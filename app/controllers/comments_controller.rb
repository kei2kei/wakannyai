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
    if @comment.is_best_answer
      redirect_to post_path(@comment.post), alert: "ベストアンサーに選ばれたコメントは削除できません。"
      return
    end
    @comment.destroy
    redirect_to post_path(@comment.post), notice: "コメントを削除しました。"
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
    if @comment.post.has_best_comment?
      redirect_to @comment.post, notice: '既にベストアンサーは選ばれています。'
      return
    end

    is_post_owner = (current_user == @comment.post.user)
    is_not_comment_author = (current_user != @comment.user)

    if is_post_owner && is_not_comment_author
      @comment.update(is_best_answer: true)
      @comment.user.increment!(:points, 5)
      @comment.user.cat.update_level
      redirect_to @comment.post, notice: 'ベストアンサーを選びました。'
    else
      redirect_to @comment.post, alert: 'ベストアンサーを選べるのは投稿者本人のみで、自身のコメントは選べません。'
    end
  end

  private
  def comment_params
    params.require(:comment).permit(:content, :parent_id).merge(post_id: params[:post_id])
  end
end
