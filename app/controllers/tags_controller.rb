class TagsController < ApplicationController
  def search
    q = (params[:q] || params[:query]).to_s.strip
    return render json: [] if q.blank?

    # ワイルドカードのエスケープ
    pattern = ActiveRecord::Base.sanitize_sql_like(q.downcase) + "%"

    tags = Tag.where("LOWER(name) LIKE ?", pattern)
              .order(:name)
              .limit(20)
              .pluck(:id, :name)

    render json: tags.map { |id, name| { value: name, id: id } }
  end

  private
  def tag_params
    params.require(:tag).permit(:name)
  end
end
