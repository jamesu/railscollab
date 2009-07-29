class AddFirstDayOfWeekOption < ActiveRecord::Migration
  def self.up
    opt = ConfigOption.new(:category_name => 'general', :name => 'first_day_of_week', :config_handler_class => 'DayConfigHandler', :is_system => false, :option_order => 13, :dev_comment => '')
    opt.handledValue = 7
    opt.save
  end

  def self.down
    ConfigOption.delete_all :name => 'first_day_of_week'
  end
end
