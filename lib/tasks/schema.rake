require 'ostruct'
require 'yaml'

namespace :db do
  namespace :railscollab do
    desc 'Loads the database schema and inserts initial content'
    task :install => :environment do
      puts "\nLoading schema..."
      Rake::Task["db:schema:load"].invoke
      Rake::Task["db:seed"].invoke
    end
    
    task :migrate_from_basecamp => :environment do
      puts "\nMigrating from BaseCamp..."
      Rake::Task["db:schema:load"].invoke unless ENV['RAILSCOLLAB_SCHEMA_EXISTS']
      Rake::Task["db:railscollab:load_config_schema"].invoke
      load("db/migrate_basecamp.rb")
    end
    
    # Courtesy of Retrospectiva, Copyright (C) 2006 Dimitrij Denissenko
    desc 'Converts mysql tables to use myisam engine.'
    task :mysql_convert_to_myisam => :environment do
      ActiveRecord::Base.establish_connection
      if ActiveRecord::Base.connection.adapter_name == 'MySQL'
        puts "\n===== Converting to MyISAM"
        ActiveRecord::Base.connection.tables.each do |table_name|
          puts "----- Converting to #{table_name}"
          ActiveRecord::Base.connection.execute("ALTER TABLE `#{table_name}` ENGINE = MYISAM")
        end
        puts "===== Finished\n"
      else
        puts "\nYou are not using a MySQL database!\n"
      end
    end
  end
  
  # Courtesy of http://blog.bloople.net/read/dumping-fixtures
  namespace :fixtures do
    desc 'Dumps all models into fixtures.'
    task :dump => :environment do
      table_list = ['users', 'companies', 'config_categories', 'config_options']
      table_list.each do |table|
        puts "Dumping #{table}"
        rows = ActiveRecord::Base.connection.select_all("SELECT * FROM #{ActiveRecord::Base.connection.quote_table_name(table)} ORDER BY id ASC")
        out = {}
        rows.each_with_index { |mi, i| out["#{table.singularize}_#{i + 1}"] = mi }
      
        model_file = ::Rails.root + "/test/fixtures/#{table}.yml"
        
        File.exists?(model_file) ? File.delete(model_file) : nil
        File.open(model_file, 'w') {|f| f << YAML.dump(out).gsub("<%", "<%%") }
      end
    end
  end
end
