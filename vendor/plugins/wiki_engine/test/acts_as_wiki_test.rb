require 'test_helper'

class ActsAsWikiTest < ActiveSupport::TestCase
  test 'plugin is loaded' do
    assert ActiveRecord::Base.respond_to?(:acts_as_wiki_page)
    assert ActionController::Base.respond_to?(:acts_as_wiki_pages_controller)
  end
end
