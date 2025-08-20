class CommentsController < ApplicationController
  def create
    comment = current_user.comments.build(comment_params)
    if comment.save
      redirect_to post_path(comment.post), success: "コメントを投稿しました。"
    else
      redirect_to post_path(comment.post), danger: "コメントの作成に失敗しました。"
    end
  end

  private
  def comment_params
    params.require(:comment).permit(:content).merge(post_id: params[:post_id])
  end
end
