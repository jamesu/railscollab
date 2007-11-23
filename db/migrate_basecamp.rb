#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/../config/environment'

basecamp_dump_location = ENV['BASECAMP_DUMP_FILE']
if basecamp_dump_location.nil?
	puts "Please specify the location of your Basecamp dump by setting the BASECAMP_DUMP_FILE environment variable"
	exit
end

# Load in the dump file
basecamp_dump_file = File.open(basecamp_dump_location, 'r')

xml = REXML::Document.new(basecamp_dump_file.read)

puts "Parsed dump file..."

START_DATE = Date.parse(xml.elements['account/created-on'].text)

MAP_IDS = {
	:companies => {},
	:users => {},
	:folders => {},
	:categories => {},
	:messages => {},
	:comments => {},
	:task_lists => {},
	:tasks => {},
	:milestones => {0 => 0},
	:owner => nil
}

# Ensure IM Types are present
if ImType.count == 0
	(ImType.new(:name => 'ICQ', :icon => 'icq.gif')).save!
	(ImType.new(:name => 'AIM', :icon => 'aim.gif')).save!
	(ImType.new(:name => 'MSN', :icon => 'msn.gif')).save!
	(ImType.new(:name => 'Yahoo!', :icon => 'yahoo.gif')).save!
	(ImType.new(:name => 'Skype', :icon => 'skype.gif')).save!
	(ImType.new(:name => 'Jabber', :icon => 'jabber.gif')).save!
end

# Ensure File Types are present
if FileType.count == 0
	(FileType.new(:extension => 'zip', :icon => 'archive.png', :is_searchable => 0, :is_image => 0)).save!
	(FileType.new(:extension => 'rar', :icon => 'archive.png', :is_searchable => 0, :is_image => 0)).save!
	(FileType.new(:extension => 'bz', :icon => 'archive.png', :is_searchable => 0, :is_image => 0)).save!
	(FileType.new(:extension => 'bz2', :icon => 'archive.png', :is_searchable => 0, :is_image => 0)).save!
	(FileType.new(:extension => 'gz', :icon => 'archive.png', :is_searchable => 0, :is_image => 0)).save!
	(FileType.new(:extension => 'ace', :icon => 'archive.png', :is_searchable => 0, :is_image => 0)).save!
	(FileType.new(:extension => 'mp3', :icon => 'audio.png', :is_searchable => 0, :is_image => 0)).save!
	(FileType.new(:extension => 'wma', :icon => 'audio.png', :is_searchable => 0, :is_image => 0)).save!
	(FileType.new(:extension => 'ogg', :icon => 'audio.png', :is_searchable => 0, :is_image => 0)).save!
	(FileType.new(:extension => 'doc', :icon => 'doc.png', :is_searchable => 0, :is_image => 0)).save!
	(FileType.new(:extension => 'xsl', :icon => 'doc.png', :is_searchable => 0, :is_image => 0)).save!
	(FileType.new(:extension => 'gif', :icon => 'image.png', :is_searchable => 0, :is_image => 1)).save!
	(FileType.new(:extension => 'jpg', :icon => 'image.png', :is_searchable => 0, :is_image => 1)).save!
	(FileType.new(:extension => 'jpeg', :icon => 'image.png', :is_searchable => 0, :is_image => 1)).save!
	(FileType.new(:extension => 'png', :icon => 'image.png', :is_searchable => 0, :is_image => 1)).save!
	(FileType.new(:extension => 'mov', :icon => 'mov.png', :is_searchable => 0, :is_image => 0)).save!
	(FileType.new(:extension => 'pdf', :icon => 'pdf.png', :is_searchable => 0, :is_image => 0)).save!
	(FileType.new(:extension => 'psd', :icon => 'psd.png', :is_searchable => 0, :is_image => 0)).save!
	(FileType.new(:extension => 'rm', :icon => 'rm.png', :is_searchable => 0, :is_image => 0)).save!
	(FileType.new(:extension => 'svg', :icon => 'svg.png', :is_searchable => 0, :is_image => 0)).save!
	(FileType.new(:extension => 'swf', :icon => 'swf.png', :is_searchable => 0, :is_image => 0)).save!
	(FileType.new(:extension => 'avi', :icon => 'video.png', :is_searchable => 0, :is_image => 0)).save!
	(FileType.new(:extension => 'mpeg', :icon => 'video.png', :is_searchable => 0, :is_image => 0)).save!
	(FileType.new(:extension => 'mpg', :icon => 'video.png', :is_searchable => 0, :is_image => 0)).save!
	(FileType.new(:extension => 'qt', :icon => 'mov.png', :is_searchable => 0, :is_image => 0)).save!
	(FileType.new(:extension => 'vob', :icon => 'video.png', :is_searchable => 0, :is_image => 0)).save!
	(FileType.new(:extension => 'txt', :icon => 'doc.png', :is_searchable => 1, :is_image => 0)).save!
end

def import_company(firm_attribs, owner=nil)
	company = Company.new(
		:name => firm_attribs['name'].text,
		:timezone_name => firm_attribs['time-zone-id'].text,
		:email => '', # not in dump?
		:homepage => firm_attribs['web-address'].text,
		:phone_number => firm_attribs['phone-number-office'].text,
		:fax_number => firm_attribs['phone-number-fax'].text,
		:address => firm_attribs['address-one'].text,
		:address2 => firm_attribs['address-two'].text,
		:city => firm_attribs['city'].text,
		:state => firm_attribs['state'].text,
		:zipcode => firm_attribs['zip'].text,
		:country_code => firm_attribs['country'].text
	)
	
	company.country_name = firm_attribs['country'].text
	company.client_of = owner

	puts "Adding company '#{company.name}'"
	company.save!
	company.created_on = START_DATE
	company.save!
	
	MAP_IDS[:companies][firm_attribs['id'].text.to_i] = company.id
	
	# Add people
	firm_attribs['people'].elements.each do |person|
		user_attribs = person.elements
		user = User.new(
			:display_name => "#{user_attribs['first-name'].text} #{user_attribs['last-name'].text}",
			:email => user_attribs['email-address'].text,
			:timezone_name => company.timezone_name,
			:title => user_attribs['title'].text,
			:office_number => user_attribs['phone-number-office'].text,
			:office_number_ext => user_attribs['phone-number-office-ext'].text,
			:fax_number => user_attribs['phone-number-fax'].text,
			:mobile_number => user_attribs['phone-number-mobile'].text,
			:home_number => user_attribs['phone-number-home'].text
		)
		
		user.username = user_attribs['user-name'].text
        user.is_admin = user_attribs['administrator'].nil? ? false : user_attribs['administrator'].text
        user.auto_assign = user_attribs['has-access-to-new-projects'].text
        user.identity_url = user_attribs['identity-url'].text
		user.company = company
		
		user.password = "password"
		user.save!
		
		MAP_IDS[:users][user_attribs['id'].text.to_i] = user.id
		MAP_IDS[:owner] ||= user
	end
end

# Owner company
xml.elements.each('account/firm') { |firm| import_company(firm.elements) }

puts "Inserted owner..."

# Client companies
xml.elements.each('account/clients/client')  { |client| import_company(client.elements, Company.owner) }

# Fix owners of all companies
Company.find(:all).each do |company|
	if company.created_by.nil?
		company.created_by = MAP_IDS[:owner]
		company.updated_by = MAP_IDS[:owner]
		company.save!
	end
end

puts "Inserted clients..."

# Projects
xml.elements.each('account/projects/project') do |bproject|
	project_attribs = bproject.elements
	
	project = Project.new(
		:name => project_attribs['name'].text,
		:description => 'Imported from BaseCamp',
		:show_description_in_overview => false
	)
	
	puts "Adding project '#{project.name}'"
	project.created_by = MAP_IDS[:owner]
	project.save!
	project.created_on = Date.parse(project_attribs['created-on'].text)
	project.updated_by = MAP_IDS[:owner]
	project.set_completed(true, MAP_IDS[:owner]) unless project_attribs['status'].text == 'active'
	project.save!
	
	# Iterate through project objects
	
	# Attachment categories...
	bproject.elements.each('attachment-categories/attachment-category') do |attach_category|
		folder = ProjectFolder.new(:name => attach_category.elements['name'].text)
		folder.project = project
		
		puts "  Adding folder '#{folder.name}'"
		folder.save!
		MAP_IDS[:folders][attach_category.elements['id'].text.to_i] = folder.id
		ApplicationLog::new_log(folder, MAP_IDS[:owner], :add)
	end
	
	# Message categories...
	bproject.elements.each('post-categories/post-category') do |post_category|
		category = ProjectMessageCategory.new(:name => post_category.elements['name'].text)
		category.project = project
		
		puts "  Adding category '#{category.name}'"
		category.save!
		MAP_IDS[:categories][post_category.elements['id'].text.to_i] = category.id
		ApplicationLog::new_log(category, MAP_IDS[:owner], :add)
	end
	
	# Milestones...
	bproject.elements.each('milestones/milestone') do |bmilestone|
		milestone_attribs = bmilestone.elements
		
		milestone = ProjectMilestone.new(
			:name => milestone_attribs['title'].text,
			:description => 'Imported from BaseCamp',
			:due_date => Date.parse(milestone_attribs['deadline'].text),
			:assigned_to_id => milestone_attribs['responsible-party-type'].text == 'Person' ? 
			                  MAP_IDS[:users][milestone_attribs['responsible-party-id'].text.to_i] : 
			                  "c#{MAP_IDS[:users][milestone_attribs['responsible-party-id'].text.to_i]}"
		)
		
		milestone.project = project
		milestone.created_by = User.find(MAP_IDS[:users][milestone_attribs['creator-id'].text.to_i])
		
		puts "  Adding milestone '#{milestone.name}'"
		milestone.save!
		milestone.created_on = Date.parse(project_attribs['created-on'].text)
		milestone.updated_by = MAP_IDS[:owner]
		if milestone_attribs['completed'].text == 'true'
			milestone.set_completed(true, User.find(MAP_IDS[:users][milestone_attribs['completer-id'].text.to_i]))
			milestone.completed_on = Time.parse(milestone_attribs['completed-on'].text)
		end
		milestone.save!
		
		MAP_IDS[:milestones][milestone_attribs['id'].text.to_i] = milestone.id
	end
	
	bproject.elements.each('todo-lists/todo-list') do |todo_list|
		todo_list_attribs = todo_list.elements
		
		task_list = ProjectTaskList.new(
			:name => todo_list_attribs['name'].text,
			:description => 'Imported from BaseCamp',
			:priority => todo_list_attribs['position'].text,
			:milestone_id => MAP_IDS[:milestones][todo_list_attribs['milestone-id'].text.to_i],
			:is_private => (!todo_list_attribs['private'].nil? ? (todo_list_attribs['private'].text == 'true') : false)
		)
		
		task_list.project = project
		task_list.created_by = MAP_IDS[:owner]
		
		puts "  Adding task list '#{task_list.name}'"
		task_list.save!
		
		MAP_IDS[:task_lists][todo_list_attribs['id'].text.to_i] = task_list.id
				
		# add todo items
		todo_list.elements.each('todo-items/todo-item') do |todo_item|
			todo_item_attribs = todo_item.elements
			
			task = ProjectTask.new(
				:text => todo_item_attribs['content'].text,
				:order => todo_item_attribs['position'].text,
				:assigned_to_id => todo_item_attribs['responsible-party-type'].nil? ? '0' :
				                  (todo_item_attribs['responsible-party-type'].text == 'Person' ? 
				                   MAP_IDS[:users][todo_item_attribs['responsible-party-id'].text.to_i] : 
				                   "c#{MAP_IDS[:users][todo_item_attribs['responsible-party-id'].text.to_i]}")
			)
			
			task.created_by = User.find(MAP_IDS[:users][todo_item_attribs['creator-id'].text.to_i])
			task.task_list = task_list
			puts "    Adding task '#{task.text}'"
			task.save!
			
			# Set completer manually so we don't keep messing with the todo list
			if !todo_item_attribs['completed-on'].nil?
				task.completed_on = Time.parse(todo_item_attribs['completed-on'].text)
				task.completed_by = User.find(MAP_IDS[:users][todo_item_attribs['completer-id'].text.to_i])
				
				# Update completion date of task list if this is more recent 
				if task_list.completed_by.nil? or (task_list.completed_on < task.completed_on)
					task_list.completed_by = task.completed_by
					task_list.completed_on = task.completed_on
				end
			end
			
			task.created_on = Time.parse(todo_item_attribs['created-on'].text)
			task.updated_by = MAP_IDS[:owner]
			task.save!
			
			MAP_IDS[:tasks][todo_item_attribs['id'].text.to_i] = task.id
		end
		
		task_list.updated_by = MAP_IDS[:owner]
		task_list.save!
	end
	
	bproject.elements.each('time-entries/time-entry') do |btime|
		time_attribs = btime.elements
		
		time = ProjectTime.new(
			:name => time_attribs['description'].text,
			:description => 'Imported from BaseCamp',
			:done_date => time_attribs['date'],
			:hours => time_attribs['hours'],
			:open_task_id => MAP_IDS[:tasks][time_attribs['todo-item-id'].text.to_i],
			:assigned_to_id => MAP_IDS[:users][time_attribs['person-id'].text.to_i]
		)
		
		time.project = project
		time.created_by = User.find(MAP_IDS[:users][time_attribs['person-id'].text.to_i])
		
		puts "  Adding time '#{time.name}'"
		time.save!
		
		MAP_IDS[:times][time_attribs['id'].text.to_i] = time.id
	end
	
	bproject.elements.each('posts/post') do |post|
		post_attribs = post.elements
		
		message = ProjectMessage.new(
			:title => post_attribs['title'].text,
			:text => post_attribs['body'].text,
			:additional_text => post_attribs['extended-body'].text,
			:milestone_id => MAP_IDS[:milestones][post_attribs['milestone-id'].text.to_i],
			:category_id => MAP_IDS[:categories][post_attribs['category-id'].text.to_i],
			:is_private => (!post_attribs['private'].nil? ? (post_attribs['private'].text == 'true') : false),
			:is_important => false,
			:comments_enabled => true,
			:anonymous_comments_enabled => false
		)
		
		message.project = project
		message.created_by = User.find(MAP_IDS[:users][post_attribs['author-id'].text.to_i])
		
		puts "  Adding message '#{message.title}'"
		message.save!
		message.created_on = Time.parse(post_attribs['posted-on'].text)
		message.updated_by = MAP_IDS[:owner]
		message.save!
		
		MAP_IDS[:messages][post_attribs['id'].text.to_i] = message.id
		
		# add comments
		post.elements.each('comments/comment') do |bcomment|
			comment_attribs = bcomment.elements
			
			comment = Comment.new(
				:text => comment_attribs['body'].text,
				:is_private => false
			)
			
			comment.created_by = User.find(MAP_IDS[:users][comment_attribs['author-id'].text.to_i])
			comment.rel_object = message
			
			comment.save!
			comment.created_on = Time.parse(comment_attribs['posted-on'].text)
			comment.updated_by = MAP_IDS[:owner]
			comment.save!
			
			MAP_IDS[:comments][comment_attribs['id'].text.to_i] = message.id
		end
	end
	
	# Add companies and users to the project
	project_companies = []
	bproject.elements.each('participants/person') do |person|
		user = User.find(MAP_IDS[:users][person.text.to_i])
		project.users << user
		project_companies << user.company
	end
	
	project_companies.uniq!
	project_companies.each { |company| project.companies << company }
end

puts "Inserted projects..."

puts "Done"
