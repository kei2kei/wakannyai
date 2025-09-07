require 'rails_helper'

RSpec.describe Comment, type: :model do
  describe 'Commentのアソシエーション確認' do
    let(:parent_comment) { create(:comment) }
    let(:reply) { create(:comment, parent_comment: parent_comment) }

    it '親コメントが存在する' do
      expect(reply.parent_comment).to eq(parent_comment)
    end

    it '返信が存在する' do
      expect(parent_comment.replies).to include(reply)
    end
  end

  describe 'ベストアンサーのテスト' do
    let(:post) { create(:post) }
    let!(:best_comment) { create(:comment, post: post, is_best_answer: true) }
    let!(:other_comment) { create(:comment, post: post, is_best_answer: false) }

    it 'ポストに対してのベストアンサーが存在する' do
      expect(post.comments.best_answer).to eq(best_comment)
    end
  end
end