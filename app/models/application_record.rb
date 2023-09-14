class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.define_index(&block)
    # TODO
  end

  def ms_id
    "#{self.class}#{self.id}"
  end

  def tag_list
    Tag.where(rel_object_type: self.class.to_s, rel_object_id: self.id)
  end

  def class_name
    self.class.to_s
  end

  def self.register_meilisearch
    include MeiliSearch::Rails
    us = self

    # Search
    meilisearch index_uid: 'GlobalProject', primary_key: :ms_id do

      [:id,
       :class_name,
       :text,
       :rel_object, 
       :created_by, 
       :filename, 
       :description, 
       :project, 
       :folder, 
       :created_by, 
       :milestone, 
       :comment, 
       :type_string, 
       :data_file_name, 
       :data_content_type, 
       :content,
       :title].each do |field|
      
        if !us.method_defined?(field)
          us.attr_accessor field
        end

        attribute field
      end

      if !us.method_defined?(:is_private)
        us.define_method(:is_private) { @is_private||false }
        us.define_method(:"is_private=") { |value| @is_private = value }
      end

      attribute :is_private

      filterable_attributes [:class_name, :tag, :project, :created_by, :is_private]

      if !us.method_defined?(:tag_list)
        us.attr_accessor :tag_list
      end

      attribute :tags do
        tag_list
      end
    end
  end
end
