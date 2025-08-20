class DropGitHubContributions < ActiveRecord::Migration[7.1]
  def change
    drop_table :git_hub_contributions
  end
end
