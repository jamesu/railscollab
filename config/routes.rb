ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.
  
  # Sample of regular route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  # map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # You can have the root of your site routed by hooking up '' 
  # -- just remember to delete public/index.html.
  map.root :controller => 'dashboard'

  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  map.connect ':controller/service.wsdl', :action => 'wsdl'

  # feed url's
  map.connect 'feed/:user/:token/:action.:format',          :controller => 'feed'
  map.connect 'feed/:user/:token/:action.:project.:format', :controller => 'feed'
  
  # The rest of the simple controllers
  %w[dashboard].each do |controller|
  	map.connect "#{controller}/:action/:id",        :controller => controller
  	map.connect "#{controller}/:action/:id.format", :controller => controller
  end

  map.resource :session, :only => [:new, :create, :destroy]
  map.login 'login', :controller => 'sessions', :action => 'new'
  map.logout 'logout', :controller => 'sessions', :action => 'destroy', :method => :delete

  # BaseCamp API
  map.connect 'project/list',                                       :controller => 'basecamp', :action => 'projects_list'
  map.connect 'project/show/:id',                                   :controller => 'basecamp', :action => 'project_show'
  map.connect 'projects/:active_project/attachment_categories',     :controller => 'basecamp', :action => 'projects_attachment_categories'
  map.connect 'projects/:active_project/post_categories',           :controller => 'basecamp', :action => 'projects_post_categories'
  map.connect 'contacts/companies',                                 :controller => 'basecamp', :action => 'contacts_companies'
  map.connect 'contacts/company/:id',                               :controller => 'basecamp', :action => 'contacts_company'
  map.connect 'contacts/people/:id',                                :controller => 'basecamp', :action => 'contacts_people'
  map.connect 'projects/:active_project/contacts/people/:id',       :controller => 'basecamp', :action => 'contacts_people'
  map.connect 'contacts/person/:id',                                :controller => 'basecamp', :action => 'contacts_person'
  map.connect 'msg/comment/:id',                                    :controller => 'basecamp', :action => 'msg_comment'
  map.connect 'msg/comments/:id',                                   :controller => 'basecamp', :action => 'msg_comments'
  map.connect 'msg/create_comment/:id',                             :controller => 'basecamp', :action => 'msg_create_comment'
  map.connect 'projects/:active_project/msg/create',                :controller => 'basecamp', :action => 'projects_msg_create'
  map.connect 'msg/delete_comment/:id',                             :controller => 'basecamp', :action => 'msg_delete_comment'
  map.connect 'msg/delete/:id',                                     :controller => 'basecamp', :action => 'msg_delete'
  map.connect 'msg/get/:ids',                                       :controller => 'basecamp', :action => 'msg_get', :requirements => {:ids => %r([^/;?]+)}
  map.connect 'projects/:active_project/msg/archive',               :controller => 'basecamp', :action => 'projects_msg_archive'
  map.connect 'projects/:active_project/msg/cat/:cat_id/archive',   :controller => 'basecamp', :action => 'projects_msg_archive'
  map.connect 'msg/update_comment',                                 :controller => 'basecamp', :action => 'msg_update_comment'
  map.connect 'msg/update/:id',                                     :controller => 'basecamp', :action => 'msg_update'
  map.connect 'todos/complete_item/:id',                            :controller => 'basecamp', :action => 'todos_complete_item'
  map.connect 'todos/create_item/:list_id',                         :controller => 'basecamp', :action => 'todos_create_item'
  map.connect 'projects/:active_project/todos/create_list',         :controller => 'basecamp', :action => 'projects_todos_create_list'
  map.connect 'todos/delete_item/:id',                              :controller => 'basecamp', :action => 'todos_delete_item'
  map.connect 'todos/delete_list/:id',                              :controller => 'basecamp', :action => 'todos_delete_list'
  map.connect 'todos/list/:id',                                     :controller => 'basecamp', :action => 'todos_list'
  map.connect 'projects/:active_project/todos/list/:id',            :controller => 'basecamp', :action => 'todos_list'
  map.connect 'projects/:active_project/todos/lists',               :controller => 'basecamp', :action => 'projects_todos_lists'
  map.connect 'todos/move_item/:id',                                :controller => 'basecamp', :action => 'todos_move_item'
  map.connect 'todos/move_list/:id',                                :controller => 'basecamp', :action => 'todos_move_list'
  map.connect 'todos/uncomplete_item/:id',                          :controller => 'basecamp', :action => 'todos_uncomplete_item'
  map.connect 'todos/update_item/:id',                              :controller => 'basecamp', :action => 'todos_update_item'
  map.connect 'todos/update_list/:id',                              :controller => 'basecamp', :action => 'todos_update_list'
  map.connect 'milestones/complete/:id',                            :controller => 'basecamp', :action => 'milestones_complete'
  map.connect 'projects/:active_project/milestones/create',         :controller => 'basecamp', :action => 'projects_milestones_create'
  map.connect 'milestones/delete/:id',                              :controller => 'basecamp', :action => 'milestones_delete'
  map.connect 'projects/:active_project/milestones/list',           :controller => 'basecamp', :action => 'projects_milestones_list'
  map.connect 'milestones/uncomplete/:id',                          :controller => 'basecamp', :action => 'milestones_uncomplete'
  map.connect 'milestones/update/:id',                              :controller => 'basecamp', :action => 'milestones_update'
  map.connect 'time/save_entry',                                    :controller => 'basecamp', :action => 'time_save_entry'
  map.connect 'projects/:active_project/time/delete_entry/:id',     :controller => 'basecamp', :action => 'projects_time_delete_entry'
  map.connect 'time/report/:id/:from/:to/:filter',                  :controller => 'basecamp', :action => 'time_report'
  map.connect 'time/report//:from/:to/:filter',                     :controller => 'basecamp', :action => 'time_report' # Dodgy widget hack
  map.connect 'time/save_entry/:id',                                :controller => 'basecamp', :action => 'time_update_entry'
    
  # Useful BaseCamp RSS Feeds
  map.connect '/feed/recent_items_rss',                         :controller => 'basecamp', :action => 'recent_items_rss'
  map.connect 'projects/:active_project/feed/recent_items_rss', :controller => 'basecamp', :action => 'recent_project_items_rss'
    
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
  map.resources :task_lists, :path_prefix => 'project/:active_project',
                             :member => {:reorder => :any}
  map.resources :tasks, :path_prefix => 'project/:active_project/task_lists/:task_list_id',
                        :member => {:status => :put},
                        :has_many => [:comments]
  map.with_options :path_prefix => 'project/:active_project' do |project|
    WikiEngine.draw_for project
  end
  
  map.resources :comments, :path_prefix => 'project/:active_project'
  
  # Note: filter by category is done via "posts" on the category controller
  map.resources :messages, :path_prefix => 'project/:active_project',
                           :member => {:unsubscribe => :put,
                                       :subscribe => :put},
                           :has_many => [:comments]
  
  map.resources :categories, :path_prefix => 'project/:active_project',
                             :member => {:posts => :get}
  
  map.resources :folders, :path_prefix => 'project/:active_project',
                          :member => {:files => :get}
  
  map.resources :files, :path_prefix => 'project/:active_project',
                        :member => {:download => :get,
                                    :attach => [:get, :put],
                                    :detatch => :put},
                        :has_many => [:comments]
  
  map.resources :milestones, :path_prefix => 'project/:active_project',
                             :member => {:open => :put,
                                         :complete => :put}
  
  map.resources :times, :path_prefix => 'project/:active_project',
                        :member => {:stop => :put},
                        :collection => {:by_task => :get}
 
  map.resource :password, :only => [:new, :create]
  map.resources :users, :member => {:avatar => [:get, :put, :delete],
                                    :permissions => [:get, :put]} do |users|
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
