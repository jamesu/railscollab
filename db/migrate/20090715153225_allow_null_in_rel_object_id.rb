class AllowNullInRelObjectId < ActiveRecord::Migration
  def self.up
    change_column_null :application_logs, :rel_object_id, true, nil
  end

  def self.down
    change_column_null :application_logs, :rel_object_id, false, 0
  end
end
