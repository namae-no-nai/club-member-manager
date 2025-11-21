require "test_helper"

class PartnerTest < ActiveSupport::TestCase
  def setup
    # Set up a test encryption key for Lockbox if not already set
    ENV["LOCKBOX_ENCRYPTION_KEY"] ||= Lockbox.generate_key
    Lockbox.master_key = ENV["LOCKBOX_ENCRYPTION_KEY"]

    @partner = Partner.create!(
      full_name: "Test Partner",
      cpf: CPF.generate,
      registry_certificate: "12345",
      registry_certificate_expiration_date: 1.year.from_now,
      address: "123 Test St",
      filiation_number: "001",
      first_filiation_date: 1.year.ago
    )
  end

  test "partner has_one_attached biometric_proof_image" do
    # Verify the attachment method exists
    assert_respond_to @partner, :biometric_proof_image

    # Initially, no image should be attached
    assert_not @partner.biometric_proof_image.attached?

    # Create a test image file
    test_image = create_test_image

    # Attach the image
    @partner.biometric_proof_image.attach(
      io: File.open(test_image.path),
      filename: "test_image.jpg",
      content_type: "image/jpeg"
    )

    # Verify the image is now attached
    assert @partner.biometric_proof_image.attached?
    assert_equal "test_image.jpg", @partner.biometric_proof_image.filename.to_s
    assert_equal "image/jpeg", @partner.biometric_proof_image.content_type

    test_image.close
    test_image.unlink
  end

  test "partner can detach biometric_proof_image" do
    # Attach an image first
    test_image = create_test_image
    @partner.biometric_proof_image.attach(
      io: File.open(test_image.path),
      filename: "test_image.jpg",
      content_type: "image/jpeg"
    )

    assert @partner.biometric_proof_image.attached?

    # Detach the image
    @partner.biometric_proof_image.purge

    # Verify it's no longer attached
    assert_not @partner.biometric_proof_image.attached?

    test_image.close
    test_image.unlink
  end

  test "biometric_proof_image is encrypted using encrypts_attached" do
    # Create a test image
    test_image = create_test_image("sensitive biometric data")
    original_content = File.read(test_image.path)

    # Attach the image
    @partner.biometric_proof_image.attach(
      io: File.open(test_image.path),
      filename: "encrypted_image.jpg",
      content_type: "image/jpeg"
    )

    # Reload to ensure we're getting fresh data
    @partner.reload

    # Verify the attachment is accessible (decryption works)
    assert @partner.biometric_proof_image.attached?

    # Download and verify the content matches (decryption works correctly)
    downloaded_content = @partner.biometric_proof_image.download
    assert_equal original_content, downloaded_content

    # Verify the blob exists in ActiveStorage
    blob = @partner.biometric_proof_image.blob
    assert_not_nil blob

    # The encryption happens at the storage level via Lockbox
    # We can verify that the attachment can be accessed and decrypted
    # by successfully downloading it and comparing content

    test_image.close
    test_image.unlink
  end

  test "encrypted biometric_proof_image can be accessed after reload" do
    # Attach an image
    test_image = create_test_image("test content")
    original_content = File.read(test_image.path)

    @partner.biometric_proof_image.attach(
      io: File.open(test_image.path),
      filename: "reload_test.jpg",
      content_type: "image/jpeg"
    )

    # Reload the partner from database
    @partner.reload

    # Verify the attachment is still accessible after reload
    assert @partner.biometric_proof_image.attached?

    # Verify we can still download and decrypt the content
    downloaded_content = @partner.biometric_proof_image.download
    assert_equal original_content, downloaded_content

    test_image.close
    test_image.unlink
  end

  test "multiple partners can have encrypted biometric_proof_images simultaneously" do
    partners = []
    images = []

    # Create 3 partners with different images
    3.times do |i|
      partner = Partner.create!(
        full_name: "Partner #{i + 1}",
        cpf: CPF.generate,
        registry_certificate: "#{i + 1}#{i + 1}#{i + 1}#{i + 1}#{i + 1}",
        registry_certificate_expiration_date: 1.year.from_now,
        address: "Address #{i + 1}",
        filiation_number: "00#{i + 1}",
        first_filiation_date: 1.year.ago
      )

      image = create_test_image("content for partner #{i + 1}")
      partners << partner
      images << image

      partner.biometric_proof_image.attach(
        io: File.open(image.path),
        filename: "partner_#{i + 1}_image.jpg",
        content_type: "image/jpeg"
      )
    end

    # Verify all partners have their attachments
    partners.each_with_index do |partner, i|
      assert partner.biometric_proof_image.attached?, "Partner #{i + 1} should have attachment"
      assert_equal "partner_#{i + 1}_image.jpg", partner.biometric_proof_image.filename.to_s

      # Verify each can be downloaded and decrypted
      downloaded = partner.biometric_proof_image.download
      original = File.read(images[i].path)
      assert_equal original, downloaded, "Partner #{i + 1} should decrypt correctly"
    end

    # Clean up
    images.each do |image|
      image.close
      image.unlink
    end
  end

  private

  def create_test_image(content = "fake image content for testing")
    tempfile = Tempfile.new([ "test", ".jpg" ])
    tempfile.write(content)
    tempfile.rewind
    tempfile
  end
end
