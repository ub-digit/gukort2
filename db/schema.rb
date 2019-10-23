# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20191023115550) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "blacklisted_card_numbers", force: :cascade do |t|
    t.string "card_number", null: false
  end

  create_table "issued_states", force: :cascade do |t|
    t.string "pnr"
    t.date "expiration_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pnr"], name: "index_issued_states_on_pnr", unique: true
  end

  create_table "messages", force: :cascade do |t|
    t.text "xml"
    t.string "queue_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "response"
  end

  create_table "patrons", force: :cascade do |t|
    t.text "firstname"
    t.text "surname"
    t.text "care_of"
    t.text "street"
    t.text "zip"
    t.text "city"
    t.text "country"
    t.text "phone"
    t.text "email"
    t.text "b_care_of"
    t.text "b_street"
    t.text "b_zip"
    t.text "b_city"
    t.text "b_country"
    t.text "categorycode"
    t.text "account"
    t.text "pnr"
    t.text "pnr12"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
