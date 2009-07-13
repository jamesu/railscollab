require 'test_helper'

class WikiPageTest < ActiveSupport::TestCase
  test 'has friendly id' do
    wiki_page = WikiPage.create!(:title => 'Hello world')

    assert_equal 'hello-world', wiki_page.to_param
    assert_equal wiki_page, WikiPage.find('hello-world')
  end

  test 'sets title_from_id' do
    wiki_page = WikiPage.new
    wiki_page.title_from_id = 'hello-world'

    assert_equal 'Hello world', wiki_page.title
    assert_nil wiki_page.id
  end

  test 'does not set title_from_id if id is nil' do
    wiki_page = WikiPage.new
    wiki_page.title_from_id = nil

    assert_nil wiki_page.title
  end

  test 'requires presence of title' do
    wiki_page = WikiPage.new

    assert !wiki_page.valid?
    assert_not_nil wiki_page.errors[:title]
  end
end
