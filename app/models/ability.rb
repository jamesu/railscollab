#==
# RailsCollab
# Copyright (C) 2011 James S Urquhart
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++

class Ability
  class AccessDenied < Exception
  end

  def can(ability, klass, &block)
    @abilityCheckers ||= {}
    @abilityCheckers["#{ability}_#{klass}"] = block
  end

  def can?(ability, instance = nil)
    key = "#{ability}_#{instance.class}"
    if @abilityCheckers.has_key?(key)
      func = @abilityCheckers[key]
      return func.call(instance)
    else
      return false
    end
  end

  def init(user)

    # Task

    can :create_task, TaskList do |task_list|
      task_list.project.is_active? and user.member_of(task_list.project) and (!(task_list.is_private and !user.member_of_owner?) and can?(:manage, task_list))
    end

    can :edit, Task do |task|
      task_list = task.task_list
      project = task_list.project

      if !user.member_of(project) or !project.is_active?
        false
      elsif user.is_admin
        true
      elsif (task.assigned_to == user) or (task.assigned_to == user.company) or task.assigned_to.nil?
        true
      elsif task.created_by_id == user.id and (task.created_on + 3.minutes) < Time.now.utc # Owner editable for 3 mins
        true
      else
        can? :edit, task_list
      end
    end

    can :delete, Task do |task|
      can? :delete, task.task_list
    end

    can :show, Task do |task|
      can?(:show, task.task_list) or can?(:edit, task)
    end

    can :complete, Task do |task|
      can? :edit, task
    end

    can :comment, Task do |task|
      can? :comment, task.task_list
    end

    # TaskList

    can :create_task_list, Project do |project|
      project.is_active? and user.permissions_for(project).has_permission(:can_manage_tasks)
    end

    can :manage, TaskList do |task_list|
      task_list.project.is_active? and user.permissions_for(task_list.project).has_permission(:can_manage_tasks)
    end

    can :edit, TaskList do |task_list|
      if !task_list.project.is_active? or !user.member_of(task_list.project)
        false
      elsif user.is_admin
        true
      else
        !(task_list.is_private and !user.member_of_owner?) and user.id == task_list.created_by_id
      end
    end

    can :delete, TaskList do |task_list|
      task_list.project.is_active? and user.member_of(task_list.project) and user.is_admin
    end

    can :show, TaskList do |task_list|
      user.member_of(task_list.project) and !(task_list.is_private and !user.member_of_owner?)
    end

    can :comment, TaskList do |task_list|
      task_list.project.is_active? and task_list.project.has_member(user)
    end

    # TimeRecord

    can :create_time, TimeRecord do |project|
      project.is_active? and user.permissions_for(project).has_permission(:can_manage_time)
    end

    can :edit, TimeRecord do |project_time|
      if (!user.member_of(project_time.project))
        false
      else
        (user.is_admin or project_time.created_by_id == user.id) and project_time.project.is_active?
      end
    end

    can :delete, TimeRecord do |project_time|
      project_time.project.is_active? and user.member_of(project_time.project) and user.is_admin
    end

    can :show, TimeRecord do |project_time|
      if !project_time.project.has_member(user)
        false
      elsif user.permissions_for(project_time.project).has_permission(:can_manage_time)
        true
      elsif project_time.is_private and !user.member_of_owner?
        false
      else
        true
      end
    end

    can :manage_time, Project do |project|
      project.is_active? and user.permissions_for(project).has_permission(:can_manage_time)
    end

    can :manage, TimeRecord do |project_time|
      project_time.project.is_active? and user.permissions_for(project_time.project).has_permission(:can_manage_time)
    end

    # Milestone

    can :create_milestone, Project do |project|
      project.is_active? and user.permissions_for(project).has_permission(:can_manage_milestones)
    end

    can :edit, Milestone do |milestone|
      if (!milestone.project.is_active? or !user.member_of(milestone.project))
        false
      else
        user.is_admin or milestone.created_by_id == user.id
      end
    end

    can :delete, Milestone do |milestone|
      milestone.project.is_active? and user.member_of(milestone.project) and user.is_admin
    end

    can :show, Milestone do |milestone|
      user.member_of(milestone.project) and !(milestone.is_private and !user.member_of_owner?)
    end

    can :manage, Milestone do |milestone|
      milestone.project.is_active? and user.permissions_for(milestone.project).has_permission(:can_manage_milestones)
    end

    can :change_status, Milestone do |milestone|
      if can?(:edit, milestone)
        true
      else
        milestone_assigned_to = milestone.assigned_to
        (milestone_assigned_to == user) or (milestone_assigned_to == user.company)
      end
    end

    can :comment, Milestone do |milestone|
      milestone.project.is_active? and milestone.project.has_member(user)
    end

    # Category

    can :create_message_category, Project do |project|
      project.is_active? and user.permissions_for(project).has_permission(:can_manage_messages)
    end

    can :edit, Category do |category|
      category.project.is_active? and user.permissions_for(category.project).has_permission(:can_manage_messages)
    end

    can :delete, Category do |category|
      category.project.is_active? and user.permissions_for(category.project).has_permission(:can_manage_messages)
    end

    can :show, Category do |category|
      category.project.has_member(user)
    end

    can :manage, Category do |category|
      category.project.is_active? and user.permissions_for(category.project).has_permission(:can_manage_messages)
    end

    # Message

    can :create_message, Project do |project|
      project.is_active? and user.permissions_for(project).has_permission(:can_manage_messages)
    end

    can :edit, Message do |message|
      if !message.project.is_active? or !user.member_of(message.project)
        false
      elsif user.is_admin
        true
      else
        !(message.is_private and !user.member_of_owner?) and user.id == message.created_by_id
      end
    end

    can :delete, Message do |message|
      user.is_admin and message.project.is_active? and user.member_of(message.project)
    end

    can :show, Message do |message|
      if !user.member_of(message.project)
        false
      else
        !(message.is_private and !user.member_of_owner?)
      end
    end

    can :subscribe, Message do |message|
      message.comments_enabled and message.project.is_active? and user.member_of(message.project) and !(message.is_private and !user.member_of_owner?)
    end

    can :manage, Message do |message|
      message.project.is_active? and user.permissions_for(message.project).has_permission(:can_manage_messages)
    end

    can :add_file, Message do |message|
      can?(:edit, message) and user.permissions_for(message.project).has_permission(:can_upload_files)
    end

    can :change_options, Message do |message|
      user.member_of_owner? and can?(:edit, message)
    end

    can :comment, Message do |message|
      project = message.project
      message.comments_enabled and project.is_active? and user.member_of(project) and !(message.is_private and !user.member_of_owner?)
    end

    # Folder

    can :create_folder, Project do |project|
      project.is_active? and user.permissions_for(project).has_permission(:can_manage_files)
    end

    can :edit, Folder do |folder|
      folder.project.is_active? and user.permissions_for(folder.project).has_permission(:can_manage_files)
    end

    can :delete, Folder do |folder|
      folder.project.is_active? and user.permissions_for(folder.project).has_permission(:can_manage_files)
    end

    can :show, Folder do |folder|
      folder.project.has_member(user)
    end

    can :manage, Folder do |folder|
      folder.project.is_active? and user.permissions_for(folder.project).has_permission(:can_manage_files)
    end

    # ProjectFile

    can :create_file, Project do |project|
      project.is_active? and user.permissions_for(project).has_permission(:can_upload_files)
    end

    can :edit, ProjectFile do |project_file|
      if (!project_file.project.is_active? or !(user.member_of(project_file.project) and user.permissions_for(project_file.project).has_permission(:can_manage_files)))
        false
      elsif user.is_admin
        true
      else
        !(project_file.is_private and !user.member_of_owner?) and user.id == project_file.created_by_id
      end
    end

    can :delete, ProjectFile do |project_file|
      user.is_admin and project_file.project.is_active? and user.member_of(project_file.project)
    end

    can :show, ProjectFile do |project_file|
      if !user.member_of(project_file.project)
        false
      else
        !(project_file.is_private and !user.member_of_owner?)
      end
    end

    can :manage, ProjectFile do |project_file|
      project_file.project.is_active? and user.permissions_for(project_file.project).has_permission(:can_manage_files)
    end

    can :download, ProjectFile do |project_file|
      can? :show, project_file
    end

    can :change_options, ProjectFile do |project_file|
      user.member_of_owner? and can?(:edit, project_file)
    end

    can :comment, ProjectFile do |project_file|
      project = project_file.project
        project_file.comments_enabled and project.is_active? and user.member_of(project) and !(project_file.is_private and !user.member_of_owner?)
    end

    # Project

    can :create_project, User do |in_user|
      user.member_of_owner? and user.is_admin
    end

    can :edit, Project do |project|
      user.member_of_owner? and user.is_admin
    end

    can :delete, Project do |project|
      user.member_of_owner? and user.is_admin
    end

    can :show, Project do |project|
      project.has_member(user) or (user.member_of_owner? and user.is_admin)
    end

    can :manage, Project do |project|
      user.member_of_owner? and user.is_admin
    end

    can :remove_company, Project do |project, company|
      if company.is_instance_owner?
        false
      else
        user.member_of_owner? and user.is_admin
      end
    end

    can :remove_user, Project do |project, target_user|
      if target_user.owner_of_owner?
        false
      else
        user.member_of_owner? and user.is_admin
      end
    end

    can :change_status, Project do |project|
      can? :edit, project
    end

    # Comment

    can :edit, Comment do |comment|
      comment_project = comment.rel_object.project

      if comment_project.is_active? and comment_project.has_member(user)
        if (user.member_of_owner? and user.is_admin)
          true
        elsif comment.created_by == user
          now = Time.now.utc
          (now <= (comment.created_on + (60 * Rails.configuration.railscollab.minutes_to_comment_edit_expire)))
        end
      end

      false
    end

    can :delete, Comment do |comment|
      can? :delete, comment.rel_object
    end

    can :show, Comment do |comment|
      if (comment.is_private and !user.member_of_owner?)
        false
      else
        can? :show, comment.rel_object
      end
    end

    can :add_file, Comment do |comment|
      can?(:edit, comment) and (comment.new_record? and user.permissions_for(comment.rel_object.project).has_permission(:can_upload_files))
    end

    # Company

    can :create_company, User do |in_user|
      user.is_admin and user.member_of_owner?
    end

    can :edit, Company do |company|
      user.is_admin and (user.company == company or user.member_of_owner?)
    end

    can :delete, Company do |company|
      user.is_admin and user.member_of_owner?
    end

    can :show, Company do |company|
      true
    end

    can :add_client, Company do |company|
      user.is_admin and user.member_of_owner?
    end

    can :remove, Company do |company|
      !company.is_instance_owner? and user.is_admin and user.member_of_owner?
    end

    can :manage, Company do |company|
      if user.member_of_owner? and (user.is_admin or (company.created_by == user))
        true
      else
        user.is_admin and !company.is_instance_owner?
      end
    end

    # User

    can :create_user, User do |in_user|
      user.member_of_owner? and user.is_admin
    end

    can :delete, User do |target_user|
      if target_user.owner_of_owner? or user.id == target_user.id
        false
      else
        user.is_admin
      end
    end

    can :show, User do |target_user|
      user.member_of_owner? or user.company_id == target_user.company_id or target_user.member_of_owner?
    end

    can :update_profile, User do |target_user|
      (target_user.id == user.id) or (user.member_of_owner? and user.is_admin)
    end

    can :update_permissions, User do |target_user|
      if target_user.owner_of_owner?
        false
      else
        user.member_of_owner? and user.is_admin
      end
    end

    # WikiPage

    can :create_wiki_page, Project do |project|
      project.is_active? and user.member_of(project) and user.permissions_for(project).has_permission(:can_manage_wiki_pages)
    end

    can :edit, WikiPage do |page|
      page.project.is_active? and user.member_of(page.project) and user.permissions_for(page.project).has_permission(:can_manage_wiki_pages)
    end

    can :delete, WikiPage do |page|
      user.is_admin and page.project.is_active? and user.member_of(page.project)
    end

    return self
  end
end
