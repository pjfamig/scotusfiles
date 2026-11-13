class Admin::CommentsController < Admin::BaseController
  def index
    @user = User.find(params[:user_id]) if params[:user_id].present?
    scope = Comment.latest_first.includes(:user, :decision, :passage)
    scope = scope.where(user: @user) if @user
    @comments = paginate(scope)
  end
end
