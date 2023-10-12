class SimplifyPerson < ActiveRecord::Migration[7.1]
  def change
    add_column :people, :code, :integer, default: 0, limit: 8, null: false
    remove_column :people, :can_manage_messages
    remove_column :people, :can_manage_tasks
    remove_column :people, :can_manage_milestones
    remove_column :people, :can_upload_files
    remove_column :people, :can_manage_files
    remove_column :people, :can_assign_to_owners
    remove_column :people, :can_assign_to_other
    remove_column :people, :can_manage_time
    remove_column :people, :can_manage_wiki_pages

    Person.update_all(code: 0xFFFFFFFF)
  end
end
