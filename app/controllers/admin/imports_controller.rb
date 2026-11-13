class Admin::ImportsController < Admin::BaseController
  FILTERS = %w[ first refresh failed ].freeze

  def index
    @filter = params[:filter].presence_in(FILTERS)
    scope = DecisionImport.latest_first.includes(:decision)
    scope = case @filter
    when "first" then scope.first_imports
    when "refresh" then scope.refreshes
    when "failed" then scope.failed
    else scope
    end
    @imports = paginate(scope)
    @recent_syncs = TermSync.latest_first.limit(10) if @page == 1
  end
end
