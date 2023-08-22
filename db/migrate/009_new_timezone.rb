class NewTimezone < ActiveRecord::Migration[4.2]
  def self.up
    add_column :users, :time_zone, :string, :null => false, :default => ''
    add_column :companies, :time_zone, :string, :null => false, :default => ''
    
    User.all.each do |user|
        user.time_zone = TimeZone[user.timezone].name
        user.save
    end
    
    Company.all.each do |company|
        company.time_zone = TimeZone[company.timezone].name
        company.save
    end
    
    remove_column :users, :timezone
    remove_column :companies, :timezone
  end

  def self.down
    add_column :users, :timezone, :float, :default => 0.0,   :null => false
    add_column :companies, :timezone, :float, :default => 0.0,   :null => false
    
    User.all.each do |user|
        time_zone = TimeZone[user.time_zone]
        time_zone ||= TimeZone[0]
        user.timezone = (time_zone.utc_offset).to_f / 60.0 / 60.0
        puts "time_zone == #{user.timezone}"
        user.save
    end
    
    Company.all.each do |company|
        time_zone = TimeZone[company.time_zone]
        time_zone ||= TimeZone[0]
        company.timezone = (time_zone.utc_offset).to_f / 60.0 / 60.0
        company.save
    end
    
    remove_column :users, :time_zone
    remove_column :companies, :time_zone
  end
end
