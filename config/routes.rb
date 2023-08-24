Railscollab::Application.routes.draw do
  # feed url's
  get 'feed/:user/:token/:action.:format',  :controller => 'feed'
  get 'feed/:user/:token/:action.::format', :controller => 'feed'
  
  # The rest of the simple controllers
  get "dashboard/(/:action(/:id))",        :controller => 'dashboard'
  get "dashboard/:action/:id.format", :controller => 'dashboard'
  
  resource :session, :only => [:new, :create, :destroy]
  get 'login', :controller => 'sessions', :action => 'new'
  delete 'logout', :controller => 'sessions', :action => 'destroy'
    
  # project & project object url's
  resources :projects do
    member do
      get :people
      get :search
      post :search
      delete :users
      delete :companies
      put :complete
      put :open
      get :permissions
      put :permissions
    end
    
    resources :tags

    resources :task_lists do
      member do
        get :reorder
        post :reorder
        put :reorder
        delete :reorder
      end

      resources :tasks do
        member do
          put :status
        end
        
        resources :comments
      end
    end
    
    resources :wiki_pages do
      collection do
        put :preview
        get :list
      end
    end
    get 'wiki_pages/:id/:version', :controller => 'wiki_pages', :action => 'show', as:  :version_wiki_page

    resources :comments
    # Note: filter by category is done via "posts" on the category controller
    resources :messages do
      member do
        put :unsubscribe
        put :subscribe
      end
      
      resources :comments
    end
  
    resources :categories do
      member do
        get :posts
      end
    end
    
    resources :folders do
      member do
        get :files
      end
    end
    
    resources :files do
      member do 
        get :download
        get :attach
        put :attach
        put :detatch
      end
      resources :comments
    end
  
    resources :milestones do
      member do 
        put :open
        put :complete
      end
    end
    
    resources :times do
      member do
        put :stop
      end
      collection do
        put :by_task
      end
    end
  end
 
  resource :password, :only => [:new, :create]
  resources :users do
    member do
      get :avatar
      put :avatar
      delete :avatar
      get :permissions
      put :permissions
    end
    
    collection do
      get :current
    end
    
    resource :password, :only => [:edit, :update]
  end

  resources :companies do
    member do 
      get :logo
      put :logo
      delete :logo
      put :hide_welcome_info
      get :permissions
      put :permissions
    end
  end

  get 'administration', :controller => 'administration', :action => 'index', as:  :administration

  root :to => 'dashboard#index'
end
