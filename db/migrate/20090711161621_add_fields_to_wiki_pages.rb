class AddFieldsToWikiPages < ActiveRecord::Migration[4.2]
  def self.up
    change_table :wiki_pages do |t|
      t.references :project, :created_by
      t.index :project_id
    end
    #change_table :wiki_page_versions do |t|
    #  t.references :project, :created_by
    #end
  end

  def self.down
    #change_table :wiki_page_versions do |t|
    #  t.remove_references :project, :created_by
    #end
    change_table :wiki_pages do |t|
      t.remove_references :project, :created_by
    end
  end
end
