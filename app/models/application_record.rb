class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def ms_id
    "#{self.class}#{self.id}"
  end

  def tag_list
    if !@new_tags.nil?
      @new_tags
    else
      Tag.where(rel_object_type: self.class.to_s, rel_object_id: self.id)
    end
  end

  def class_name
    self.class.to_s
  end

  def new_tags(val)
    Tag.set_to_object(self, val) unless val.nil?
  end

  def update_tags(val)
    return if val.nil?
    Tag.clear_by_object(self)
    Tag.set_to_object(self, val)
  end

  def tags
    tl = !@new_tags.nil? ? @new_tags : Tag.list_by_object(self)
    tl.join(",")
  end

  def tags_with_spaces
    tl = !@new_tags.nil? ? @new_tags : Tag.list_by_object(self)
    tl.join(" ")
  end

  def tags=(val)
    @new_tags = val.split(",")
  end

  def self.register_meilisearch
    include MeiliSearch::Rails
    us = self
    inst = self.new

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
      
        if !inst.respond_to?(field)
          us.attr_accessor field
        end

        attribute field
      end

      if !inst.respond_to?(:is_private)
        us.define_method(:is_private) { @is_private||false }
        us.define_method(:"is_private=") { |value| @is_private = value }
      end

      attribute :is_private

      filterable_attributes [:class_name, :tag, :project, :created_by, :is_private]

      if !inst.respond_to?(:tag_list)
        us.attr_accessor :tag_list
      end

      attribute :tags do
        tag_list
      end
    end
  end
end
