require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'UserとCatのアソシエーション' do
    it 'ユーザー作成時にCatが自動作成される' do
      user = create(:user)
      expect(user.cat).to be_present
    end
  end

  describe 'GitHub App 連携判定' do
    context 'インストールIDと保存先リポが揃っている' do
      it 'can_sync_to_github? が true' do
        user = create(:user, :with_github_app)
        expect(user.can_sync_to_github?).to eq(true)
      end
    end

    context '不足している時' do
      it 'インストールIDが無ければ false' do
        user = create(:user, github_repo_full_name: 'someone/learning-logs')
        expect(user.can_sync_to_github?).to eq(false)
      end

      it '保存先リポが無ければ false' do
        user = create(:user, github_app_installation_id: 123)
        expect(user.can_sync_to_github?).to eq(false)
      end
    end
  end
end
