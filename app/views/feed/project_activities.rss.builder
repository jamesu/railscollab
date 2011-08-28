xml.instruct!

xml.rss "version" => "2.0", "xmlns:dc" => "http://purl.org/dc/elements/1.1/" do

  xml.channel do 
    xml.title I18n.t('recent_project_activities_feed', :project => @project.name)
    xml.link @activity_url
    xml.description I18n.t('recent_project_activities_feed_info', :project => @project.name)
    xml.language 'en-us'
    @activity_log.each do |activity|
      xml.item do
        item_url = activity.rel_object ? activity.rel_object.object_url(Rails.configuration.site_url) : root_url

        xml.title "#{activity.friendly_action} #{activity.object_name}"
        xml.category activity.project.name, activity.created_by.display_name
        xml.link item_url
        xml.guid item_url
        xml.pubDate CGI.rfc1123_date(activity.created_on)

        xml.tag!('dc:creator', activity.created_by.display_name)
      end
    end
  end

end
