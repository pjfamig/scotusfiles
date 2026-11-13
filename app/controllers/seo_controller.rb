class SeoController < ApplicationController
  allow_unauthenticated_access
  skip_before_action :resume_session

  def sitemap
    @terms = Decision.group(:term).order(term: :desc).maximum(:updated_at)
    @decisions = Decision.where.not(status: :failed).latest_first.select(:id, :slug, :status, :updated_at, :imported_at)
    expires_in 1.hour, public: true
  end

  def robots
    expires_in 1.day, public: true
  end
end
