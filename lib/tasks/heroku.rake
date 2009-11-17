namespace :heroku do
	task :config do
		if !ENV['app']
			puts "Usage: rake heroku:config app=[name of app]"
			return
		end
		puts "Reading config/config.yml and sending config vars to Heroku..."
		session_key_settings = YAML.load_file("config/app_keys.yml") rescue {}
		config_yml_settings = YAML.load_file('config/config.yml')['production'] rescue {}
		command = "heroku config:add --app #{ENV['app']}"
		session_key_settings.merge(config_yml_settings).each {|key, val| command << " #{key}=#{val} " if val }
		system command
	end
end
