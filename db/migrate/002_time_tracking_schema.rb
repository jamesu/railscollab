class TimeTrackingSchema < ActiveRecord::Migration
  def self.up
	  create_table :project_time do |t|
	    t.column "project_id",             :integer,  :limit => 10
	    t.column "task_list_id",           :integer
	    t.column "task_id",                :integer
	    t.column "name",                   :string,   :limit => 100
	    t.column "description",            :text
	    t.column "done_date",              :datetime,                                   :null => false
	    t.column "hours",                  :float,    :limit => 4,   :default => 0.0,   :null => false
	    t.column "is_billable",            :boolean,                 :default => true,  :null => false
	    t.column "assigned_to_company_id", :integer,  :limit => 10,  :default => 0,     :null => false
	    t.column "assigned_to_user_id",    :integer,  :limit => 10,  :default => 0,     :null => false
	    t.column "is_private",             :boolean,                 :default => false, :null => false
	    t.column "created_on",             :datetime,                                   :null => false
	    t.column "created_by_id",          :integer,  :limit => 10
	    t.column "updated_on",             :datetime,                                   :null => false
	    t.column "updated_by_id",          :integer,  :limit => 10
	  end
	
	  add_index :project_time, ["project_id"]
	  add_index :project_time, ["done_date"]
	  add_index :project_time, ["created_on"]
	  
	  add_column :project_users, "can_manage_time", :boolean,  :default => false, :null => false
  end

  def self.down
  	  drop_table :project_time
  	  remove_column :project_users, "can_manage_time"
  end
end
