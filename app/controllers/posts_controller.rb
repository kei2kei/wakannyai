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
      purge_images if params[:post][:purged_image_ids]
      current_user.increment!(:points, 1)
      redirect_to root_path
    else
      @unattached_blobs = find_unattached_blobs
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @post = Post.find(params[:id])
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
    blobs = ActiveStorage::Blob.find_signed(params[:post][:images])

    blobs.compact.map do |blob|
      {
        id: blob.id,
        url: url_for(blob),
        signed_id: blob.signed_id
      }
    end
  end
end
