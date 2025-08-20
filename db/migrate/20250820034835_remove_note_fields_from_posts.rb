class RemoveNoteFieldsFromPosts < ActiveRecord::Migration[7.1]
  def change
    remove_column :posts, :note_url, :string
    remove_column :posts, :is_note_article, :boolean
    remove_column :posts, :note_thumbnail_url, :string
  end
end
