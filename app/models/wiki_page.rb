class WikiPage < ActiveRecord::Base
  include ActionController::UrlWriter
  include WikiEngine::Model
  belongs_to :project
  self.friendly_id_options[:scope] = :project
  self.non_versioned_columns << :project_id
  named_scope :main, lambda{ |project| {:conditions => {:main => true, :project_id => project.id}} }

  def object_name
    self.title
  end

  def object_url
    url_for :only_path => true, :controller => 'wiki_pages', :action => 'show', :id => self, :active_project => self.project_id
  end

  def self.can_be_created_by(user, project)
    project.is_active? and user.member_of(project) and user.has_permission(project, :can_manage_wiki_pages)
  end

  def can_be_edited_by(user)
    return false if (!project.is_active? or !(user.member_of(project) and user.has_permission(project, :can_manage_wiki_pages)))

    true
  end

  def can_be_deleted_by(user)
    user.is_admin and project.is_active? and user.member_of(project)
  end

  protected
  def main_page
    @main_page ||= self.class.main(project).first
  end
end
