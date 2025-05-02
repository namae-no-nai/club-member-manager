require 'csv'

class CsvToPartnerService
  MAPPING = {
    "nome" => :full_name,
    "cpf" => :cpf,
    "cr" => :registry_certificate,
    "filiação" => :first_filiation_date,
    "validade" => :registry_certificate_expiration_date
  }

  def initialize(file)
    @file = file
  end

  def process
    partners = []
    CSV.foreach(@file.path, headers: true, col_sep: ",", encoding: "bom|utf-8") do |row|
      attributes = {}

      row.headers.each do |header|
        mapped_attr = MAPPING[header.strip.downcase]
        next unless mapped_attr

        value = row[header]&.strip
        if mapped_attr.to_s.include?("date")
          attributes[mapped_attr] = parse_date(value)
        else
          attributes[mapped_attr] = value
        end
      end

      partners << Partner.new(attributes) if attributes.present?
    end

    partners
  end

  private

  def parse_date(value)
    return nil unless value.is_a?(String) && [8, 10].include?(value.length)

    value.length == 8 ? parse_short_date(value) : Date.strptime(value, "%m/%d/%Y")
  end

  def parse_short_date(value)
    date = Date.strptime(value, "%m/%d/%y")
    date.year < 1950 ? date.next_year(100) : date
  end
end
