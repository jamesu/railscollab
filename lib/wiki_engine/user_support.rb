module WikiEngine::UserSupport
  def self.included(base)
    base.belongs_to :created_by,   :class_name => 'User', :foreign_key => 'created_by_id'
  end

  def user
    self.created_by
  end

  def user_name
    user.display_name if self.user
  end
end
