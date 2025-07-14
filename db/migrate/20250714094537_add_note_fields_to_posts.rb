class AddNoteFieldsToPosts < ActiveRecord::Migration[7.1]
  def change
    add_column :posts, :note_url, :string
    add_column :posts, :is_note_article, :boolean, default: false
  end
end
