class WikiPage < ApplicationRecord
  extend FriendlyId
  include Rails.application.routes.url_helpers

  before_save :set_main_page
  friendly_id :title, use: :slugged
  validates_presence_of :title
  validates_length_of :title, minimum: 4

  belongs_to :created_by, class_name: "User", foreign_key: "created_by_id"
  belongs_to :project
  scope :main, lambda { |project| where(main: true, current_revision: true, project_id: project.id) }

  after_create :process_create
  before_destroy :process_destroy

  def process_create
    Activity.new_log(self, created_by, self.revision_number == 0 ? :add : :edit)
  end

  def process_destroy
    if self.revision_number == 0
      Activity.new_log(self, created_by, :delete)
    end
  end

  def user
    created_by
  end

  def user_name
    user.display_name if user
  end

  def title_from_slug=(slug)
    self.title = slug.to_s.underscore.humanize if slug
  end

  def object_name
    title
  end

  def versions
    self.class.where(:slug => self.slug).order(revision_number: :desc)
  end

  def new_version(params)
    last_version = self.versions.last
    new_version = self.project.wiki_pages.build(last_version.attributes.except('id'))
    new_version.attributes = params.except('id')
    new_version.revision_number = last_version.revision_number + 1
    new_version.current_revision = true

    if new_version.save
      self.versions.update_all(current_revision: false)
    end

    new_version
  end

  def object_url(host = nil)
    if self.current_revision
      project_wiki_page_url(project, id: self.friendly_id, only_path: host.nil?, host: host)
    else
      project_wiki_page_url(project, id: self.friendly_id, version: self.revision_number, only_path: host.nil?, host: host)
    end
  end

  # Search
  register_meilisearch

  protected

  def main_page
    @main_page ||= WikiPage.main(project).first
  end

  def set_main_page
    main_page.update_attribute :main, false if main && !main_was && main_page
    true
  end
end
