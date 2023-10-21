class ProjectOwnerCompany < ActiveRecord::Migration[7.1]
  def up
    add_column :projects, :owner_company_id, :integer, default: 0, limit: 8, null: false
    add_index :projects, :owner_company_id

    owner = Company.where(client_of_id: nil).first
    Project.all do |pr|
      pr.owner_company = owner
      pr.save!
    end
  end

  def down
    remove_column :projects, :owner_company_id
  end
end
