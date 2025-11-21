require "test_helper"

class PocControllerTest < ActionDispatch::IntegrationTest
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

  test "should get index" do
    get poc_index_path
    assert_response :success
  end

  test "should get new" do
    get new_poc_path
    assert_response :success
    assert_select "form"
    assert_select "input[name='partner[full_name]']"
    assert_select "input[name='partner[cpf]']"
    assert_select "input[name='partner[biometric_proof]']"
  end

  test "should create partner with valid attributes and biometric proof" do
    # Create base64 encoded image data
    test_image = Tempfile.new([ "test", ".png" ])
    test_image.write("fake image content")
    test_image.rewind
    base64_data = "data:image/png;base64,#{Base64.encode64(test_image.read)}"

    assert_difference("Partner.count") do
      post poc_index_path, params: {
        partner: {
          full_name: "Jane Smith",
          cpf: CPF.generate,
          registry_certificate: "67890",
          registry_certificate_expiration_date: 1.year.from_now,
          address: "456 Oak Ave",
          filiation_number: "002",
          first_filiation_date: 1.year.ago,
          biometric_proof: base64_data
        }
      }
    end

    partner = Partner.last
    assert_redirected_to edit_partner_path(partner)
    assert partner.biometric_proof_image.attached?

    test_image.close
    test_image.unlink
  end

  test "should not create partner with invalid attributes" do
    # Create base64 encoded image data
    test_image = Tempfile.new([ "test", ".png" ])
    test_image.write("fake image content")
    test_image.rewind
    base64_data = "data:image/png;base64,#{Base64.encode64(test_image.read)}"

    assert_no_difference("Partner.count") do
      post poc_index_path, params: {
        partner: {
          full_name: "",
          cpf: "invalid_cpf",
          registry_certificate: "",
          registry_certificate_expiration_date: nil,
          address: "",
          filiation_number: "",
          first_filiation_date: nil,
          biometric_proof: base64_data
        }
      }
    end

    assert_redirected_to new_poc_path
    assert_match(/Erro ao registrar sócio/, flash[:alert])

    test_image.close
    test_image.unlink
  end

  test "should handle create with missing biometric_proof parameter" do
    assert_no_difference("Partner.count") do
      post poc_index_path, params: {
        partner: {
          full_name: "Jane Smith",
          cpf: CPF.generate,
          registry_certificate: "67890",
          registry_certificate_expiration_date: 1.year.from_now,
          address: "456 Oak Ave",
          filiation_number: "002",
          first_filiation_date: 1.year.ago
        }
      }
    end

    assert_redirected_to new_poc_path
    assert_match(/Ocorreu um erro ao verificar a biometria do sócio/, flash[:alert])
  end

  test "should handle create with service exception" do
    # Create base64 encoded image data
    test_image = Tempfile.new([ "test", ".png" ])
    test_image.write("fake image content")
    test_image.rewind
    base64_data = "data:image/png;base64,#{Base64.encode64(test_image.read)}"

    # Temporarily replace the service method to raise an error
    unless ActiveStorageUploaderService.method_defined?(:call_without_test_stub)
      ActiveStorageUploaderService.alias_method(:call_without_test_stub, :call)
    end

    ActiveStorageUploaderService.define_method(:call) do
      raise StandardError, "Service error"
    end

    begin
      assert_no_difference("Partner.count") do
        post poc_index_path, params: {
          partner: {
            full_name: "Jane Smith",
            cpf: CPF.generate,
            registry_certificate: "67890",
            registry_certificate_expiration_date: 1.year.from_now,
            address: "456 Oak Ave",
            filiation_number: "002",
            first_filiation_date: 1.year.ago,
            biometric_proof: base64_data
          }
        }
      end

      assert_redirected_to new_poc_path
      assert_match(/Erro ao tentar registrar sócio/, flash[:alert])
    ensure
      # Restore the original method
      ActiveStorageUploaderService.alias_method(:call, :call_without_test_stub)
      ActiveStorageUploaderService.remove_method(:call_without_test_stub) if ActiveStorageUploaderService.method_defined?(:call_without_test_stub)
    end

    test_image.close
    test_image.unlink
  end

  test "should verify biometric proof with valid data and attached image" do
    # Attach a biometric proof image to the partner
    test_image = Tempfile.new([ "test", ".jpg" ])
    test_image.write("fake stored image content")
    test_image.rewind

    @partner.biometric_proof_image.attach(
      io: File.open(test_image.path),
      filename: "test_image.jpg",
      content_type: "image/jpeg"
    )

    # Create base64 encoded image data for verification
    verify_image = Tempfile.new([ "verify", ".png" ])
    verify_image.write("fake verification image content")
    verify_image.rewind
    base64_data = "data:image/png;base64,#{Base64.encode64(verify_image.read)}"

    # Mock the verification service to return success
    unless BiometricVerificationService.method_defined?(:call_without_test_stub)
      BiometricVerificationService.alias_method(:call_without_test_stub, :call)
    end

    BiometricVerificationService.define_method(:call) do
      { verified: true }
    end

    begin
      post verify_poc_index_path, params: {
        partner_id: @partner.id,
        biometric_proof: base64_data
      }

      assert_redirected_to edit_partner_path(@partner)
    ensure
      # Restore the original method
      BiometricVerificationService.alias_method(:call, :call_without_test_stub)
      BiometricVerificationService.remove_method(:call_without_test_stub) if BiometricVerificationService.method_defined?(:call_without_test_stub)
    end

    test_image.close
    test_image.unlink
    verify_image.close
    verify_image.unlink
  end

  test "should verify biometric proof with valid data and stored S3 key" do
    # Set a biometric_proof key (S3 key) instead of attached image
    @partner.update(biometric_proof: "s3://bucket/key/to/image.jpg")

    # Create base64 encoded image data for verification
    verify_image = Tempfile.new([ "verify", ".png" ])
    verify_image.write("fake verification image content")
    verify_image.rewind
    base64_data = "data:image/png;base64,#{Base64.encode64(verify_image.read)}"

    # Mock the verification service to return success
    unless BiometricVerificationService.method_defined?(:call_without_test_stub)
      BiometricVerificationService.alias_method(:call_without_test_stub, :call)
    end

    BiometricVerificationService.define_method(:call) do
      { verified: true }
    end

    begin
      post verify_poc_index_path, params: {
        partner_id: @partner.id,
        biometric_proof: base64_data
      }

      assert_redirected_to edit_partner_path(@partner)
    ensure
      # Restore the original method
      BiometricVerificationService.alias_method(:call, :call_without_test_stub)
      BiometricVerificationService.remove_method(:call_without_test_stub) if BiometricVerificationService.method_defined?(:call_without_test_stub)
    end

    verify_image.close
    verify_image.unlink
  end

  test "should redirect when biometric_proof parameter is missing" do
    post verify_poc_index_path, params: {
      partner_id: @partner.id
    }

    assert_redirected_to poc_index_path
  end

  test "should redirect when partner has no stored biometric proof" do
    # Ensure partner has no biometric proof
    @partner.update(biometric_proof: nil)
    assert_not @partner.biometric_proof_image.attached?

    # Create base64 encoded image data for verification
    verify_image = Tempfile.new([ "verify", ".png" ])
    verify_image.write("fake verification image content")
    verify_image.rewind
    base64_data = "data:image/png;base64,#{Base64.encode64(verify_image.read)}"

    post verify_poc_index_path, params: {
      partner_id: @partner.id,
      biometric_proof: base64_data
    }

    assert_redirected_to poc_index_path

    verify_image.close
    verify_image.unlink
  end

  test "should handle verification service error" do
    # Attach a biometric proof image to the partner
    test_image = Tempfile.new([ "test", ".jpg" ])
    test_image.write("fake stored image content")
    test_image.rewind

    @partner.biometric_proof_image.attach(
      io: File.open(test_image.path),
      filename: "test_image.jpg",
      content_type: "image/jpeg"
    )

    # Create base64 encoded image data for verification
    verify_image = Tempfile.new([ "verify", ".png" ])
    verify_image.write("fake verification image content")
    verify_image.rewind
    base64_data = "data:image/png;base64,#{Base64.encode64(verify_image.read)}"

    # Mock the verification service to return an error
    unless BiometricVerificationService.method_defined?(:call_without_test_stub)
      BiometricVerificationService.alias_method(:call_without_test_stub, :call)
    end

    BiometricVerificationService.define_method(:call) do
      { verified: false, error: "API connection failed" }
    end

    begin
      post verify_poc_index_path, params: {
        partner_id: @partner.id,
        biometric_proof: base64_data
      }

      assert_redirected_to poc_index_path
      assert_match(/Erro na verificação biométrica/, flash[:alert])
    ensure
      # Restore the original method
      BiometricVerificationService.alias_method(:call, :call_without_test_stub)
      BiometricVerificationService.remove_method(:call_without_test_stub) if BiometricVerificationService.method_defined?(:call_without_test_stub)
    end

    test_image.close
    test_image.unlink
    verify_image.close
    verify_image.unlink
  end

  test "should handle verification service exception" do
    # Attach a biometric proof image to the partner
    test_image = Tempfile.new([ "test", ".jpg" ])
    test_image.write("fake stored image content")
    test_image.rewind

    @partner.biometric_proof_image.attach(
      io: File.open(test_image.path),
      filename: "test_image.jpg",
      content_type: "image/jpeg"
    )

    # Create base64 encoded image data for verification
    verify_image = Tempfile.new([ "verify", ".png" ])
    verify_image.write("fake verification image content")
    verify_image.rewind
    base64_data = "data:image/png;base64,#{Base64.encode64(verify_image.read)}"

    # Mock the verification service to raise an exception
    unless BiometricVerificationService.method_defined?(:call_without_test_stub)
      BiometricVerificationService.alias_method(:call_without_test_stub, :call)
    end

    BiometricVerificationService.define_method(:call) do
      raise StandardError, "Service exception"
    end

    begin
      post verify_poc_index_path, params: {
        partner_id: @partner.id,
        biometric_proof: base64_data
      }

      assert_redirected_to poc_index_path
      assert_match(/Erro ao processar verificação biométrica/, flash[:alert])
    ensure
      # Restore the original method
      BiometricVerificationService.alias_method(:call, :call_without_test_stub)
      BiometricVerificationService.remove_method(:call_without_test_stub) if BiometricVerificationService.method_defined?(:call_without_test_stub)
    end

    test_image.close
    test_image.unlink
    verify_image.close
    verify_image.unlink
  end

  test "should handle non-existent partner in verify" do
    # Create base64 encoded image data for verification
    verify_image = Tempfile.new([ "verify", ".png" ])
    verify_image.write("fake verification image content")
    verify_image.rewind
    base64_data = "data:image/png;base64,#{Base64.encode64(verify_image.read)}"

    post verify_poc_index_path, params: {
      partner_id: 99999,
      biometric_proof: base64_data
    }

    assert_response :not_found

    verify_image.close
    verify_image.unlink
  end

  test "should not create partner with duplicate CPF" do
    existing_cpf = @partner.cpf

    # Create base64 encoded image data
    test_image = Tempfile.new([ "test", ".png" ])
    test_image.write("fake image content")
    test_image.rewind
    base64_data = "data:image/png;base64,#{Base64.encode64(test_image.read)}"

    assert_no_difference("Partner.count") do
      post poc_index_path, params: {
        partner: {
          full_name: "Another Person",
          cpf: existing_cpf,
          registry_certificate: "99999",
          registry_certificate_expiration_date: 1.year.from_now,
          address: "789 Pine St",
          filiation_number: "003",
          first_filiation_date: 1.year.ago,
          biometric_proof: base64_data
        }
      }
    end

    assert_redirected_to new_poc_path
    assert_match(/Erro ao registrar sócio/, flash[:alert])

    test_image.close
    test_image.unlink
  end
end
