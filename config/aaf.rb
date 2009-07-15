ActsAsFerret::define_index('shared',
  :models => {
    Comment => {:fields => [:text, :project_id, :is_private]},
    ProjectMessage => {:fields => [:title, :text, :additional_text, :project_id, :is_private, :tags_with_spaces]},
    ProjectTime => {:fields => [:name, :description, :project_id, :is_private, :tags_with_spaces]},
    ProjectTask => {:fields => [:text, :project_id, :is_private]},
    ProjectTaskList => {:fields => [:name, :description, :project_id, :is_private, :tags_with_spaces]},
    ProjectMilestone => {:fields => [:name, :description, :project_id, :is_private, :tags_with_spaces]},
    ProjectFile => {:fields => [:filename, :description, :project_id, :is_private, :tags_with_spaces]},
    ProjectFileRevision => {:fields => [:comment, :project_id, :is_private]},
    WikiPage => {:fields => [:title, :content, :project_id]}
  },
  :ferret => {
    :default_fields => [:title, :text, :additional_text, :project_id, :is_private, :tags_with_spaces, :description, :filename, :comment, :content]
  }
)
