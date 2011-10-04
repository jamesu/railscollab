module WikiPageUser
  def self.included(base)
    base.belongs_to :created_by,   :class_name => 'User', :foreign_key => 'created_by_id'
  end

  def user
    created_by
  end

  def user_name
    user.display_name if user
  end
end