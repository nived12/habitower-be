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

ActiveRecord::Schema[8.0].define(version: 2026_01_30_012306) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "challenge_steps", force: :cascade do |t|
    t.bigint "challenge_id", null: false
    t.bigint "creator_id", null: false
    t.string "title", null: false
    t.integer "position", null: false
    t.jsonb "requirements", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["challenge_id"], name: "index_challenge_steps_on_challenge_id"
    t.index ["creator_id"], name: "index_challenge_steps_on_creator_id"
  end

  create_table "challenges", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.string "period_type", null: false
    t.jsonb "rules", default: {}, null: false
    t.bigint "creator_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_challenges_on_creator_id"
  end

  create_table "groups", force: :cascade do |t|
    t.bigint "challenge_id", null: false
    t.bigint "creator_id", null: false
    t.date "start_date", null: false
    t.string "privacy_type", null: false
    t.string "invite_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["challenge_id"], name: "index_groups_on_challenge_id"
    t.index ["creator_id"], name: "index_groups_on_creator_id"
    t.index ["invite_code"], name: "index_groups_on_invite_code"
  end

  create_table "memberships", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "group_id", null: false
    t.string "role", null: false
    t.string "status", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_memberships_on_group_id"
    t.index ["user_id", "group_id"], name: "index_memberships_on_user_id_and_group_id", unique: true
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "progress_logs", force: :cascade do |t|
    t.bigint "membership_id", null: false
    t.bigint "challenge_step_id", null: false
    t.decimal "value", precision: 15, scale: 4, null: false
    t.datetime "occurred_at", null: false
    t.text "note"
    t.string "proof_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["challenge_step_id"], name: "index_progress_logs_on_challenge_step_id"
    t.index ["membership_id"], name: "index_progress_logs_on_membership_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "jti"
    t.string "first_name"
    t.string "last_name"
    t.string "avatar_url"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "challenge_steps", "challenges"
  add_foreign_key "challenge_steps", "users", column: "creator_id"
  add_foreign_key "challenges", "users", column: "creator_id"
  add_foreign_key "groups", "challenges"
  add_foreign_key "groups", "users", column: "creator_id"
  add_foreign_key "memberships", "groups"
  add_foreign_key "memberships", "users"
  add_foreign_key "progress_logs", "challenge_steps"
  add_foreign_key "progress_logs", "memberships"
end
