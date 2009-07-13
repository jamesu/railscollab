class WikiPage < ActiveRecord::Base
  include WikiEngine::Model
  belongs_to :project
  acts_as_ferret :fields => [:title, :content, :project_id], :store_class_name => true
  self.friendly_id_options[:scope] = :project
  self.non_versioned_columns << :project_id
end
