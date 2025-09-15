class RemoveGithubTokenFromUsers < ActiveRecord::Migration[7.1]
  def up
    execute "UPDATE users SET github_token = NULL" rescue nil
    remove_column :users, :github_token, :string
  end

  def down
    add_column :users, :github_token, :string
  end
end
