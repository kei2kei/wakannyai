class AddGithubFieldsToPosts < ActiveRecord::Migration[7.1]
  def change
    add_column :posts, :github_url, :string
    add_column :posts, :github_sha, :string
    add_column :posts, :github_synced_at, :datetime
    add_column :posts, :auto_sync_github, :boolean
  end
end
