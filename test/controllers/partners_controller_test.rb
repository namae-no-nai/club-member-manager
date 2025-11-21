require "test_helper"

class PartnersControllerTest < ActionDispatch::IntegrationTest
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

  test "should get new" do
    get new_partner_path
    assert_response :success

    # Verify the page title/heading is present
    assert_select "h1", text: "Registrar Praticante"

    # Verify the form is present
    assert_select "form", count: 1

    # Verify key form fields are present
    assert_select "input[name='partner[full_name]']"
    assert_select "input[name='partner[cpf]']"
    assert_select "input[name='partner[registry_certificate]']"
    assert_select "input[name='partner[address]']"
    assert_select "input[name='partner[filiation_number]']"

    # Verify the submit button is present
    assert_select "input[type='submit'][value='Registrar Praticante']"
  end

  test "should create partner with valid attributes" do
    assert_difference("Partner.count") do
      post partners_path, params: {
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

    assert_redirected_to new_event_path(partner_id: Partner.last.id, old_practice: true)
  end

  test "should create partner with return_to parameter" do
    return_path = "/some/custom/path"

    assert_difference("Partner.count") do
      post partners_path, params: {
        return_to: return_path,
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

    assert_redirected_to return_path
  end

  test "should not create partner with invalid attributes" do
    assert_no_difference("Partner.count") do
      post partners_path, params: {
        partner: {
          full_name: "",
          cpf: "invalid_cpf",
          registry_certificate: "",
          registry_certificate_expiration_date: nil,
          address: "",
          filiation_number: "",
          first_filiation_date: nil
        }
      }
    end

    assert_response :success
    assert_select "form"
  end

  test "should not create partner with duplicate CPF" do
    existing_cpf = @partner.cpf

    assert_no_difference("Partner.count") do
      post partners_path, params: {
        partner: {
          full_name: "Another Person",
          cpf: existing_cpf,
          registry_certificate: "99999",
          registry_certificate_expiration_date: 1.year.from_now,
          address: "789 Pine St",
          filiation_number: "003",
          first_filiation_date: 1.year.ago
        }
      }
    end

    assert_response :success
    assert_select "form"
  end

  test "should get edit" do
    get edit_partner_path(@partner)
    assert_response :success
    assert_select "form"
  end

  test "should update partner with valid attributes" do
    patch partner_path(@partner), params: {
      partner: {
        full_name: "Updated Name",
        cpf: @partner.cpf,
        registry_certificate: "99999",
        registry_certificate_expiration_date: 2.years.from_now,
        address: "Updated Address",
        filiation_number: "999",
        first_filiation_date: 2.years.ago
      }
    }

    assert_redirected_to last_records_path
    assert_equal "Sócio atualizado com sucesso.", flash[:notice]
    @partner.reload
    assert_equal "Updated Name", @partner.full_name
    assert_equal "99999", @partner.registry_certificate
  end

  test "should not update partner with invalid attributes" do
    original_name = @partner.full_name

    patch partner_path(@partner), params: {
      partner: {
        full_name: "",
        cpf: "invalid_cpf",
        registry_certificate: @partner.registry_certificate,
        registry_certificate_expiration_date: @partner.registry_certificate_expiration_date,
        address: @partner.address,
        filiation_number: @partner.filiation_number,
        first_filiation_date: @partner.first_filiation_date
      }
    }

    assert_response :unprocessable_entity
    @partner.reload
    assert_equal original_name, @partner.full_name
  end

  test "should get bulk" do
    get bulk_partners_path
    assert_response :success
  end

  test "should create partners from valid CSV" do
    csv_content = <<~CSV
      nome,cpf,cr,filiação,validade
      Test User 1,#{CPF.generate},11111,01/01/2020,01/01/2025
      Test User 2,#{CPF.generate},22222,02/02/2020,02/02/2025
    CSV

    csv_file = Tempfile.new([ "test", ".csv" ])
    csv_file.write(csv_content)
    csv_file.rewind

    assert_difference("Partner.count", 2) do
      post csv_create_partners_path, params: { file: Rack::Test::UploadedFile.new(csv_file.path, "text/csv") }
    end

    assert_redirected_to root_path
    assert_match(/2 sócios criados com sucesso/, flash[:notice])

    csv_file.close
    csv_file.unlink
  end

  test "should handle CSV with invalid partners" do
    csv_content = <<~CSV
      nome,cpf,cr,filiação,validade
      Invalid User,invalid_cpf,11111,01/01/2020,01/01/2025
    CSV

    csv_file = Tempfile.new([ "test", ".csv" ])
    csv_file.write(csv_content)
    csv_file.rewind

    assert_no_difference("Partner.count") do
      post csv_create_partners_path, params: { file: Rack::Test::UploadedFile.new(csv_file.path, "text/csv") }
    end

    assert_response :success
    assert_equal "Nenhum parceiro válido encontrado no CSV.", flash[:alert]

    csv_file.close
    csv_file.unlink
  end

  test "should handle CSV with mixed valid and invalid partners" do
    valid_cpf = CPF.generate
    csv_content = <<~CSV
      nome,cpf,cr,filiação,validade
      Valid User,#{valid_cpf},11111,01/01/2020,01/01/2025
      Invalid User,invalid_cpf,22222,02/02/2020,02/02/2025
    CSV

    csv_file = Tempfile.new([ "test", ".csv" ])
    csv_file.write(csv_content)
    csv_file.rewind

    assert_difference("Partner.count", 1) do
      post csv_create_partners_path, params: { file: Rack::Test::UploadedFile.new(csv_file.path, "text/csv") }
    end

    assert_redirected_to root_path
    assert_match(/1 sócios criados com sucesso/, flash[:notice])

    csv_file.close
    csv_file.unlink
  end

  test "should require file for CSV create" do
    assert_no_difference("Partner.count") do
      post csv_create_partners_path, params: {}
    end

    assert_response :success
    assert_equal "Envie um arquivo CSV.", flash[:alert]
  end

  test "should return not found for non-existent partner on edit" do
    get edit_partner_path(id: 99999)
    assert_response :not_found
  end

  test "should return not found for non-existent partner on update" do
    patch partner_path(id: 99999), params: {
      partner: {
        full_name: "Test"
      }
    }
    assert_response :not_found
  end
end
