ActionController::Routing::Routes.draw do |map|
  root :to => 'dashboard#index'

  # feed url's
  match 'feed/:user/:token/:action.:format',          :controller => 'feed'
  match 'feed/:user/:token/:action.:project.:format', :controller => 'feed'
  
  # The rest of the simple controllers
  %w[dashboard].each do |controller|
  	map.connect "#{controller}/:action/:id",        :controller => controller
  	map.connect "#{controller}/:action/:id.format", :controller => controller
  end

  map.resource :session, :only => [:new, :create, :destroy]
  map.login 'login', :controller => 'sessions', :action => 'new'
  map.logout 'logout', :controller => 'sessions', :action => 'destroy', :method => :delete
    
  # project & project object url's
  map.resources :projects,
                          :member => { :people => :get,
                                       :search => [:get, :post],
                                       :users => [:delete],
                                       :companies => [:delete],
                                       :complete => :put,
                                       :open => :put,
                                       :permissions => [:get, :put]},
                          :has_many => [:tags]
  
  # Nested routes don't seem to work with path_prefix...
  map.with_options :path_prefix => 'projects/:active_project' do |project|
    project.resources :task_lists,
                               :member => {:reorder => :any}
    project.resources :tasks, :path_prefix => 'projects/:active_project/task_lists/:task_list_id',
                          :member => {:status => :put},
                          :has_many => [:comments]
    
    WikiEngine.draw_for project

    project.resources :comments
    # Note: filter by category is done via "posts" on the category controller
    project.resources :messages,
                           :member => {:unsubscribe => :put, :subscribe => :put},
                           :has_many => [:comments]
  
    project.resources :categories, :member => {:posts => :get}
  
    project.resources :folders, :member => {:files => :get}
  
    project.resources :files,
                        :member => {:download => :get, :attach => [:get, :put], :detatch => :put},
                        :has_many => [:comments]
  
    project.resources :milestones, :member => {:open => :put, :complete => :put}
  
    project.resources :times,
                        :member => {:stop => :put},
                        :collection => {:by_task => :get}
  end
  
 
  map.resource :password, :only => [:new, :create]
  map.resources :users, :member => {:avatar => [:get, :put, :delete],
                                    :permissions => [:get, :put]},
                        :collection => {:current => :get} do |users|
    users.resource :password, :only => [:edit, :update]
  end

  map.resources :companies, :member => {:logo => [:get, :put, :delete],
                                        :hide_welcome_info => :put,
                                        :permissions => [:get, :put]}
  map.resources :configurations, :only => [:index, :edit, :update]
  map.resources :tools, :only => [:index]

  map.administration 'administration', :controller => 'administration', :action => 'index'

  # Install the default route as the lowest priority.
  #map.connect ':controller/:action/:id.:format'
  #map.connect ':controller/:action/:id'
end
