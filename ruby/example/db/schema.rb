# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_10_02_051318) do

  create_table "timeline_events", force: :cascade do |t|
    t.integer "timeline_id", null: false
    t.integer "version_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["timeline_id"], name: "index_timeline_events_on_timeline_id"
    t.index ["version_id"], name: "index_timeline_events_on_version_id"
  end

  create_table "timelines", force: :cascade do |t|
    t.datetime "transaction_start"
    t.datetime "transaction_stop"
    t.string "uuid"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["transaction_start"], name: "index_timelines_on_transaction_start"
    t.index ["transaction_stop"], name: "index_timelines_on_transaction_stop"
    t.index ["uuid"], name: "index_timelines_on_uuid", unique: true
  end

  create_table "toy_versions", force: :cascade do |t|
    t.datetime "effective_start"
    t.datetime "effective_stop"
    t.string "uuid"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["effective_start"], name: "index_toy_versions_on_effective_start"
    t.index ["effective_stop"], name: "index_toy_versions_on_effective_stop"
    t.index ["uuid"], name: "index_toy_versions_on_uuid", unique: true
  end

  add_foreign_key "timeline_events", "timelines"
  add_foreign_key "timeline_events", "versions"
end
