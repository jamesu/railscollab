class CreateWikiPages < ActiveRecord::Migration[4.2]
  def self.up
    create_table :wiki_pages do |t|
      t.string :title
      t.text :content
      t.boolean :main, :null => false, :default => false

      t.timestamps
    end
    add_index :wiki_pages, :main
    WikiPage.create_versioned_table
  end

  def self.down
    WikiPage.drop_versioned_table
    drop_table :wiki_pages
  end
end
