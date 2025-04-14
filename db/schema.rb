# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_04_06_194348) do
  create_table "credentials", force: :cascade do |t|
    t.string "webauthn_id"
    t.string "public_key"
    t.string "nickname"
    t.integer "sign_count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "partner_id", null: false
    t.index ["partner_id"], name: "index_credentials_on_partner_id"
  end

  create_table "events", force: :cascade do |t|
    t.integer "partner_id"
    t.integer "weapon_id"
    t.string "activity"
    t.date "date"
    t.integer "ammo_amount"
    t.integer "sheet", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "finger_prints", force: :cascade do |t|
    t.string "credentials"
    t.integer "partner_id"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "partners", force: :cascade do |t|
    t.string "full_name"
    t.string "cpf"
    t.string "registry_certificate"
    t.date "registry_certificate_expiration_date"
    t.text "address"
    t.string "filiation_number"
    t.date "first_filiation_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "webauthn_id"
  end

  create_table "weapons", force: :cascade do |t|
    t.string "sigma"
    t.string "serial_number"
    t.integer "weapon_type"
    t.string "brand"
    t.string "caliber"
    t.string "model"
    t.string "action"
    t.integer "bore_type"
    t.integer "authorized_use"
    t.integer "partner_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["partner_id"], name: "index_weapons_on_partner_id"
  end

  add_foreign_key "credentials", "partners"
  add_foreign_key "weapons", "partners"
end
