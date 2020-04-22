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

ActiveRecord::Schema.define(version: 2020_03_21_041225) do

  create_table "currencies", force: :cascade do |t|
    t.string "name"
    t.string "code"
    t.decimal "exchange_rate"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "symbol"
  end

  create_table "deal_records", force: :cascade do |t|
    t.string "deal_type"
    t.string "symbol"
    t.decimal "price"
    t.decimal "amount"
    t.decimal "fees"
    t.string "purpose"
    t.decimal "loss_limit"
    t.decimal "earn_limit"
    t.boolean "auto_sell"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "account"
    t.integer "data_id"
    t.string "order_id"
    t.decimal "real_profit"
    t.boolean "first_sell"
  end

  create_table "interests", force: :cascade do |t|
    t.integer "property_id"
    t.date "start_date"
    t.decimal "rate"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["property_id"], name: "index_interests_on_property_id"
  end

  create_table "items", force: :cascade do |t|
    t.integer "property_id"
    t.decimal "price"
    t.decimal "amount"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["property_id"], name: "index_items_on_property_id"
  end

  create_table "open_orders", force: :cascade do |t|
    t.string "order_id"
    t.string "symbol"
    t.decimal "amount"
    t.decimal "price"
    t.string "order_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "portfolios", force: :cascade do |t|
    t.string "name"
    t.string "include_tags"
    t.string "exclude_tags"
    t.integer "order_num"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "mode"
    t.integer "twd_amount"
    t.integer "cny_amount"
    t.decimal "proportion"
  end

  create_table "properties", force: :cascade do |t|
    t.string "name"
    t.decimal "amount", default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "currency_id"
    t.boolean "is_hidden"
    t.boolean "is_locked"
    t.index ["currency_id"], name: "index_properties_on_currency_id"
  end

  create_table "records", force: :cascade do |t|
    t.string "class_name"
    t.integer "oid"
    t.decimal "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "taggings", force: :cascade do |t|
    t.integer "tag_id"
    t.string "taggable_type"
    t.integer "taggable_id"
    t.string "tagger_type"
    t.integer "tagger_id"
    t.string "context", limit: 128
    t.datetime "created_at"
    t.index ["context"], name: "index_taggings_on_context"
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context"
    t.index ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy"
    t.index ["taggable_id"], name: "index_taggings_on_taggable_id"
    t.index ["taggable_type"], name: "index_taggings_on_taggable_type"
    t.index ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_id_and_tagger_type"
    t.index ["tagger_id"], name: "index_taggings_on_tagger_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name"
    t.integer "taggings_count", default: 0
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "trial_lists", force: :cascade do |t|
    t.date "trial_date"
    t.decimal "begin_price"
    t.decimal "begin_amount"
    t.integer "month_cost"
    t.decimal "month_sell"
    t.integer "begin_balance"
    t.integer "begin_balance_twd"
    t.decimal "month_grow_rate"
    t.decimal "end_price"
    t.integer "end_balance"
    t.integer "end_balance_twd"
  end

end
