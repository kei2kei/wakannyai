
require 'rails_helper'

RSpec.describe Post, type: :model do
  describe 'アクティブストレージのテスト' do
    let(:post) { create(:post, :with_images) }

    it 'ポスト削除時にイメージの削除がジョブにキューされているか' do
      expect { post.destroy }.to have_enqueued_job(ActiveStorage::PurgeJob).on_queue(:default)
    end
  end

  describe 'Postのバリデーションテスト' do
    let(:user) { create(:user) }

    it "タイトル、内容、ユーザーの正常登録" do
      post = build(:post, user: user)
      expect(post).to be_valid
    end

    it "タイトルがない場合のエラー確認" do
      post = build(:post, title: nil, user: user)
      post.valid?
      expect(post.errors[:title]).to include("can't be blank")
    end

    it "内容がない場合のエラー確認" do
      post = build(:post, content: nil, user: user)
      post.valid?
      expect(post.errors[:content]).to include("can't be blank")
    end

    it "ユーザーがいない場合のエラー確認" do
      post = build(:post, user: nil)
      post.valid?
      expect(post.errors[:user]).to include("must exist")
    end
  end

  describe 'アソシエーションテスト（コメント）' do
    context '通常のコメントごとポスト削除' do
      let(:post) { create(:post) }
      let!(:comment) { create(:comment, post: post) }
      it "ポスト削除時のコメントの削除" do
        expect { post.destroy }.to change(Comment, :count).by(-1)
      end
    end

    context 'ベストコメント付きのポスト削除' do
      let(:user) { create(:user) }
      let(:post) { create(:post, user: user) }
      let(:other_user) { create(:user) }
      let!(:best_comment) { create(:comment, post: post, user: other_user) }
      before do
        # 投稿にベストアンサーを設定する
        post.update(best_comment: best_comment)
      end

        # 💡 ベストアンサーが設定された投稿は削除できない
      it "cannot be deleted" do
        expect { post.destroy }.to change(Post, :count).by(0)
      end
      it "leaves the post intact and returns an error" do
        expect(post.destroy).to be_falsey
        expect(post.reload).to be_present
      end
    end
  end
end
