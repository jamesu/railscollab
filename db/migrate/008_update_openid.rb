class UpdateOpenid < ActiveRecord::Migration[4.2]
  def self.up
    create_table :open_id_authentication_associations, :force => true do |t|
      t.integer :issued, :lifetime
      t.string :handle, :assoc_type
      t.binary :server_url, :secret
    end
    
    create_table :open_id_authentication_nonces, :force => true do |t|
      t.integer :timestamp, :null => false
      t.string :server_url, :null => true
      t.string :salt, :null => false
    end
    
    drop_table "open_id_associations"
    drop_table "open_id_settings"
    drop_table "open_id_nonces"
  end

  def self.down
    create_table "open_id_associations", :force => true do |t|
      t.column "server_url", :binary
      t.column "handle", :string
      t.column "secret", :binary
      t.column "issued", :integer
      t.column "lifetime", :integer
      t.column "assoc_type", :string
    end

    create_table "open_id_nonces", :force => true do |t|
      t.column "nonce", :string
      t.column "created", :integer
    end

    create_table "open_id_settings", :force => true do |t|
      t.column "setting", :string
      t.column "value", :binary
    end
    
    drop_table "open_id_authentication_associations"
    drop_table "open_id_authentication_nonces"
  end
end
