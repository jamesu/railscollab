xml.instruct!

xml.rss "version" => "2.0", "xmlns:dc" => "http://purl.org/dc/elements/1.1/" do

  xml.channel do 
    xml.title I18n.t('recent_milestones_feed')
    xml.link @milestones_url
    xml.description I18n.t('recent_milestones_feed_info')

    xml.language 'en-us'
    @milestones.each do |milestone|
      xml.item do
        item_url = milestone.object_url(Rails.configuration.railscollab.site_url)

        xml.title "#{milestone.name}"
        xml.category milestone.project.name, milestone.created_by.display_name
        xml.link item_url
        xml.guid item_url
        xml.pubDate CGI.rfc1123_date(milestone.due_date)
      end
    end
  end

end
