class AddGithubAppFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :github_installation_id, :bigint
    add_column :users, :github_repo_full_name, :string
    add_column :users, :github_app_user_token, :text
    add_column :users, :github_branch, :string, default: "main"

    add_index :users, [:provider, :uid], unique: true
    add_index :users, :github_installation_id
  end
end
