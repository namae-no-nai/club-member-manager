require 'faker'

Partner.destroy_all
Weapon.destroy_all

5.times do
  Partner.create!(
    full_name: Faker::Name.name,
    cpf: Faker::IdNumber.brazilian_citizen_number(formatted: true),
    registry_certificate: Faker::Number.unique.number(digits: 10),
    registry_certificate_expiration_date: Faker::Date.between(from: Date.today, to: 1.year.from_now),
    filiation_number: Faker::Number.unique.number(digits: 8),
    first_filiation_date: Faker::Date.between(from: 5.years.ago, to: Date.today)
  )
end

3.times do
  Weapon.create!(
    caliber: Faker::Number.between(from: 1, to: 10),
    category: Faker::Lorem.word,
    sigma: Faker::Number.decimal(l_digits: 2, r_digits: 2)
  )
end
