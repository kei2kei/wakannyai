class AddSorceryColumnsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :crypted_password, :string
    add_column :users, :salt, :string
  end
end
