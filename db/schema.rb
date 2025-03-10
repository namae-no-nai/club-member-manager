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

ActiveRecord::Schema[8.0].define(version: 2025_03_06_223557) do
  create_table "credentials", force: :cascade do |t|
    t.string "webauthn_id"
    t.string "public_key"
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
    t.integer "sheet"
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
    t.integer "webauthn_id"
  end

  create_table "weapons", force: :cascade do |t|
    t.string "caliber"
    t.string "category"
    t.string "sigma"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "credentials", "partners"
end
