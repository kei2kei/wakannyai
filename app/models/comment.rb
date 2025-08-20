class Comment < ApplicationRecord
  validates :content, presence: true, length: { maximum: 65_535 }
  belongs_to :post
  belongs_to :user
  belongs_to :parent_comment, class_name: 'Comment', optional: true
  has_many :replies, class_name: 'Comment', foreign_key: :parent_comment_id
end
