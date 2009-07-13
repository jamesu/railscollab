module WikiEngine::Controller
  def self.included(base)
    base.class_eval do
      before_filter :find_wiki_page, :only => [:show, :edit, :update, :destroy]
      before_filter :find_main_wiki_page, :only => :index
      before_filter :find_wiki_pages, :only => :list

      rescue_from ActiveRecord::RecordNotFound, :with => :not_found
    end
  end

  def index
    unless @wiki_page.nil?
      @versions = @wiki_page.versions.all
      render :action => 'show'
    end
  end

  def list
  end

  def new
    @wiki_page = wiki_pages.new(:title_from_id => params[:id])
  end

  def show
    @versions = @wiki_page.versions.all.reverse!
    @version = @wiki_page.versions.find(params[:version]) if params[:version]
    @version ||= @wiki_page
  end

  def create
    @wiki_page = wiki_pages.new(params[:wiki_page])

    if @wiki_page.save
      flash[:notice] = 'New wiki page has been created.'
      redirect_to wiki_pages_path
    else
      render :action => 'new'
    end
  end

  def edit
  end

  def update
    if @wiki_page.update_attributes(params[:wiki_page])
      flash[:notice] = 'The wiki page has been updated.'
      redirect_to wiki_page_path(:id => @wiki_page)
    else
      render :action => 'edit'
    end
  end

  def destroy
    @wiki_page.destroy

    flash[:notice] = 'The wiki page has been deleted.'
    redirect_to wiki_pages_path
  end

  def preview
    @wiki_page = wiki_pages.new(params[:wiki_page])
    @wiki_page.readonly!

    respond_to do |format|
      format.js { render @wiki_page }
    end
  end

  protected

  # Override this to provide own collection of wiki pages. This by default equals to
  # +WikiPage+ (therefore - all wiki pages).
  #
  # == Example
  #
  #   def wiki_pages
  #     current_user.wiki_pages
  #   end
  def wiki_pages
    WikiPage
  end

  # Override this if you need custom find logic for single wiki page.
  #
  # == Example
  #
  #   # Restrict wiki pages to some named scope
  #   # (+visible+ is hypotetical named_scope defined on WikiPage model).
  #   def find_wiki_page
  #     @wiki_page = wiki_pages.visible.find(params[:id])
  #   end
  #
  # or
  #
  #   # Use different param name.
  #   def find_wiki_page
  #     @wiki_page = wiki_pages.find(params[:wiki_page_id])
  #   end
  #
  def find_wiki_page
    @wiki_page = wiki_pages.find(params[:id])
  end

  # Find main wiki page. This is by default used only for index action.
  def find_main_wiki_page
    @wiki_page = wiki_pages.first(:conditions => {:main => true})
  end

  # Find all wiki pages. This is by default used only for list action.
  def find_wiki_pages
    @wiki_pages = wiki_pages.all
  end

  # This is called when wiki page is not found. By default it display a page explaining
  # that the wiki page does not exist yet and link to create it.
  def not_found
    render :action => 'not_found', :status => :not_found
  end
end
