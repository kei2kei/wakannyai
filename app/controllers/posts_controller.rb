class PostsController < ApplicationController
  def index
    @q = Post.ransack(params[:q])
    @posts = @q.result(distinct: true).includes(:post_tags, :tags).order(created_at: :desc).page params[:page]
  end

  def show
    @post = Post.find(params[:id])
    @comment = @post.comments.new
    @comments = @post.comments.where(parent_id: nil).includes(:replies)
  end

  def new
    @post = Post.new
  end

  def edit
    @post = Post.find(params[:id])
  end

  def create
    @post = current_user.posts.build(post_params)
    if @post.save
      current_user.increment!(:points, 1)
      redirect_to root_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @post = Post.find(params[:id])
    if @post.update(post_params)
      redirect_to post_path(@post.id)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    post = Post.find(params[:id])
    post.destroy
    redirect_to root_path
  end

  def solve
    @post = Post.find(params[:id])
    if current_user == @post.user && @post.unsolved?
      @post.solved!
      current_user.increment!(:points, 2)
      redirect_to post_path(@post), success: '解決おめでとうございます。'
    else
      redirect_to @post, alert: '解決済みにできません。'
    end
  end

  private

  def post_params
    params.require(:post).permit(:title, :content, :tag_names)
  end
end
