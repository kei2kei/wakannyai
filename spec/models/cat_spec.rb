# spec/models/cat_spec.rb

require 'rails_helper'

RSpec.describe Cat, type: :model do
  describe 'Userのpoints上昇からのCatのupdate_levelに関して' do
    let(:user) { create(:user, points: initial_points) }
    let(:cat) { create(:cat, user: user, level: initial_level) }

    context 'ユーザーのポイントが49で猫がレベル1のとき' do
      let(:initial_points) { 49 }
      let(:initial_level) { 1 }

      it 'ポイント数がレベル2基準に到達した時のレベル更新処理' do
        user.update(points: 50)
        cat.update_level
        expect(cat.reload.level).to eq(2)
      end
    end

    context 'ユーザーのポイントが49で猫がレベル1のとき' do
      let(:initial_points) { 49 }
      let(:initial_level) { 1 }

      it 'ポイント数がレベル2基準手前でのレベル更新処理' do
        user.update(points: 49)
        cat.update_level
        expect(cat.reload.level).to eq(1)
      end
    end

    context 'ユーザーのポイントが100で猫がレベル2のとき' do
      let(:initial_points) { 100 }
      let(:initial_level) { 2 }

      it 'ユーザーのポイントが減少し、レベルを更新する（レベルは変わらない）' do
        user.update(points: 99)
        cat.update_level
        expect(cat.reload.level).to eq(2)
      end
    end
  end
end
