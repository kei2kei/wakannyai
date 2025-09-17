class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :rememberable, :omniauthable, omniauth_providers: %i[github_app]

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_one :cat, dependent: :destroy
  after_create :assign_random_cat

  def can_sync_to_github?
    github_app_installation_id.present? && github_repo_full_name.present?
  end

  private

  def self.from_github_app_oauth(auth)
    provider = auth.provider
    uid      = auth.uid.to_s
    login    = auth.info.nickname.presence || "user_#{uid}"
    email    = (auth.info.email.presence || "#{uid}@users.noreply.github.com").downcase
    user = find_by(provider: provider, uid: uid) ||
        where("LOWER(email) = ?", email).first ||
        new(email: email)

    user.provider ||= provider
    user.uid      ||= uid
    user.email    ||= email
    user.name       = user.name.presence || auth.info.name.presence || login
    user.github_username        = login
    user.github_app_user_token  = auth.credentials.token

    user.save!
    user
  end

  def assign_random_cat
    colors = ['orange', 'calico', 'white', 'black']
    random_color = colors.sample

    Cat.create(user: self, color: random_color)
  end
end
