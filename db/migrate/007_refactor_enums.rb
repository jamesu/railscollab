class RefactorEnums < ActiveRecord::Migration
  @@log_lookup = {:add => 0, :upload => 1, :open => 2, :close => 3, :edit => 4, :delete => 5}
  @@form_lookup = {:add_comment => 1, :add_task => 2}
  
  def self.up
    # Replaces 'action' enum with 'action_id' which should be abstracted by the model
    #add_column :application_logs, "action_id", :integer, :limit => 1, :default => nil
    #add_column :project_forms, "action_id", :integer, :limit => 1, :default => nil
    
    @@log_lookup.keys.each do |key|
    	ApplicationLog.update_all("action_id = #{@@log_lookup[key]}", "action = '#{key}'")
    end
    
    @@form_lookup.keys.each do |key|
    	ProjectForm.update_all("action_id = #{@@form_lookup[key]}", "action = '#{key}'")
    end

    remove_column :application_logs, :action
    remove_column :project_forms, :action
  end

  def self.down
    # Replaces 'action_id' identifier with 'action' enum. Extra enums added in future revisions should default
    add_column :application_logs, "action", :enum, :limit => [:upload, :open, :close, :delete, :edit, :add]
    add_column :project_forms, "action",    :enum, :limit => [:add_comment, :add_task], :default => :add_comment, :null => false
    
    inverted_lookup = @@log_lookup.invert
    inverted_lookup.keys.each do |key|
    	ApplicationLog.update_all("action = '#{inverted_lookup[key]}'", "action_id = #{key}")
    end
    
    inverted_lookup = @@form_lookup.invert
    inverted_lookup.keys.each do |key|
    	ProjectForm.update_all("action = '#{inverted_lookup[key]}'", "action_id = #{key}")
    end

    remove_column :application_logs, "action_id"
    remove_column :project_forms, "action_id"
  end
end
