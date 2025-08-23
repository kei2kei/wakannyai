class CommentsController < ApplicationController
  def create
    comment = current_user.comments.build(comment_params)
    if comment.save
      redirect_to post_path(comment.post), success: "コメントを投稿しました。"
    else
      redirect_to post_path(comment.post), danger: "コメントの作成に失敗しました。"
    end
  end

  def destroy
    comment = current_user.comments.find(params[:id])
    comment.destroy
    redirect_to post_path(comment.post)
  end

  def new_reply
    @parent_comment = Comment.find(params[:parent_id])
    @post = @parent_comment.post
    @comment = @parent_comment.replies.build
    respond_to do |format|
      format.html { render partial: 'comments/form', locals: { comment: @comment, post: @post, parent_comment: @parent_comment } }
    end
  end

  private
  def comment_params
    params.require(:comment).permit(:content, :parent_id).merge(post_id: params[:post_id])
  end
end
