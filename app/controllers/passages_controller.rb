class PassagesController < ApplicationController
  allow_unauthenticated_access

  def show
    @decision = Decision.find_by!(slug: params[:decision_id])
    @passage = @decision.passages.find_by!(key: params[:id])

    unless turbo_frame_request?
      redirect_to decision_path(@decision, anchor: @passage.anchor)
      return
    end

    session[:return_to_after_authenticating] = decision_url(@decision, s: @passage.key) unless authenticated?
    @comments = @passage.comments.chronological.includes(:user)
  end
end
