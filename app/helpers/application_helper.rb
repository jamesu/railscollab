=begin
RailsCollab
-----------
Copyright (C) 2007 James S Urquhart (jamesu at gmail.com)This program is free software; you can redistribute it and/ormodify it under the terms of the GNU General Public Licenseas published by the Free Software Foundation; either version 2of the License, or (at your option) any later version.This program is distributed in the hope that it will be useful,but WITHOUT ANY WARRANTY; without even the implied warranty ofMERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See theGNU General Public License for more details.You should have received a copy of the GNU General Public Licensealong with this program; if not, write to the Free SoftwareFoundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
=end

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

	def system_notices
	    []
	end
	
	def site_name
		html_escape AppConfig.site_name
	end
	
	def product_signature
		:product_signature.l
	end
	
	def pagination_links(url, ids)
	 values = ids.collect do |id|
	   "<a href=\"#{url}page=#{id}\">#{id}</a>"
	 end.join ' | '
	 
	 "<div class=\"advancedPagination\"><span>Page: </span><span>(#{values})</span></div>"
	end

	def checkbox_link(link, checked=false, hint=nil, attrs={})
    	icon_url = checked ? '/images/icons/checked.gif' : '/images/icons/not-checked.gif'
    	
    	link_to "<img src='#{icon_url}' alt='' />", link, attrs.merge({:method => :post, :class => 'checkboxLink', :title => ( hint.nil? ? '' : (html_escape hint) )})
	end
	
	def render_icon(filename, alt, attrs={})
		attr_values = attrs.keys.collect do |a|
			"#{a}='#{attrs[a]}'"
		end.join ' '
		
		"<img src='/images/icons/#{filename}.gif' alt='#{alt}' #{attr_values}/>"
	end
	
	def action_list(actions)
		actions.collect do |action|
			if action[:cond]
				extras = {}
				extras[:confirm] = action[:confirm] if action.has_key? :confirm
				extras[:method] = action[:method] if action.has_key? :method
				extras[:onclick] = action[:onclick] if action.has_key? :onclick
				extras[:id] = action[:id] if action.has_key? :id
				
				link_to action[:name], action[:url], extras
			else
				nil
			end
		end.compact.join(' | ')
	end
	
	def tag_list(object)
		tags = Tag.list_by_object(object)
		
		if !tags.empty?
			tags.collect do |tag|
				tag_name = (h tag)
				"<a href=\"/project/#{object.project_id}/tags/#{tag_name}\">#{tag_name}</a>"
			end.join(', ')
		else
			"--"
		end
	end
	
	def country_code_select(object_name, method, extra_options={})
		countries = [TZInfo::Country.all.collect{|x|x.name},
		             TZInfo::Country.all_codes].transpose.sort
		select(object_name, method, countries, extra_options)
	end
	
	def format_size(value)
		kbs = value / 1024
		mbs = kbs / 1024
		
		if kbs > 0
			if mbs > 0
				"#{mbs}MB"
			else
				"#{kbs}KB"
			end
		else
			"#{value}B"
		end
	end
	
	def format_usertime(time, format, user=@logged_user)
		return '' if time.nil?
		adjusted_time = time + ((user.timezone * 60.0 * 60.0).to_i)
		adjusted_time.strftime(format)
	end
	
	def yesno_toggle(object_name, method, options = {})
		radio_button(object_name, method, "true", options.merge({:id => "#{options[:id]}Yes"})) +
		" <label for=\"#{options[:id]}Yes\" class=\"#{options[:class]}\">#{:yesno_yes.l}</label> " +
		radio_button(object_name, method, "false", options.merge({:id => "#{options[:id]}No"})) +
		" <label for=\"#{options[:id]}No\" class=\"#{options[:class]}\">#{:yesno_no.l}</label>"
	end
	
	def yesno_toggle_tag(name, is_yes, options = {})
		radio_button_tag(name, "1", is_yes, options.merge({:id => "#{options[:id]}Yes"})) +
		" <label for=\"#{options[:id]}Yes\" class=\"#{options[:class]}\">#{:yesno_yes.l}</label> " +
		radio_button_tag(name, "0", !is_yes, options.merge({:id => "#{options[:id]}No"})) +
		" <label for=\"#{options[:id]}No\" class=\"#{options[:class]}\">#{:yesno_no.l}</label>"
	end
	
	#def textilize(text)
	# "<p>#{text}</p>"
	#end
end
