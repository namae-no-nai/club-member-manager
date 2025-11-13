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

ActiveRecord::Schema[8.0].define(version: 2025_11_12_022344) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "credentials", force: :cascade do |t|
    t.binary "webauthn_id"
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
    t.string "biometric_proof"
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
    t.datetime "archived_at"
    t.string "archived_reason"
    t.index ["partner_id"], name: "index_weapons_on_partner_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "credentials", "partners"
  add_foreign_key "weapons", "partners"
end
