class AddBestAnswerIdToPosts < ActiveRecord::Migration[7.1]
  def change
    add_reference :posts, :best_comment, foreign_key: { to_table: :comments}
  end
end
