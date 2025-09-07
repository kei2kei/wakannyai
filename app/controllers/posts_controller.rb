class PostsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]
  before_action :set_post, only: [:edit, :update, :destroy, :solve, :sync_to_github]

  def index
    @q = Post.ransack(params[:q])
    @posts = @q.result(distinct: true).includes(:post_tags, :tags).order(created_at: :desc).page params[:page]
  end

  def my_posts
    @posts = current_user.posts.order(created_at: :desc)
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
  end

  def create
    @post = current_user.posts.build(post_params)
    if @post.save
      purge_images if params[:post][:purged_image_ids]
      current_user.increment!(:points, 1)
      current_user.cat.update_level
      redirect_to root_path
    else
      @unattached_blobs = find_unattached_blobs
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @post.update(post_params)
      # formのパージ用隠しフィールドに入ってるものは削除
      purge_images if params[:post][:purged_image_ids]
      redirect_to post_path(@post.id)
    else
      @unattached_blobs = find_unattached_blobs
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @post.destroy
      redirect_to root_path, notice: "投稿を削除しました。"
    else
      redirect_to @post, alert: "投稿を削除できませんでした。"
    end
  end

  def solve
    if current_user == @post.user && @post.unsolved?
      @post.solved!
      current_user.increment!(:points, 1)
      current_user.cat.update_level
      redirect_to post_path(@post), success: '解決おめでとうございます。'
    else
      redirect_to @post, alert: '解決済みにできません。'
    end
  end

  def sync_to_github
    service = GithubService.new(current_user)

    unless service.can_sync?
      redirect_to @post, alert: 'GitHub連携を設定してください'
      return
    end

    result = service.sync_post(@post)

    if result[:success]
      redirect_to @post, notice: 'GitHubに同期しました！'
    else
      redirect_to @post, alert: "同期に失敗しました: #{result[:error]}"
    end
  end

  private

  def set_post
    @post = current_user.posts.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:title, :content, :tag_names, images: [])
  end

  def purge_images
    purged_ids = params[:post][:purged_image_ids]

    purged_ids.each do |signed_id|
      blob = ActiveStorage::Blob.find_signed(signed_id)
      blob&.purge
    end
  end

  def find_unattached_blobs
    return [] unless params[:post][:images]
    blobs = params[:post][:images].map do |image|
      ActiveStorage::Blob.find_signed(image)
    end

    blobs.compact.map do |blob|
      {
        id: blob.id,
        url: url_for(blob),
        signed_id: blob.signed_id
      }
    end
  end
end
