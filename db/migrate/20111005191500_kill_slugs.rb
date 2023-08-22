class PageFix < ActiveRecord::Base
  set_table_name 'wiki_pages'
end

class SlugFix < ActiveRecord::Base
  set_table_name 'slugs'
end

class KillSlugs < ActiveRecord::Migration[4.2]
  def up
    add_column :wiki_pages, :slug, :string
    add_index :wiki_pages, :slug
    PageFix.all.each do |page|
      page.slug = SlugFix.where(:sluggable_type => 'WikiPage', :sluggable_id => page.id).first.try(:name)
    end
  end

  def down
    remove_column :wiki_pages, :slug
  end
end
