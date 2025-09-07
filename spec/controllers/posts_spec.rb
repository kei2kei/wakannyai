
require 'rails_helper'

RSpec.describe PostsController, type: :controller do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe 'POST #create' do
    let(:post_params) { { title: '新しい投稿', content: 'テストコンテンツ' } }

    context 'ログイン済みのユーザーの場合' do
      before { sign_in user }
      it '投稿が成功すると、ポイントが加算されてルートパスにリダイレクトされる' do
        expect { post :create, params: { post: post_params } }.to change(Post, :count).by(1)
        expect(user.reload.points).to eq(1) # 1ポイント加算を確認
        expect(response).to redirect_to(root_path)
      end
    end

    context '未ログインのユーザーの場合' do
      it 'ログインページにリダイレクトされる' do
        post :create, params: { post: post_params }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  # 🔥 destroyアクションのテスト
  describe 'DELETE #destroy' do
    let!(:post_to_destroy) { create(:post, user: user) }

    context '投稿者本人がログインしている場合' do
      before { sign_in user }

      it '投稿を削除し、ルートパスにリダイレクトされる' do
        expect { delete :destroy, params: { id: post_to_destroy.id } }.to change(Post, :count).by(-1)
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq("投稿を削除しました。")
      end
    end

    context '投稿者以外のユーザーがログインしている場合' do
      before { sign_in other_user }

      # 💡 修正後: `RecordNotFound`エラーが発生することを確認
      it '投稿を削除できず、ActiveRecord::RecordNotFound例外が発生する' do
        expect { delete :destroy, params: { id: post_to_destroy.id } }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  # 🔥 solveアクションのテスト
  describe 'PATCH #solve' do
    let!(:post_to_solve) { create(:post, user: user, status: :unsolved) }

    context '投稿者本人がログインしている場合' do
      before { sign_in user }

      it '投稿のステータスが解決済みに更新され、ポイントが加算される' do
        expect { patch :solve, params: { id: post_to_solve.id } }.to change { post_to_solve.reload.status }.from('unsolved').to('solved')
        expect(user.reload.points).to eq(1)
        expect(response).to redirect_to(post_path(post_to_solve))
      end
    end

    context '未ログインのユーザーの場合' do
      it 'ログインページにリダイレクトされる' do
        patch :solve, params: { id: post_to_solve.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end