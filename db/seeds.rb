require 'faker'

Partner.destroy_all
Weapon.destroy_all

# Create the club partner
club_partner = Partner.find_or_create_by!(
  full_name: 'Interarmas clube de tiro',
  cpf: Faker::IdNumber.brazilian_citizen_number(formatted: true),
  address: 'Alameda Nothmann, nº 1209',
  registry_certificate: 66098,
  registry_certificate_expiration_date: Faker::Date.between(from: Date.today, to: 1.year.from_now),
  filiation_number: Faker::Number.unique.number(digits: 8),
  first_filiation_date: Faker::Date.between(from: 5.years.ago, to: Date.today)
)

puts "Created club partner: #{club_partner.full_name}"

# Create a weapon for the club partner
club_weapon = Weapon.find_or_create_by!(
  partner: club_partner,
  sigma: Faker::Alphanumeric.alphanumeric(number: 10).upcase,
  serial_number: Faker::Alphanumeric.alphanumeric(number: 12).upcase,
  weapon_type: :pistola,
  brand: 'Taurus',
  caliber: '.40 S&W',
  model: 'PT 100',
  action: 'semi-automático',
  bore_type: :raiada,
  authorized_use: :permitido
)

puts "Created weapon for club: #{club_weapon.friendly_name}"

# Create 3 individual partners with 3 weapons each
weapon_configs = [
  # Partner 1 weapons
  [
    { weapon_type: :pistola, brand: 'Glock', caliber: '9mm', model: 'G19', action: 'semi-automático', bore_type: :raiada, authorized_use: :permitido },
    { weapon_type: :revolver, brand: 'Taurus', caliber: '.38 Special', model: '85', action: 'outros', bore_type: :raiada, authorized_use: :permitido },
    { weapon_type: :carabina, brand: 'CBC', caliber: '.22 LR', model: '8022', action: 'semi-automático', bore_type: :raiada, authorized_use: :permitido }
  ],
  # Partner 2 weapons
  [
    { weapon_type: :pistola, brand: 'Taurus', caliber: '.380 ACP', model: 'PT 938', action: 'semi-automático', bore_type: :raiada, authorized_use: :restrito },
    { weapon_type: :revolver, brand: 'Rossi', caliber: '.357 Magnum', model: 'R971', action: 'outros', bore_type: :raiada, authorized_use: :restrito },
    { weapon_type: :espingarda, brand: 'Boito', caliber: '12', model: 'A680', action: 'repetição', bore_type: :lisa, authorized_use: :permitido }
  ],
  # Partner 3 weapons
  [
    { weapon_type: :pistola, brand: 'IMBEL', caliber: '9mm', model: 'GC-MD1', action: 'semi-automático', bore_type: :raiada, authorized_use: :restrito },
    { weapon_type: :carabina, brand: 'Rossi', caliber: '.44 Magnum', model: 'R92', action: 'repetição', bore_type: :raiada, authorized_use: :permitido },
    { weapon_type: :espingarda, brand: 'CBC', caliber: '20', model: 'Standard', action: 'repetição', bore_type: :lisa, authorized_use: :permitido }
  ]
]

3.times do |i|
  partner = Partner.create!(
    full_name: Faker::Name.name,
    cpf: Faker::IdNumber.brazilian_citizen_number(formatted: true),
    address: Faker::Address.full_address,
    registry_certificate: Faker::Number.unique.number(digits: 6),
    registry_certificate_expiration_date: Faker::Date.between(from: Date.today, to: 2.years.from_now),
    filiation_number: Faker::Number.unique.number(digits: 8),
    first_filiation_date: Faker::Date.between(from: 3.years.ago, to: 1.year.ago)
  )

  puts "\nCreated partner #{i + 1}: #{partner.full_name} (CPF: #{partner.cpf})"

  # Create 3 weapons for this partner
  weapon_configs[i].each do |weapon_config|
    weapon = Weapon.create!(
      partner: partner,
      sigma: Faker::Alphanumeric.alphanumeric(number: 10).upcase,
      serial_number: Faker::Alphanumeric.alphanumeric(number: 12).upcase,
      **weapon_config
    )
    puts "  - #{weapon.friendly_name}"
  end
end

puts "\n✓ Seeds completed successfully!"
puts "Total partners: #{Partner.count}"
puts "Total weapons: #{Weapon.count}"
