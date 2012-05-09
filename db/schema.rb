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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120419013101) do

  create_table "admins", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bets", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.integer  "league_id"
    t.integer  "game_id"
    t.integer  "parlay_id"
    t.float    "risk"
    t.float    "win"
    t.boolean  "lock"
    t.string   "bet_type"
    t.boolean  "won"
  end

  create_table "games", :force => true do |t|
    t.string   "home_team"
    t.string   "away_team"
    t.decimal  "spread"
    t.decimal  "over_under"
    t.string   "game_time"
    t.decimal  "home_score"
    t.decimal  "away_score"
    t.string   "game_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "game_status"
  end

  create_table "leagues", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.string   "encrypted_password"
    t.integer  "manager"
    t.text     "league_settings"
    t.string   "salt"
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
  end

  create_table "memberships", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.integer  "league_id"
    t.text     "credits"
    t.string   "record"
    t.integer  "buy_backs"
  end

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "encrypted_password"
    t.string   "salt"
    t.boolean  "admin",              :default => false
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true

end
