class Post < ApplicationRecord
  validates :title, presence: true, length: { maximum: 255 }
  validates :content, presence: true, length: { maximum: 65_535 }
  enum status: { unsolved: 0, solved: 1 }

  belongs_to :user
  has_many :post_tags, dependent: :destroy
  has_many :tags, through: :post_tags
  has_many :comments, dependent: :destroy
  has_many_attached :images, dependent: :purge_later

  attr_accessor :tag_names
  after_save :apply_tag_names
  paginates_per 10

  # Ransackで検索可能にするフィールド
  def self.ransackable_attributes(auth_object = nil)
    ["title", "content"]
  end

  # Ransackで検索可能にするアソシエーション
  def self.ransackable_associations(auth_object = nil)
    ["user", "tags"]
  end

  def has_best_comment?
    comments.exists?(is_best_answer: true)
  end

  def tag_names
    @tag_names.presence || tags.pluck(:name).join(', ')
  end

  private

  def apply_tag_names
    return if tag_names.nil?

    names =
      tag_names.to_s.tr('、', ',')
                .split(',')
                .map { _1.strip }
                .reject(&:blank?)
                .uniq

    self.tags = names.map { |n| Tag.find_or_create_by!(name: n) }
  end
end

