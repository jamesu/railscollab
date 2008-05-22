ConfigCategory.destroy_all
ConfigOption.destroy_all

category_count = 0
config = YAML.load_file("#{RAILS_ROOT}/config/config_schema.yml")
config.keys.each do |key|
	options = config[key]
	category = ConfigCategory.new(:name => key, :is_system => (:name == 'system'), :category_order => category_count)
	category.save
	
	# Create options
	options.keys.each do |opt_key|
		option = options[opt_key]
		
		if opt_key == 'order'
			category.order = option
			next
		end
		
		#puts "#{opt_key} => #{option.keys.each { |key| key }.join(',')}"
		opt = ConfigOption.new(:category_name => category.name, :name => opt_key, :config_handler_class => option['handler'], :is_system => category.is_system, :option_order => option['order'], :dev_comment => option['comment'])
		opt.handledValue = option['default']
		opt.save
		
		puts "#{opt_key} handled by #{option['handler']}"
		
	end
	
	category_count += 1
end
