class RemoveSorceryColumnFromUsers < ActiveRecord::Migration[7.1]
  def change
    remove_column :users, :crypted_password, :string
    remove_column :users, :salt, :string
    remove_column :users, :email, :string
  end
end
