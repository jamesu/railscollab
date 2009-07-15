class AllowNullInRelObjectId < ActiveRecord::Migration
  def self.up
    change_column_null :application_logs, :rel_object_id, true, nil
    opt = ConfigOption.new(:category_name => 'general', :name => 'log_really_silent', :config_handler_class => 'BoolConfigHandler', :is_system => false, :option_order => 12, :dev_comment => '')
    opt.handledValue = false
    opt.save
  end

  def self.down
    change_column_null :application_logs, :rel_object_id, false, 0
    ConfigOption.delete_all :name => 'log_really_silent'
  end
end
