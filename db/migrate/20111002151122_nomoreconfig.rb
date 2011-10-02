class Nomoreconfig < ActiveRecord::Migration
  def up
    drop_table "config_categories"
    drop_table "config_options"
  end

  def down
    create_table "config_categories", do |t|
      t.string  "name",           :limit => 50, :default => "",    :null => false
      t.boolean "is_system",                    :default => false, :null => false
      t.integer "category_order", :limit => 3,  :default => 0,     :null => false
    end

    add_index "config_categories", ["category_order"], :name => "index_config_categories_on_category_order"
    add_index "config_categories", ["name"], :name => "index_config_categories_on_name", :unique => true

    create_table "config_options", do |t|
      t.string  "category_name",        :limit => 30, :default => "",    :null => false
      t.string  "name",                 :limit => 50, :default => "",    :null => false
      t.text    "value"
      t.string  "config_handler_class", :limit => 50, :default => "",    :null => false
      t.boolean "is_system",                          :default => false, :null => false
      t.integer "option_order",         :limit => 8,  :default => 0,     :null => false
      t.string  "dev_comment"
    end

    add_index "config_options", ["category_name"], :name => "index_config_options_on_category_name"
    add_index "config_options", ["name"], :name => "index_config_options_on_name", :unique => true
    add_index "config_options", ["option_order"], :name => "index_config_options_on_option_order"
  end
end
