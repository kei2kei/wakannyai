require 'rails_helper'

RSpec.describe CommentsController, type: :controller do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:new_post) { create(:post, user: user) }
  let!(:comment) { create(:comment, post: new_post, user: other_user) }

  describe 'POST #create' do
    context 'ログイン済みのユーザーの場合' do
      before { sign_in other_user }

      it 'コメントが成功すると、投稿ページにリダイレクトされる' do
        comment_params = { content: 'テストコメント' }
        expect { post :create, params: { post_id: new_post.id, comment: comment_params } }.to change(Comment, :count).by(1)
        expect(response).to redirect_to(post_path(new_post))
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:comment_to_destroy) { create(:comment, post: new_post, user: user) }

    context 'コメントがベストアンサーでない場合' do
      before { sign_in user }

      it 'コメントを削除し、投稿ページにリダイレクトされる' do
        expect { delete :destroy, params: { post_id: new_post.id, id: comment_to_destroy.id } }.to change(Comment, :count).by(-1)
        expect(response).to redirect_to(post_path(new_post))
      end
    end

    context 'コメントがベストアンサーである場合' do
      before { sign_in user }
      let!(:best_comment) { create(:comment, post: new_post, user: user, is_best_answer: true) }

      it 'コメントを削除できず、リダイレクトされる' do
        expect { delete :destroy, params: { post_id: new_post.id, id: best_comment.id } }.not_to change(Comment, :count)
        expect(response).to redirect_to(post_path(new_post))
      end
    end
  end

  describe 'PATCH #set_best_comment' do
    let!(:target_comment) { create(:comment, post: new_post, user: other_user) }

    context '投稿者本人がログインしている場合' do
      before { sign_in user }

      it 'コメントのis_best_answerがtrueに更新される' do
        patch :set_best_comment, params: { post_id: new_post.id, id: target_comment.id }
        expect(target_comment.reload.is_best_answer).to be_truthy
        expect(response).to redirect_to(post_path(new_post))
      end

      it '自分のコメントはベストアンサーに選べない' do
        my_comment = create(:comment, post: new_post, user: user)
        patch :set_best_comment, params: { post_id: new_post.id, id: my_comment.id }
        expect(my_comment.reload.is_best_answer).to be_falsey
      end
    end

    context '投稿者以外のユーザーがログインしている場合' do
      before { sign_in other_user }

      it 'ベストアンサーを選べず、リダイレクトされる' do
        patch :set_best_comment, params: { post_id: new_post.id, id: target_comment.id }
        expect(target_comment.reload.is_best_answer).to be_falsey
        expect(response).to redirect_to(post_path(new_post))
      end
    end
  end
end