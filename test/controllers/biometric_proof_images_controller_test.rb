require "test_helper"

class BiometricProofImagesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @partner = Partner.create!(
      full_name: "John Doe",
      cpf: CPF.generate,
      registry_certificate: "12345",
      registry_certificate_expiration_date: 1.year.from_now,
      address: "123 Main St",
      filiation_number: "001",
      first_filiation_date: 1.year.ago
    )
  end

  test "should send biometric proof image when attached" do
    # Create a simple test image file
    test_image = Tempfile.new([ "test", ".jpg" ])
    test_image.write("fake image content")
    test_image.rewind

    @partner.biometric_proof_image.attach(
      io: File.open(test_image.path),
      filename: "test_image.jpg",
      content_type: "image/jpeg"
    )

    get biometric_proof_image_partner_path(@partner)

    assert_response :success
    assert_equal "image/jpeg", response.content_type

    test_image.close
    test_image.unlink
  end

  test "should return not found when biometric proof image not attached" do
    get biometric_proof_image_partner_path(@partner)

    assert_response :not_found
  end

  test "should handle disposition parameter for biometric proof image" do
    # Create a simple test image file
    test_image = Tempfile.new([ "test", ".jpg" ])
    test_image.write("fake image content")
    test_image.rewind

    @partner.biometric_proof_image.attach(
      io: File.open(test_image.path),
      filename: "test_image.jpg",
      content_type: "image/jpeg"
    )

    get biometric_proof_image_partner_path(@partner), params: { disposition: "attachment" }

    assert_response :success
    assert_equal "image/jpeg", response.content_type

    test_image.close
    test_image.unlink
  end

  test "should create biometric proof image with base64 data" do
    # Create base64 encoded image data
    test_image = Tempfile.new([ "test", ".png" ])
    test_image.write("fake image content")
    test_image.rewind

    base64_data = "data:image/png;base64,#{Base64.encode64(test_image.read)}"

    assert_not @partner.biometric_proof_image.attached?

    post biometric_proof_images_partner_path(@partner), params: {
      biometric_proof: base64_data
    }

    assert_redirected_to edit_partner_path(@partner)
    assert_equal "Foto biométrica adicionada com sucesso.", flash[:notice]
    @partner.reload
    assert @partner.biometric_proof_image.attached?

    test_image.close
    test_image.unlink
  end

  test "should not create biometric proof image if one already exists" do
    # Attach an existing image
    test_image1 = Tempfile.new([ "test1", ".jpg" ])
    test_image1.write("fake image content 1")
    test_image1.rewind

    @partner.biometric_proof_image.attach(
      io: File.open(test_image1.path),
      filename: "test_image1.jpg",
      content_type: "image/jpeg"
    )

    assert @partner.biometric_proof_image.attached?
    original_blob_id = @partner.biometric_proof_image.blob_id

    # Try to attach a new image
    test_image2 = Tempfile.new([ "test2", ".png" ])
    test_image2.write("fake image content 2")
    test_image2.rewind

    base64_data = "data:image/png;base64,#{Base64.encode64(test_image2.read)}"

    post biometric_proof_images_partner_path(@partner), params: {
      biometric_proof: base64_data
    }

    assert_redirected_to edit_partner_path(@partner)
    assert_equal "Já existe uma foto biométrica cadastrada. Remova a foto atual antes de adicionar uma nova.", flash[:alert]
    @partner.reload
    assert @partner.biometric_proof_image.attached?
    assert_equal original_blob_id, @partner.biometric_proof_image.blob_id

    test_image1.close
    test_image1.unlink
    test_image2.close
    test_image2.unlink
  end

  test "should not create biometric proof image without image data" do
    assert_not @partner.biometric_proof_image.attached?

    post biometric_proof_images_partner_path(@partner), params: {}

    assert_redirected_to edit_partner_path(@partner)
    assert_equal "Envie uma foto biométrica.", flash[:alert]
    @partner.reload
    assert_not @partner.biometric_proof_image.attached?
  end

  test "should destroy biometric proof image" do
    # Attach an image first
    test_image = Tempfile.new([ "test", ".jpg" ])
    test_image.write("fake image content")
    test_image.rewind

    @partner.biometric_proof_image.attach(
      io: File.open(test_image.path),
      filename: "test_image.jpg",
      content_type: "image/jpeg"
    )

    assert @partner.biometric_proof_image.attached?

    delete biometric_proof_image_partner_path(@partner)

    assert_redirected_to edit_partner_path(@partner)
    assert_equal "Foto biométrica removida com sucesso.", flash[:notice]
    @partner.reload
    assert_not @partner.biometric_proof_image.attached?

    test_image.close
    test_image.unlink
  end

  test "should handle destroy when no image is attached" do
    assert_not @partner.biometric_proof_image.attached?

    delete biometric_proof_image_partner_path(@partner)

    assert_redirected_to edit_partner_path(@partner)
    assert_equal "Nenhuma foto biométrica encontrada para remover.", flash[:alert]
    @partner.reload
    assert_not @partner.biometric_proof_image.attached?
  end

  test "should return not found for non-existent partner on show" do
    # Create a fake partner object with id 99999 for testing
    fake_partner = Partner.new(id: 99999)
    get biometric_proof_image_partner_path(fake_partner)
    assert_response :not_found
  end

  test "should return not found for non-existent partner on create" do
    base64_data = "data:image/png;base64,#{Base64.encode64("fake image content")}"

    # Create a fake partner object with id 99999 for testing
    fake_partner = Partner.new(id: 99999)
    post biometric_proof_images_partner_path(fake_partner), params: {
      biometric_proof: base64_data
    }

    assert_response :not_found
  end

  test "should return not found for non-existent partner on destroy" do
    # Create a fake partner object with id 99999 for testing
    fake_partner = Partner.new(id: 99999)
    delete biometric_proof_image_partner_path(fake_partner)
    assert_response :not_found
  end
end
