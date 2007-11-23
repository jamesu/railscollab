namespace :db do
	namespace :railscollab do
		desc 'Loads the database schema and inserts initial content'
		task :install => :environment do
			puts "\nLoading schema..."
			Rake::Task["db:schema:load"].invoke
			Rake::Task["db:railscollab:install_content"].invoke
		end

		task :install_content => :environment do
			puts "\nLoading initial content..."
			load("db/default_content.rb")
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
			puts "\nDone.\n"
		end
		
		task :migrate_from_basecamp => :environment do
			puts "\nMigrating from BaseCamp..."
			Rake::Task["db:schema:load"].invoke unless ENV['RAILSCOLLAB_SCHEMA_EXISTS']
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
end
