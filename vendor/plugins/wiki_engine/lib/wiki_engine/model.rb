module WikiEngine::Model
  def self.included(base)
    base.class_eval do
      before_save :set_main_page
      has_friendly_id :title, :use_slug => true, :strip_diacritics => true
      acts_as_versioned :extend => WikiEngine::UserSupport
      validates_presence_of :title
      named_scope :main, :conditions => {:main => true}
    end
  end

  def title_from_id=(id)
    self.title = id.to_s.underscore.humanize if id
  end

  protected
  def main_page
    @main_page ||= self.class.main.first
  end

  def set_main_page
    self.main_page.update_attribute :main, false if self.main && !self.main_was && self.main_page
  end
end
