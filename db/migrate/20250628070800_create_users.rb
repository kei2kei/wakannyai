class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :name
      t.string :email
      t.string :crypted_password

      t.timestamps
    end
    add_index :users, :email, unique: true
  end
end
