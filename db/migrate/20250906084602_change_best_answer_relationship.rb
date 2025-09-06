class ChangeBestAnswerRelationship < ActiveRecord::Migration[7.1]
  def change
    remove_reference :posts, :best_comment, foreign_key: { to_table: :comments }
    add_column :comments, :is_best_answer, :boolean, default: false, null: false
  end
end
