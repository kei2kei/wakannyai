class CreateGitHubContributions < ActiveRecord::Migration[7.1]
  def change
    create_table :git_hub_contributions do |t|
      t.date :date, null: false
      t.string :color, null: false
      t.integer :contribution_count, default: 0
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    add_index :git_hub_contributions, [:user_id, :date], unique: true
  end
end
