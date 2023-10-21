class SetPersonDefault < ActiveRecord::Migration[7.1]
  def change
    change_column :people, :code, :integer, default: 0xFFFFFF, limit: 8, null: false
  end
end
