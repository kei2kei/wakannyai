class TagsController < ApplicationController
  def search
    query = params[:query]
    if query.present?
      @tags = Tag.where("name Like ?", "#{query}%").limit(5)
    else
      @tags = Tag.none
    end
    render json: @tags.map { |tag| { id: tag.id, name: tag.name } }
  end

  private
  def tag_params
    params.require(:tag).permit(:name)
  end
end
