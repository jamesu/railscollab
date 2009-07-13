class WikiEngineGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      unless options[:skip_migration]
        m.migration_template(
          'create_wiki_pages.rb', 'db/migrate', :migration_file_name => 'create_wiki_pages'
        )
      end
    end
  end
end