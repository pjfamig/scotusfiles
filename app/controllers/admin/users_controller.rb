class Admin::UsersController < Admin::BaseController
  def index
    @query = params[:q].to_s.strip
    scope = User.select("users.*",
      "(SELECT COUNT(*) FROM comments WHERE comments.user_id = users.id) AS comments_total",
      "(SELECT MAX(sessions.created_at) FROM sessions WHERE sessions.user_id = users.id) AS last_signed_in_at")
    if @query.present?
      pattern = "%#{User.sanitize_sql_like(@query)}%"
      scope = scope.where("users.name ILIKE :pattern OR users.email_address ILIKE :pattern", pattern: pattern)
    end
    @users = paginate(scope.order(created_at: :desc, id: :desc))
  end
end
