require 'rubygems'
require 'test/unit'
require 'active_support'
require 'active_support/test_case'
require 'active_record'
require 'action_controller'
require 'action_controller/test_process'
require 'action_view/test_case'

require File.dirname(__FILE__) + '/../init'

# TODO: isn't there a better way to load plugins?

# Load inherit_views plugin
$LOAD_PATH << File.dirname(__FILE__) + '/../../inherit_views/lib'
require File.dirname(__FILE__) + '/../../inherit_views/init'

# Load friendly_id plugin
$LOAD_PATH << File.dirname(__FILE__) + '/../../friendly_id/lib'
require File.dirname(__FILE__) + '/../../friendly_id/init'

# Establish a temporary sqlite3 db for testing.
ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')
ActiveRecord::Base.logger # instantiate logger
ActiveRecord::Schema.define(:version => 1) do
  create_table :wiki_pages do |t|
    t.string :title
    t.text :content
    t.timestamps
  end

  create_table :slugs do |t|
    t.string :name
    t.string :sluggable_type
    t.integer :sluggable_id
    t.integer :sequence, :null => false, :default => 1
  end

  create_table :sites do |t|
    t.string :name
  end

  create_table :site_wiki_pages do |t|
    t.belongs_to :site
    t.string :title
    t.text :content
    t.timestamps
  end
end

# Testing classes
class WikiPage < ActiveRecord::Base
  acts_as_wiki_page
end

class WikiPagesController < ActionController::Base
  acts_as_wiki_pages_controller
end

class Site < ActiveRecord::Base
  has_many :site_wiki_pages
end

class SiteWikiPage < ActiveRecord::Base
  belongs_to :site
  acts_as_wiki_page :scope => :site_id
end

# Routes
ActionController::Routing::Routes.draw do |map|
  map.resources :wiki_pages, :new => {:preview => :post}
end
