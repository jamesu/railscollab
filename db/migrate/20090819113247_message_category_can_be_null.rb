class MessageCategoryCanBeNull < ActiveRecord::Migration
  def self.up
    change_column_null :project_messages, :category_id, true
  end

  def self.down
    change_column_null :project_messages, :category_id, false
  end
end
