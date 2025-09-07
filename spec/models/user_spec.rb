
require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'UserとCatのアソシエーション確認' do
    # 💡 ユーザーが作成されたときに、catも自動で作成されるか？
    it 'ひもづく猫を自動的に作成する' do
      user = create(:user)
      expect(user.cat).to be_present
    end
  end

  describe 'UserのGithub連携' do
    context 'ユーザーがGithubトークンを保持している' do
      let(:user) { create(:user, github_token: 'test_token') }
      it 'Octokitのクライアントが存在する' do
        expect(user.github_client).to be_an_instance_of(Octokit::Client)
      end
    end

    context 'Githubトークンがない' do
      let(:user) { create(:user, github_token: nil) }
      it 'Githubクライアントはない' do
        expect(user.github_client).to be_nil
      end
    end
  end
end