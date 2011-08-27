class WikiPage < ActiveRecord::Base
  include Rails.application.routes.url_helpers
  include WikiPageUser
  
  before_save :set_main_page
  acts_as_versioned :extend => WikiPageUser
  has_friendly_id :title, :use_slug => true, :strip_diacritics => true
  validates_presence_of :title

  def title_from_id=(id)
    self.title = id.to_s.underscore.humanize if id
  end
  
  belongs_to :project
  # self.friendly_id_options[:scope] = :project
  self.friendly_id_options[:scope] = :scope_value
  self.non_versioned_columns << :project_id
  scope :main, lambda{ |project| {:conditions => {:main => true, :project_id => project.id}} }

  after_create  :process_create
  before_update :process_update_params
  before_destroy :process_destroy

  def scope_value
    self.project.id.to_s
  end

  def process_create
    ApplicationLog.new_log(self, self.created_by, :add)
  end

  def process_update_params
    ApplicationLog.new_log(self, self.created_by, :edit)
  end

  def process_destroy
    ApplicationLog.new_log(self, self.created_by, :delete)
  end

  def object_name
    self.title
  end

  def object_url(host = nil)
    url_for :only_path => host.nil?, :host => host, :controller => 'wiki_pages', :action => 'show', :id => self, :active_project => self.project_id
  end

  protected
  
  def main_page
    @main_page ||= self.class.main(project).first
  end

  def set_main_page
    self.main_page.update_attribute :main, false if self.main && !self.main_was && self.main_page
  end
end
