class PostsController < ApplicationController
  skip_before_action :require_login, only: %i[index show]
  def index
    @q = Post.ransack(params[:q])
    @posts = @q.result(distinct: true).includes(:post_tags, :tags).order(created_at: :desc).page params[:page]
    # 一覧画面のカレンダーに合わせ週初め（日曜）〜週終わり（土曜）までのコントリビューションのデータを取得
    today = Date.today
    @git_hub_contributions = GitHubContribution.where(date: (today.beginning_of_week - 1)..(today.end_of_week - 1)).order(:date)
  end

  def show
    @post = Post.find(params[:id])
  end

  def new
    @post = Post.new
  end

  def edit
    @post = find_post(params[:id])
  end

  def create
    @post = current_user.posts.build(post_params)
    if @post.save
      redirect_to root_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @post = find_post(params[:id])
    if @post.update(post_params)
      redirect_to post_path(@post.id)
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
    current_user.posts.find(id)
  end

  def post_params
    params.require(:post).permit(:title, :content, :tag_names, :thumbnail)
  end
end
