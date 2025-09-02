class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :rememberable, :omniauthable, omniauth_providers: %i[github]

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy

  def github_client
    @github_client ||= Octokit::Client.new(access_token: github_token) if github_token.present?
  end

  def can_sync_to_github?
    github_token.present? && github_username.present?
  end

  private

  def self.from_omniauth(auth)
    find_or_create_by(provider: auth.provider, uid: auth.uid) do |user|
      user.email = auth.info.email
      user.name = auth.info.name
      user.github_token = auth.credentials.token
      user.github_username = auth.info.nickname
    end.tap do |user|
      # 既存ユーザーのトークンを更新
      if user.persisted? && !user.new_record?
        user.update!(
          github_token: auth.credentials.token,
          github_username: auth.info.nickname
        )
      end
    end
  end
end
