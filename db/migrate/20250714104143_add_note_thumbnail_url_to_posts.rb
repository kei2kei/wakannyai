class AddNoteThumbnailUrlToPosts < ActiveRecord::Migration[7.1]
  def change
    add_column :posts, :note_thumbnail_url, :string
  end
end
