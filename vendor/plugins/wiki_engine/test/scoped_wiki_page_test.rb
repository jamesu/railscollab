require 'test_helper'

class ScopedWikiPageTest < ActiveSupport::TestCase
  test 'allows same id for pages in different scopes' do
    site_one = Site.create!(:name => 'dogs')
    site_two = Site.create!(:name => 'cats')

    wiki_page_one = site_one.site_wiki_pages.create!(:title => 'Hello world')
    wiki_page_two = site_two.site_wiki_pages.create!(:title => 'Hello world')

    assert_equal wiki_page_one.to_param, wiki_page_two.to_param
  end
end
