require 'ostruct'
require 'yaml'

namespace :db do
	namespace :railscollab do
		desc 'Loads the database schema and inserts initial content'
		task :install => :environment do
			puts "\nLoading schema..."
			Rake::Task["db:schema:load"].invoke
			Rake::Task["db:railscollab:load_config_schema"].invoke
			Rake::Task["db:railscollab:install_content"].invoke
		end

		task :install_content => :environment do
			puts "\nLoading initial content..."
			load("db/default_content.rb")
		end
		
		task :reload_config => :environment do
		    puts "\nRe-loading configuration..."
		    Rake::Task["db:railscollab:dump_config"].invoke
		    Rake::Task["db:railscollab:load_config_schema"].invoke
		    Rake::Task["db:railscollab:load_config"].invoke
		    puts "Done."
		end
		
		task :load_config_schema => :environment do
			puts "\nLoading configuration schema..."
			load("db/default_config.rb")
		end
		
		task :dump_config => :environment do
			puts "Dumping configuration to config/config.yml"
			config = OpenStruct.new()
			ConfigOption.dump_config(config)
			File.open("#{RAILS_ROOT}/config/config.yml", 'w') do |file|
				file.puts YAML::dump(config.marshal_dump)
			end
		end
		
		task :load_config => :environment do
			puts "Loading configuration from config/config.yml"
			config = OpenStruct.new(YAML.load_file("#{RAILS_ROOT}/config/config.yml"))
			ConfigOption.load_config(config)
		end
		
		task :migrate_from_activecollab => :environment do
			# NOTE: should probably replace this with something more generic later
			puts "\nMigrating from ActiveCollab..."
			activecollab_version = ENV['ACTIVECOLLAB_VERSION']
			activecollab_version ||= '0.7.1'
			base_schema_version = 0
			
			ActiveRecord::Base.establish_connection
			if ActiveRecord::Base.connection.adapter_name != 'MySQL'
				puts "\nYou are not using a MySQL database!\n"
				return
			end
			
			case activecollab_version
				when '0.7.1'
					if ActiveRecord::Base.connection.tables.include? 'project_time'
						puts 'Looks like its 0.7.1 with the time tracking enhancements...'
						base_schema_version = 2
					else
						base_schema_version = 1
					end
				else
					puts "\nUnknown version, aborting!\n"
					return
			end
			
			# Insert the schema version table
			ActiveRecord::Base.connection.execute("CREATE TABLE schema_info (version int)")
			ActiveRecord::Base.connection.execute("INSERT INTO schema_info VALUES (#{base_schema_version})")
			
			puts "Migrating..."
			Rake::Task["db:migrate"].invoke
			Rake::Task["db:railscollab:load_config_schema"].invoke
			puts "\nDone.\n"
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
		
		desc 'Sets the MYSQL blob size for ProjectFiles accordingly'
		task :fix_files => :environment do
			ActiveRecord::Base.establish_connection
			if ActiveRecord::Base.connection.adapter_name == 'MySQL'
				puts "\nFixing file size schema..."
				ActiveRecord::Base.connection.execute("ALTER TABLE file_repo MODIFY content LONGBLOB NOT NULL DEFAULT ''")
				puts "Done\n"
			else
				puts "\nDatabase not supported by this task!\n"
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
      
        model_file = RAILS_ROOT + "/test/fixtures/#{table}.yml"
        
        File.exists?(model_file) ? File.delete(model_file) : nil
        File.open(model_file, 'w') {|f| f << YAML.dump(out).gsub("<%", "<%%") }
      end
    end
  end
end
