class WikiPage < ApplicationRecord
  extend FriendlyId
  include Rails.application.routes.url_helpers
  include WikiPageUser
  
  before_save :set_main_page
  #acts_as_versioned :extend => WikiPageUser
  friendly_id :title, :use => :slugged
  validates_presence_of :title

  def title_from_id=(id)
    self.title = id.to_s.underscore.humanize if id
  end
  
  belongs_to :project
  #self.non_versioned_columns << :project_id
  #self.non_versioned_columns << :title
  #self.non_versioned_columns << :slug
  scope :main, lambda{ |project| where(:main => true, :project_id => project.id) }

  after_create  :process_create
  before_update :process_update_params
  before_destroy :process_destroy

  def scope_value
    project.id.to_s
  end

  def process_create
    Activity.new_log(self, created_by, :add)
  end

  def process_update_params
    Activity.new_log(self, created_by, :edit)
  end

  def process_destroy
    Activity.new_log(self, created_by, :delete)
  end

  def object_name
    title
  end

  def wiki_page
    self
  end

  def object_url(host = nil)
    project_wiki_page_url(project, id: self.id, only_path: host.nil?, host: host)
  end
  
  # Indexing
  define_index do
    indexes :title
    indexes :content
    
    has :project_id
    has :created_at
    has :updated_at
  end

  protected
  
  def main_page
    @main_page ||= WikiPage.main(project).first
  end

  def set_main_page
    main_page.update_attribute :main, false if main && !main_was && main_page
    true
  end
end
