class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def ms_id
    "#{self.class}#{self.id}"
  end

  def last_edited_by_owner?
    if !self.updated_by.nil?
      self.updated_by.member_of_owner?
    else
      self.created_by.member_of_owner?
    end
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

  def reset_perm_with_uid_list(perm_list, uid_list, existing_people)
    # Reset list with new people
    uid_list.uniq!
    existing_people.destroy_all

    uid_list.each do |uid_proj_code|
      key = uid_proj_code.map(&:to_s).join('_')
      code = perm_list.has_key?(key) ? perm_list[key] : 0

      person = Person.new(
        user_id: uid_proj_code[1], 
        project_id: uid_proj_code[0], 
        code: code)
      
      person.save!
    end
  end

  def make_perm_uid_lists(val, project_filter, user_filter)
    # Make new list
    new_list = {}
    uid_list = []

    if !user_filter.nil? and !user_filter.is_a?(Array)
      user_filter = [user_filter]
    end

    if !project_filter.nil? and !project_filter.is_a?(Array)
      project_filter = [project_filter]
    end

    val.map(&:strip).uniq.each do |perm|
      begin
        v = perm.split('_')

        project_id = v[0].to_i
        user_id = v[1].to_i
        perm_name = v[2..-1].join('_')
        key = [v[0], v[1]].join('_')

        next if (!user_filter.nil? and !user_filter.include?(user_id))
        next if (!project_filter.nil? and !project_filter.include?(project_id))

        if perm_name == 'member'
          uid_list << [project_id, user_id]
        end

        if new_list.has_key?(key)
          new_list[key] |= Person.permission_code(perm_name.to_sym)
        else
          new_list[key] = Person.permission_code(perm_name.to_sym)
        end

      rescue Exception => e
        next
      end
    end

    return [new_list, uid_list]
  end

  # Sets a permission list based on project and user filter
  def set_perm_list(val, project_filter=nil, user_filter=nil)
    return if val.nil?

    # Select correct existing records
    if project_filter.nil? && user_filter.nil?
      raise Exception.new("No filter")
    elsif project_filter.nil?
      existing_people = Person.where(user_id: user_filter)
    elsif user_filter.nil?
      existing_people = Person.where(project_id: project_filter)
    else
      existing_people = Person.where(project_id: project_filter, user_id: user_filter)
    end

    # Make new list
    perm_list, uid_list = make_perm_uid_lists(val, project_filter, user_filter)

    # Reset list with new people
    reset_perm_with_uid_list(perm_list, uid_list, existing_people)
  end

  def self.register_meilisearch(&block)
    return unless Rails.configuration.railscollab.search_enabled
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

    block.call
  end
end
