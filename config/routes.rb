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
  map.connect '', :controller => "dashboard"

  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  map.connect ':controller/service.wsdl', :action => 'wsdl'

  # feed url's
  map.connect 'feed/:user/:token/:action.:format', :controller => 'feed'
  map.connect 'feed/:user/:token/:action.:project.:format', :controller => 'feed'

  # Account routes
  map.connect 'account', :controller => 'account'
  map.connect 'account/avatar/:id.png', :controller => 'account', :action => 'avatar', :format => 'png'
  
  ['edit_profile', 'edit_password', 'update_permissions', 'edit_avatar', 'delete_avatar'].each do |action|
  	map.connect 'account/:action/:id', :controller => 'account', :action => action
  	map.connect 'account/:action/:id.:format', :controller => 'account', :action => action
  end
  
  # Company routes
  map.connect 'company/logo/:id.png', :controller => 'company', :action => 'logo', :format => 'png'
  
  ['card', 'view_client', 'edit', 'add_client', 'edit_client', 'delete_client', 'update_permissions',
   'edit_logo', 'delete_logo', 'hide_welcome_info'].each do |action|
  	map.connect 'company/:action/:id', :controller => 'company', :action => action
  	map.connect 'company/:action/:id.:format', :controller => 'company', :action => action
  end
  
  # The rest of the simple controllers
  
  ['dashboard', 'access', 'administration', 'comment', 'user'].each do |controller|
  	map.connect "#{controller}/:action/:id", :controller => controller
  	map.connect "#{controller}/:action/:id.format", :controller => controller
  end
  
  map.connect "comment/add/:object_id.:object_type", :controller => 'comment', :action => 'add'
  
  map.connect 'administration/:action/:id.:format', :controller => 'administration'
  map.connect 'administration/:action/:id', :controller => 'administration'
  
  # project & project object url's
  map.connect 'project/add', :controller => 'project', :action => 'add'
  
  map.connect 'project/:active_project/tags', :controller => 'project', :action => 'tags'
  map.connect 'project/:active_project/tags/:id', :controller => 'tag', :action => 'project'
  
  map.connect '/files/thumbnail/:id.jpg', :controller => 'files', :action => 'thumbnail', :format => 'jpg'
  
  ['search', 'people', 'permissions', 'remove_user', 'remove_company', 'edit', 'delete', 'complete', 'open'].each do |action|
  	map.connect "project/:active_project/#{action}/:id", :controller => 'project', :action => action
  end
  
  ['message', 'task', 'comment', 'milestone', 'time', 'files', 'tags', 'form', 'people'].each do |controller|
  	map.connect "project/:active_project/#{controller}/:action/:id", :controller => controller
  	map.connect "project/:active_project/#{controller}/:action/:id.:format", :controller => controller
  	map.connect "project/:active_project/#{controller}", :controller => controller
  end
  
  map.connect 'project/:active_project/:id', :controller => 'project', :action => 'overview'


  # BaseCamp API
  map.connect 'projects/list', :controller => 'basecamp', :action => 'projects_list'
  map.connect 'projects/:active_project/attachment_categories', :controller => 'basecamp', :action => 'projects_attachment_categories'
  map.connect 'projects/:active_project/post_categories', :controller => 'basecamp', :action => 'projects_post_categories'
  map.connect 'contacts/companies', :controller => 'basecamp', :action => 'contacts_companies'
  
  map.connect 'msg/comment/:id', :controller => 'basecamp', :action => 'msg_comment'
  map.connect 'msg/comments/:id', :controller => 'basecamp', :action => 'msg_comments'
  map.connect 'msg/create_comment/:id', :controller => 'basecamp', :action => 'msg_create_comment'
  map.connect 'projects/:active_project/msg/create', :controller => 'basecamp', :action => 'projects_msg_create'
  map.connect 'msg/delete_comment/:id', :controller => 'basecamp', :action => 'msg_delete_comment'
  map.connect 'msg/delete/:id', :controller => 'basecamp', :action => 'msg_delete'
  map.connect 'msg/get/:ids', :controller => 'basecamp', :action => 'msg_get'
  map.connect 'projects/:active_project/msg/archive', :controller => 'basecamp', :action => 'projects_msg_archive'
  map.connect 'projects/:active_project/msg/cat/:cat_id/archive', :controller => 'basecamp', :action => 'projects_msg_cat_archive'
  map.connect 'msg/update_comment', :controller => 'basecamp', :action => 'msg_update_comment'
  map.connect 'msg/update/:id', :controller => 'basecamp', :action => 'msg_update'
  
  # Install the default route as the lowest priority.
  #map.connect ':controller/:action/:id.:format'
  #map.connect ':controller/:action/:id'
end
