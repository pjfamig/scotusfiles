class DecisionsController < ApplicationController
  allow_unauthenticated_access

  def index
    @terms = Decision.terms
    @term = params[:term].presence&.to_i || @terms.first || Scotus::SlipOpinionIndex.current_term
    @query = params[:q].to_s.strip

    scope = @query.present? ? Decision.search(@query) : Decision.in_term(@term)
    @decisions = scope.latest_first.limit(200)
  end

  def show
    @decision = Decision.find_by!(slug: params[:id])
    @opinions = @decision.opinions
    @recent_comments = @decision.comments.latest_first.includes(:user, :passage).limit(50)
  end
end
