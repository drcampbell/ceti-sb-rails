# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20160126201615) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "badges", force: :cascade do |t|
    t.string   "file"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "url"
    t.string   "file_name"
    t.string   "f_type"
    t.string   "name"
  end

  create_table "claims", force: :cascade do |t|
    t.integer  "event_id"
    t.integer  "user_id"
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.boolean  "confirmed_by_teacher", default: false
    t.boolean  "confirmed_by_speaker", default: false
    t.boolean  "active",               default: true
    t.boolean  "rejected",             default: false
    t.boolean  "cancelled",            default: false
  end

  add_index "claims", ["event_id"], name: "index_claims_on_event_id", using: :btree
  add_index "claims", ["user_id"], name: "index_claims_on_user_id", using: :btree

  create_table "devices", force: :cascade do |t|
    t.integer "user_id"
    t.string  "device_name"
    t.string  "token"
    t.string  "endpoint_arn"
  end

  create_table "email_responses", force: :cascade do |t|
    t.string   "email"
    t.text     "extra_info"
    t.integer  "response_type"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  create_table "events", force: :cascade do |t|
    t.integer  "user_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.text     "content"
    t.string   "title"
    t.datetime "event_start"
    t.datetime "event_end"
    t.integer  "loc_id"
    t.integer  "speaker_id"
    t.string   "user_name"
    t.string   "loc_name"
    t.boolean  "active"
    t.string   "time_zone"
    t.boolean  "complete"
  end

  add_index "events", ["loc_id"], name: "index_events_on_loc_id", using: :btree
  add_index "events", ["user_id"], name: "index_events_on_user_id", using: :btree

  create_table "locations", force: :cascade do |t|
    t.string   "address"
    t.float    "latitude"
    t.float    "longitude"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "name"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.integer  "user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.integer "user_id"
    t.integer "act_user_id"
    t.integer "event_id"
    t.integer "n_type"
    t.boolean "read"
  end

  add_index "notifications", ["user_id"], name: "index_notifications_on_user_id", using: :btree

  create_table "pg_search_documents", force: :cascade do |t|
    t.text     "content"
    t.integer  "searchable_id"
    t.string   "searchable_type"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "pg_search_documents", ["searchable_type", "searchable_id"], name: "index_pg_search_documents_on_searchable_type_and_searchable_id", using: :btree

  create_table "schools", force: :cascade do |t|
    t.integer  "badge_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.integer  "survey_year"
    t.string   "ncessch"
    t.string   "fipst"
    t.string   "leaid"
    t.string   "schno"
    t.string   "stid"
    t.string   "seasch"
    t.string   "edu_agency"
    t.string   "school_name"
    t.string   "phone"
    t.string   "mail_addr"
    t.string   "mail_city"
    t.string   "mail_state"
    t.string   "mail_zip"
    t.string   "mail_zip4"
    t.string   "loc_addr"
    t.string   "loc_city"
    t.string   "loc_state"
    t.string   "loc_zip"
    t.string   "loc_zip4"
    t.integer  "school_type"
    t.integer  "status"
    t.string   "union"
    t.string   "urban_local"
    t.float    "latitude"
    t.float    "longitude"
    t.string   "county_number"
    t.string   "county_name"
    t.string   "cdcode"
    t.string   "grade_lo"
    t.string   "grade_hi"
    t.boolean  "charter"
    t.text     "address"
    t.tsvector "search_vector"
  end

  add_index "schools", ["badge_id"], name: "index_schools_on_badge_id", using: :btree
  add_index "schools", ["loc_addr"], name: "index_schools_on_loc_addr", using: :btree
  add_index "schools", ["loc_city"], name: "index_schools_on_loc_city", using: :btree
  add_index "schools", ["loc_state"], name: "index_schools_on_loc_state", using: :btree
  add_index "schools", ["school_name"], name: "index_schools_on_school_name", using: :btree
  add_index "schools", ["search_vector"], name: "schools_search_idx", using: :gin

  create_table "taggings", force: :cascade do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "context",       limit: 128
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true, using: :btree
  add_index "taggings", ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context", using: :btree

  create_table "tags", force: :cascade do |t|
    t.string  "name"
    t.integer "taggings_count", default: 0
  end

  add_index "tags", ["name"], name: "index_tags_on_name", unique: true, using: :btree

  create_table "user_badges", force: :cascade do |t|
    t.integer "user_id"
    t.integer "badge_id"
    t.integer "event_id"
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.integer  "role"
    t.string   "grades"
    t.string   "job_title"
    t.string   "business"
    t.text     "biography"
    t.string   "speaking_category"
    t.integer  "school_id"
    t.string   "authentication_token"
    t.boolean  "set_updates"
    t.boolean  "set_confirm"
    t.boolean  "set_claims"
  end

  add_index "users", ["authentication_token"], name: "index_users_on_authentication_token", using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["school_id"], name: "index_users_on_school_id", using: :btree

end
