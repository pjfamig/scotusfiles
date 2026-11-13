class Admin::DashboardsController < Admin::BaseController
  CHART_DAYS = 30

  def show
    week_ago = 7.days.ago

    @stats = {
      users: User.count, users_this_week: User.where(created_at: week_ago..).count,
      comments: Comment.count, comments_this_week: Comment.where(created_at: week_ago..).count,
      decisions: Decision.count, decisions_this_week: Decision.where(created_at: week_ago..).count,
      failed_decisions: Decision.failed.count,
      refreshes_this_week: DecisionImport.refreshes.where(created_at: week_ago..).count,
      failed_imports_this_week: DecisionImport.failed.where(created_at: week_ago..).count
    }
    @daily_signups = daily_counts(User)
    @daily_comments = daily_counts(Comment)

    @recent_users = User.order(created_at: :desc).limit(8)
    @recent_comments = Comment.latest_first.includes(:user, :decision).limit(8)
    @recent_decisions = Decision.order(created_at: :desc).limit(8)
    @recent_imports = DecisionImport.latest_first.includes(:decision).limit(8)
    @recent_syncs = TermSync.latest_first.limit(5)
    @failed_decisions = Decision.failed.latest_first.limit(10)
  end

  private
    def daily_counts(model)
      zone = helpers.admin_time_zone
      start = (CHART_DAYS - 1).days.ago.in_time_zone(zone).beginning_of_day
      counts = model.where(created_at: start..).pluck(:created_at).map { |time| time.in_time_zone(zone).to_date }.tally
      (start.to_date..Time.current.in_time_zone(zone).to_date).map { |day| [ day, counts.fetch(day, 0) ] }
    end
end
