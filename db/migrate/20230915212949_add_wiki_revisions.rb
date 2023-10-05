class AddWikiRevisions < ActiveRecord::Migration[7.0]
  def change
    add_column :wiki_pages, :current_revision, :boolean, default: false
    add_column :wiki_pages, :revision_number, :integer, default: 0

    add_index :wiki_pages, :revision_number
    add_index :wiki_pages, :current_revision
  end
end
