require 'faker'

Partner.destroy_all
Weapon.destroy_all

5.times do
  Partner.create!(
    full_name: Faker::Name.name,
    cpf: Faker::IdNumber.brazilian_citizen_number(formatted: true),
    address: Faker::Address.street_address,
    registry_certificate: Faker::Number.unique.number(digits: 10),
    registry_certificate_expiration_date: Faker::Date.between(from: Date.today, to: 1.year.from_now),
    filiation_number: Faker::Number.unique.number(digits: 8),
    first_filiation_date: Faker::Date.between(from: 5.years.ago, to: Date.today)
  )
end

