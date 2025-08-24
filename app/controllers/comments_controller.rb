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
    @comment = current_user.comments.find(params[:id])
    if @comment.post.best_comment_id == @comment.id
      redirect_to post_path(@comment.post), alert: "ベストアンサーに選ばれたコメントは削除できません。"
      return
    end
    if current_user == @comment.user
      @comment.destroy
      redirect_to post_path(@comment.post), notice: "コメントを削除しました。"
    else
      redirect_to post_path(@comment.post), alert: "権限がありません。"
    end
  end

  def new_reply
    @parent_comment = Comment.find(params[:parent_id])
    @post = @parent_comment.post
    @comment = @parent_comment.replies.build
    respond_to do |format|
      format.html { render partial: 'comments/form', locals: { comment: @comment, post: @post, parent_comment: @parent_comment } }
    end
  end

  def set_best_comment
    @comment = Comment.find(params[:id])
    if @comment.post.best_comment.present? || current_user != @comment.post.user || @comment.post.user == @comment.user
      redirect_to post_path(@comment.post), alert: '権限がありません。'
    end

    @comment.post.update(best_comment: @comment)
    @comment.user.increment!(:points, 5)
    redirect_to post_path(@comment.post), notice: 'ベストアンサーを選びました。'
  end

  private
  def comment_params
    params.require(:comment).permit(:content, :parent_id).merge(post_id: params[:post_id])
  end
end
