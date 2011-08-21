require 'tzinfo'

class LongerCountry < ActiveRecord::Migration
  def self.up
    change_column :companies, 'country', :string, :limit => 100
    
    # Convert to full name
    Company.all.each do |company|
        company.update_attribute 'country', TZInfo::Country.get(company.country).name rescue nil
    end
  end

  def self.down
    codes = {}
    TZInfo::Country.all.each{ |x| codes[x.name] = x.code }
    
    # Convert back to code
    Company.all.each do |company|
      company.update_attribute 'country', (codes[company.country] || '')
    end
  end
end