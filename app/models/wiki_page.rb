class WikiPage < ActiveRecord::Base
  include WikiEngine::Model
  belongs_to :project
  acts_as_ferret :fields => [:title, :content, :project_id], :store_class_name => true
  self.friendly_id_options[:scope] = :project
  self.non_versioned_columns << :project_id
  named_scope :main, lambda{ |project| {:conditions => {:main => true, :project_id => project.id}} }

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
