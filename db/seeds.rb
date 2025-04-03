require 'faker'

Partner.destroy_all
Weapon.destroy_all

Partner.create!(
  full_name: 'Interarmas clube de tiro',
  cpf: Faker::IdNumber.brazilian_citizen_number(formatted: true),
  address: 'Alameda Nothmann, nº 1209',
  registry_certificate: 66098,
  registry_certificate_expiration_date: Faker::Date.between(from: Date.today, to: 1.year.from_now),
  filiation_number: Faker::Number.unique.number(digits: 8),
  first_filiation_date: Faker::Date.between(from: 5.years.ago, to: Date.today)
)

