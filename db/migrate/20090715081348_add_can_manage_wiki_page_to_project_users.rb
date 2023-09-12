class AddCanManageWikiPageToProjectUsers < ActiveRecord::Migration[4.2]
  def self.up
    add_column :project_users, :can_manage_wiki_pages, :boolean, null: false, default: false
  end

  def self.down
    remove_column :project_users, :can_manage_wiki_pages
  end
end
