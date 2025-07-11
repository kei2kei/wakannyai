class Post < ApplicationRecord
  validates :title, presence: true, length: { maximum: 255 }
  validates :content, presence: true, length: { maximum: 65_535 }

  def self.ransackable_attributes(auth_object = nil)
    ["title", "content"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["user"]
  end

  belongs_to :user
end
