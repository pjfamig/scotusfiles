class DecisionsController < ApplicationController
  allow_unauthenticated_access

  def index
    @query = params[:q].to_s.strip
    return if redirect_legacy_listing

    @terms = Decision.terms
    @term = params[:term].presence&.to_i || @terms.first || Scotus::SlipOpinionIndex.current_term
    if params[:term].present?
      raise ActiveRecord::RecordNotFound if @terms.exclude?(@term) && !current_user&.admin?
      return redirect_permanently_to(root_path) if @query.empty? && @term == @terms.first
    end

    scope = @query.present? ? Decision.search(@query) : Decision.in_term(@term)
    @decisions = scope.latest_first.limit(200)
  end

  def show
    @decision = Decision.find_by!(slug: params[:id])
    @opinions = @decision.opinions
    @recent_comments = @decision.comments.latest_first.includes(:user, :passage).limit(50)
    @related_decisions = Decision.in_term(@decision.term).imported.where.not(id: @decision.id).latest_first.limit(6)
  end

  def feed
    @decisions = Decision.imported.where.not(decided_on: nil).latest_first.limit(50)
    expires_in 30.minutes, public: true
  end

  private
    # /decisions and /decisions?term=2024 predate the clean listing URLs; send them to their canonical pages.
    def redirect_legacy_listing
      return false unless request.path == decisions_path && @query.empty?

      term = params[:term].to_s
      older_term = term.match?(/\A\d{4}\z/) && term.to_i != Decision.maximum(:term)
      redirect_permanently_to(older_term ? term_path(term) : root_path)
      true
    end

    def redirect_permanently_to(path)
      flash.keep
      redirect_to path, status: :moved_permanently
    end
end
