class ApplicationController < ActionController::Base
  include Authentication

  CRAWLER_USER_AGENT = /bot\b|crawl|spider|slurp|facebookexternalhit|embedly|preview|lighthouse|google-inspectiontool|bingbot|duckduck/i

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # Crawlers such as Bingbot report older Chrome versions and would otherwise get a 406 instead of the page.
  allow_browser versions: :modern, unless: :crawler?

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :resume_session
  helper_method :current_user

  private
    def current_user = Current.user

    def crawler? = request.user_agent.to_s.match?(CRAWLER_USER_AGENT)

    def require_admin
      head :forbidden unless current_user&.admin?
    end
end
