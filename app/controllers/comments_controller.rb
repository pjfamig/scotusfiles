class CommentsController < ApplicationController
  before_action :set_opinion
  before_action :authenticate_user!
  
  def create
    params[:comment][:user_id] = current_user.id
    @opinion.comments.create! params.required(:comment).permit(:content, :user_id)  
    redirect_to @opinion
  end

  private
  def set_opinion
    @opinion = Opinion.find(params[:opinion_id])
  end
end
