class AddDefaultAssignTask < ActiveRecord::Migration[7.1]
  def change
    change_column :tasks, :assigned_to_company_id, :integer, default: 0, limit: 8, null: false
    change_column :tasks, :assigned_to_user_id, :integer, default: 0, limit: 8, null: false
  end
end
