class PostsController < ApplicationController
  def index
    @posts = Post.all.order(created_at: :desc)
  end

  def show
    @post = find_post(params[:id])
  end

  def new
    @post = Post.new
  end

  def edit
    @post = find_post(params[:id])
  end

  def create
    @post = Post.new(post_params)
    @post.user_id = 1
    if @post.save
      redirect_to root_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @post = find_post(params[:id])
    if @post.update(post_params)
      redirect_to root_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    post = find_post(params[:id])
    post.destroy
    redirect_to root_path
  end

  private

  def find_post(id)
    Post.find(id)
  end

  def post_params
    params.require(:post).permit(:title, :content)
  end
end
