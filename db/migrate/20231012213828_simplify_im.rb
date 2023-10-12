class SimplifyIm < ActiveRecord::Migration[7.1]
  def change
    drop_table :user_im_values
    drop_table :im_types
  end
end
