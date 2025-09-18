class Comment < ApplicationRecord
  validates :content, presence: true, length: { maximum: 65_535 }
  validate :only_one_best_answer_per_post, if: :is_best_answer?
  belongs_to :post
  belongs_to :user
  belongs_to :parent_comment, class_name: 'Comment', foreign_key: :parent_id, optional: true
  has_many :replies, class_name: 'Comment', foreign_key: :parent_id, dependent: :destroy
  scope :best_answer, -> { find_by(is_best_answer: true) }
  after_commit :award_comment_point, on: :create

  private

  def award_comment_point
    return if post.user_id == user_id
    user.with_lock do
      has_earlier =
        Comment.where(user_id: user_id, post_id: post_id)
              .where('id < ?', id)
              .exists?

      unless has_earlier
        user.increment!(:points, 1)
        user.cat&.update_level
      end
    end
  rescue => e
    Rails.logger.error("[Points] failed to award on comment_id=#{id}: #{e.class} #{e.message}")
  end

  def only_one_best_answer_per_post
    if Comment.where(post_id: post_id, is_best_answer: true).where.not(id: id).exists?
      errors.add(:is_best_answer, 'は1件までです')
    end
  end
end
