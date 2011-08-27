class Ability
  include CanCan::Ability

  def initialize(user)

    # ProjectTask

    can :create_task, ProjectTaskList do |task_list|
      task_list.project.is_active? and user.member_of(task_list.project) and (!(task_list.is_private and !user.member_of_owner?) and can?(:manage, task_list))
    end

    can :edit, ProjectTask do |task|
      task_list = task.task_list
      project = task_list.project
      
      if !user.member_of(project) or !project.is_active? or user.is_anonymous?
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

    can :delete, ProjectTask do |task|
      can? :delete, task.task_list
    end

    can :show, ProjectTask do |task|
      can?(:show, task.task_list) or can?(:edit, task)
    end

    can :complete, ProjectTask do |task|
      can? :edit, task
    end

    can :comment, ProjectTask do |task|
      can? :comment, task.task_list
    end

    # ProjectTaskList

    can :create_task_list, Project do |project|
      project.is_active? and user.has_permission(project, :can_manage_tasks)
    end

    can :manage, ProjectTaskList do |task_list|
      task_list.project.is_active? and user.has_permission(task_list.project, :can_manage_tasks)
    end

    can :edit, ProjectTaskList do |task_list|
      if !task_list.project.is_active? or !user.member_of(task_list.project) or user.is_anonymous?
        false
      elsif user.is_admin
        true
      else
        !(task_list.is_private and !user.member_of_owner?) and user.id == task_list.created_by_id
      end
    end

    can :delete, ProjectTaskList do |task_list|
      task_list.project.is_active? and user.member_of(task_list.project) and user.is_admin
    end

    can :show, ProjectTaskList do |task_list|
      user.member_of(task_list.project) and !(task_list.is_private and !user.member_of_owner?)
    end

    can :comment, ProjectTaskList do |task_list|
      task_list.project.is_active? and task_list.project.has_member(user) and !user.is_anonymous?
    end

    # ProjectTime

    can :create_time, ProjectTime do |project|
      project.is_active? and user.has_permission(project, :can_manage_time)
    end

    can :edit, ProjectTime do |project_time|
      if (!user.member_of(project_time.project))
        false
      else
        (user.is_admin or project_time.created_by_id == user.id) and project_time.project.is_active?
      end
    end

    can :delete, ProjectTime do |project_time|
      project_time.project.is_active? and user.member_of(project_time.project) and user.is_admin
    end

    can :show, ProjectTime do |project_time|
      if !project_time.project.has_member(user)
        false
      elsif user.has_permission(project_time.project, :can_manage_time)
        true
      elsif project_time.is_private and !user.member_of_owner?
        false
      else
        true
      end
    end

    can :manage_time, Project do |project|
      project.is_active? and user.has_permission(project, :can_manage_time)
    end

    can :manage, ProjectTime do |project_time|
      project_time.project.is_active? and user.has_permission(project_time.project, :can_manage_time)
    end

    # ProjectMilestone

    can :create_milestone, Project do |project|
      project.is_active? and user.has_permission(project, :can_manage_milestones)
    end

    can :edit, ProjectMilestone do |milestone|
      if (!milestone.project.is_active? or !user.member_of(milestone.project))
        false
      else
        user.is_admin or milestone.created_by_id == user.id
      end
    end

    can :delete, ProjectMilestone do |milestone|
      milestone.project.is_active? and user.member_of(milestone.project) and user.is_admin
    end

    can :show, ProjectMilestone do |milestone|
      user.member_of(milestone.project) and !(milestone.is_private and !user.member_of_owner?)
    end

    can :manage, ProjectMilestone do |milestone|
      milestone.project.is_active? and user.has_permission(milestone.project, :can_manage_milestones)
    end
    
    can :change_status, ProjectMilestone do |milestone|
      if can?(:edit, milestone)
        true
      else
        milestone_assigned_to = milestone.assigned_to
        (milestone_assigned_to == user) or (milestone_assigned_to == user.company)
      end
    end
    
    can :comment, ProjectMilestone do |milestone|
      milestone.project.is_active? and milestone.project.has_member(user) and !user.is_anonymous?
    end

    # ProjectMessageCategory

    can :create_message_category, Project do |project|
      project.is_active? and user.has_permission(project, :can_manage_messages)
    end

    can :edit, ProjectMessageCategory do |category|
      category.project.is_active? and user.has_permission(category.project, :can_manage_messages)
    end

    can :delete, ProjectMessageCategory do |category|
      category.project.is_active? and user.has_permission(category.project, :can_manage_messages)
    end

    can :show, ProjectMessageCategory do |category|
      category.project.has_member(user)
    end

    can :manage, ProjectMessageCategory do |category|
      category.project.is_active? and user.has_permission(category.project, :can_manage_messages)
    end

    # ProjectMessage

    can :create_message, Project do |project|
      project.is_active? and user.has_permission(project, :can_manage_messages)
    end

    can :edit, ProjectMessage do |message|
      if !message.project.is_active? or !user.member_of(message.project)
        false
      elsif user.is_admin
        true
      else
        !(message.is_private and !user.member_of_owner?) and user.id == message.created_by_id
      end
    end

    can :delete, ProjectMessage do |message|
      user.is_admin and message.project.is_active? and user.member_of(message.project)
    end

    can :show, ProjectMessage do |message|
      if !user.member_of(message.project)
        false
      else
        !(message.is_private and !user.member_of_owner?)
      end
    end
    
    can :subscribe, ProjectMessage do |message|
      message.comments_enabled and message.project.is_active? and user.member_of(message.project) and !(message.is_private and !user.member_of_owner?)
    end

    can :manage, ProjectMessage do |message|
      message.project.is_active? and user.has_permission(message.project, :can_manage_messages)
    end

    can :add_file, ProjectMessage do |message|
      can?(:edit, message) and user.has_permission(message.project, :can_upload_files)
    end
    
    can :change_options, ProjectMessage do |message|
      user.member_of_owner? and can?(:edit, message)
    end
    
    can :comment, ProjectMessage do |message|
      project = message.project
      if user.is_anonymous?
        message.anonymous_comments_enabled and project.is_active? and user.member_of(project) and !message.is_private
      else
        message.comments_enabled and project.is_active? and user.member_of(project) and !(message.is_private and !user.member_of_owner?)
      end
    end

    # ProjectFolder

    can :create_folder, Project do |project|
      folder.project.is_active? and user.has_permission(folder.project, :can_manage_files)
    end

    can :edit, ProjectFolder do |folder|
      folder.project.is_active? and user.has_permission(folder.project, :can_manage_files)
    end

    can :delete, ProjectFolder do |folder|
      folder.project.is_active? and user.has_permission(folder.project, :can_manage_files)
    end

    can :show, ProjectFolder do |folder|
      folder.project.has_member(user)
    end

    can :manage, ProjectFolder do |folder|
      folder.project.is_active? and user.has_permission(folder.project, :can_manage_files)
    end

    # ProjectFile

    can :create_file, Project do |project|
      project.is_active? and user.has_permission(project, :can_upload_files)
    end

    can :edit, ProjectFile do |project_file|
      if (!project_file.project.is_active? or !(user.member_of(project_file.project) and user.has_permission(project_file.project, :can_manage_files)))
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
      project_file.project.is_active? and user.has_permission(project_file.project, :can_manage_files)
    end

    can :download, ProjectFile do |project_file|
      can? :show, project_file
    end
    
    can :change_options, ProjectFile do |project_file|
      user.member_of_owner? and can?(:edit, project_file)
    end
    
    can :comment, ProjectFile do |project_file|
      project = project_file.project
      if user.is_anonymous?
        project_file.anonymous_comments_enabled and project.is_active? and user.member_of(project) and !project_file.is_private
      else
        project_file.comments_enabled and project.is_active? and user.member_of(project) and !(project_file.is_private and !user.member_of_owner?)
      end
    end

    # Project

    can :create_project, User do
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
      if company.is_owner?
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
        elsif comment.created_by == user and !user.is_anonymous?
          now = Time.now.utc
          (now <= (comment.created_on + (60 * Rails.configuration.minutes_to_comment_edit_expire)))
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
      can?(:edit, comment) and (comment.new_record? and user.has_permission(comment.rel_object.project, :can_upload_files))
    end

    # Company

    can :create_company, User do
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
      !company.is_owner? and user.is_admin and user.member_of_owner?
    end

    can :manage, Company do |company|
      user.is_admin and !company.is_owner?
    end

    # User

    can :create_user, User do
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
    
    can :update_profile do |target_user|
      (target_user.id == user.id and !user.is_anonymous?) or (user.member_of_owner? and user.is_admin)
    end

    can :update_permissions do |target_user|
      if target_user.owner_of_owner?
        false
      else
        user.member_of_owner? and user.is_admin
      end
    end
    
    # WikiPage
    
    can :create_wiki_page, Project do |project|
      project.is_active? and user.member_of(project) and user.has_permission(project, :can_manage_wiki_pages)
    end

    can :edit, WikiPage do |page|
      page.project.is_active? and user.member_of(page.project) and user.has_permission(page.project, :can_manage_wiki_pages)
    end

    can :delete, WikiPage do |page|
      user.is_admin and page.project.is_active? and user.member_of(page.project)
    end

  end

end