class CreateCats < ActiveRecord::Migration[7.1]
  def change
    create_table :cats do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :level, null: false, default: 1
      t.string :color, null: false

      t.timestamps
    end
  end
end
