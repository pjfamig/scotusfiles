class ApplicationController < ActionController::Base
  include Authentication

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :resume_session
  helper_method :current_user

  private
    def current_user = Current.user

    def require_admin
      head :forbidden unless current_user&.admin?
    end
end
