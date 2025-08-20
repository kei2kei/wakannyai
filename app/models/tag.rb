class Tag < ApplicationRecord
  validates :name, presence: true, length: { minimum: 1, maximum: 50 }, uniqueness: { case_sensitive: false }
  has_many :post_tags, dependent: :destroy
  has_many :posts, through: :post_tags

  # Ransackで検索可能にするフィールド
  def self.ransackable_attributes(auth_object = nil)
    ["name"]
  end
end
