class Nomoreconfig < ActiveRecord::Migration[4.2]
  def up
    drop_table "config_categories"
    drop_table "config_options"
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Cannot revert this migration"
  end
end
