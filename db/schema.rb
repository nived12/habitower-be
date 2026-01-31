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

ActiveRecord::Schema[8.0].define(version: 2026_01_30_120600) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "challenge_step_templates", force: :cascade do |t|
    t.bigint "challenge_template_id", null: false
    t.bigint "creator_id", null: false
    t.string "title", null: false
    t.integer "position", null: false
    t.jsonb "requirements", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at"
    t.index ["challenge_template_id"], name: "index_challenge_step_templates_on_challenge_template_id"
    t.index ["creator_id"], name: "index_challenge_step_templates_on_creator_id"
    t.index ["discarded_at"], name: "index_challenge_step_templates_on_discarded_at"
  end

  create_table "challenge_templates", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.string "period_type", default: "weekly", null: false
    t.jsonb "rules", default: {}, null: false
    t.bigint "creator_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at"
    t.string "privacy_type", default: "public", null: false
    t.index ["creator_id"], name: "index_challenge_templates_on_creator_id"
    t.index ["discarded_at"], name: "index_challenge_templates_on_discarded_at"
    t.index ["privacy_type"], name: "index_challenge_templates_on_privacy_type"
  end

  create_table "devices", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "platform", null: false
    t.string "token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "platform"], name: "index_devices_on_user_id_and_platform", unique: true
    t.index ["user_id"], name: "index_devices_on_user_id"
  end

  create_table "group_steps", force: :cascade do |t|
    t.bigint "group_id", null: false
    t.bigint "creator_id", null: false
    t.string "title", null: false
    t.integer "position", null: false
    t.jsonb "requirements", default: {}, null: false
    t.bigint "original_step_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at"
    t.index ["creator_id"], name: "index_group_steps_on_creator_id"
    t.index ["discarded_at"], name: "index_group_steps_on_discarded_at"
    t.index ["group_id", "position"], name: "index_group_steps_on_group_id_and_position"
    t.index ["group_id"], name: "index_group_steps_on_group_id"
    t.index ["original_step_id"], name: "index_group_steps_on_original_step_id"
  end

  create_table "groups", force: :cascade do |t|
    t.bigint "challenge_template_id", null: false
    t.bigint "creator_id", null: false
    t.date "start_date", null: false
    t.string "privacy_type", default: "public", null: false
    t.string "invite_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at"
    t.jsonb "rules", default: {}, null: false
    t.decimal "integrity_score", precision: 5, scale: 2, default: "100.0", null: false
    t.index ["challenge_template_id"], name: "index_groups_on_challenge_template_id"
    t.index ["creator_id"], name: "index_groups_on_creator_id"
    t.index ["discarded_at"], name: "index_groups_on_discarded_at"
    t.index ["invite_code"], name: "index_groups_on_invite_code"
  end

  create_table "memberships", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "group_id", null: false
    t.string "role", default: "member", null: false
    t.string "status", default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at"
    t.index ["discarded_at"], name: "index_memberships_on_discarded_at"
    t.index ["group_id"], name: "index_memberships_on_group_id"
    t.index ["user_id", "group_id"], name: "index_memberships_on_user_id_and_group_id", unique: true
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "progress_logs", force: :cascade do |t|
    t.bigint "membership_id", null: false
    t.decimal "value", precision: 15, scale: 4, null: false
    t.datetime "occurred_at", null: false
    t.text "note"
    t.string "proof_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at"
    t.bigint "group_step_id", null: false
    t.index ["discarded_at"], name: "index_progress_logs_on_discarded_at"
    t.index ["group_step_id"], name: "index_progress_logs_on_group_step_id"
    t.index ["membership_id"], name: "index_progress_logs_on_membership_id"
  end

  create_table "refresh_tokens", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "token", null: false
    t.datetime "expires_at", null: false
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token"], name: "index_refresh_tokens_on_token", unique: true
    t.index ["user_id"], name: "index_refresh_tokens_on_user_id"
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
    t.string "username"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "challenge_step_templates", "challenge_templates"
  add_foreign_key "challenge_step_templates", "users", column: "creator_id"
  add_foreign_key "challenge_templates", "users", column: "creator_id"
  add_foreign_key "devices", "users"
  add_foreign_key "group_steps", "challenge_step_templates", column: "original_step_id"
  add_foreign_key "group_steps", "groups"
  add_foreign_key "group_steps", "users", column: "creator_id"
  add_foreign_key "groups", "challenge_templates"
  add_foreign_key "groups", "users", column: "creator_id"
  add_foreign_key "memberships", "groups"
  add_foreign_key "memberships", "users"
  add_foreign_key "progress_logs", "group_steps"
  add_foreign_key "progress_logs", "memberships"
  add_foreign_key "refresh_tokens", "users"
end
