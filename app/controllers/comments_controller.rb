class CommentsController < ApplicationController
  before_action :set_opinion
  before_action :authenticate_user!
  
  def create
    params[:comment][:user_id] = current_user.id
    comment = @opinion.comments.create! params.required(:comment).permit(:content, :user_id)  
    # CommentsMailer.submitted(comment).deliver_later
    redirect_to @opinion
  end

  private
  def set_opinion
    @opinion = Opinion.find(params[:opinion_id])
  end
end
