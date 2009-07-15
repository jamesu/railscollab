class AddCanManageWikiPageToProjectUsers < ActiveRecord::Migration
  def self.up
    add_column :project_users, :can_manage_wiki_pages, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :project_users, :can_manage_wiki_pages
  end
end
