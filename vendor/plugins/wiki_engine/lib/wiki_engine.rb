module WikiEngine
  def self.draw_for(map)
    map.resources :wiki_pages, :collection => {:preview => :put, :list => :get}
    map.version_wiki_page 'wiki_pages/:id/:version', :controller => 'wiki_pages', :action => 'show', :conditions => {:method => :get}
  end
end
