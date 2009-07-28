module WikiEngine::Helper
  # Format wiki text to html.
  def wiki_text(string)
    return '' unless string

    string = string.dup

    # Convert wiki links of type "Some stuff":[[hello-world]]
    string.gsub!(/"([^"]+)":\[\[\s*([^\]]+)\s*\]\]/) do
      "\"#{$1}\":#{wiki_page_path(:id => wiki_title_to_id($2))}"
    end

    # Convert wiki links of type [[hello-world]]
    string.gsub!(/\[\[\s*([a-z0-9_\-]+)\s*\]\]/) do
      "\"#{wiki_id_to_title($1)}\":#{wiki_page_path(:id => $1)}"
    end

    # Convert wiki links of type [[Hello world]]
    string.gsub!(/\[\[\s*([^\]]+)\s*\]\]/) do
      "\"#{$1}\":#{wiki_page_path(:id => wiki_title_to_id($1))}"
    end

    string = textilize(string)
    string
  end

  # Render widget with list of wiki pages.
  def wiki_pages_widget(wiki_pages)
    render :partial => 'widget', :locals => {:wiki_pages => wiki_pages}
  end

  def preview_button
    button_to_remote t('wiki_engine.preview'), {:url => preview_wiki_pages_path, :method => :put, :update => 'preview', :with => 'Form.serialize(this.form)', :complete => 'Element.scrollTo("preview")'}, :class => 'preview'
  end

  def current_version(version)
    [t("wiki_engine.current_version#{'_edited_by' unless version.user_name.blank?}", :user => version.user_name), wiki_page_path(:id => version.wiki_page)]
  end

  def versions(versions)
    versions.collect do |version|
      [t("wiki_engine.version#{'_edited_by' unless version.user_name.blank?}", :version => version.version, :user => version.user_name), version_wiki_page_path(:id => version.wiki_page, :version => version.version)]
    end
  end

  def options_for_versions_select(versions)
    options_for_select [current_version(@versions.first), *versions(@versions[1..-1])], :selected => request.path
  end

  private

  def wiki_id_to_title(id)
    id.underscore.humanize
  end

  def wiki_title_to_id(title)
    WikiPage.new(:title => title).slug_text
  end
end
