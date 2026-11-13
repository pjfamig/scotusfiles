class CommentsController < ApplicationController
  allow_unauthenticated_access only: :index
  before_action :set_decision
  rate_limit to: 20, within: 1.minute, only: :create, with: -> { head :too_many_requests }

  def index
    response.headers["X-Robots-Tag"] = "noindex"
    @recent_comments = @decision.comments.latest_first.includes(:user, :passage).limit(50)
  end

  def create
    @passage = @decision.passages.find_by!(key: params[:passage_key]) if params[:passage_key].present?
    @comment = @decision.comments.new(comment_params.merge(user: current_user, passage: @passage))

    if @comment.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to decision_path(@decision, anchor: @passage&.anchor) }
      end
    else
      render turbo_stream: turbo_stream.replace("comment_form", partial: "comments/form",
        locals: { decision: @decision, passage: @passage, comment: @comment }), status: :unprocessable_entity
    end
  end

  def destroy
    comment = @decision.comments.find(params[:id])
    return head :forbidden unless current_user.can_delete?(comment)

    comment.destroy
    respond_to do |format|
      format.turbo_stream { render turbo_stream: [ turbo_stream.remove(comment), turbo_stream.remove(dom_id(comment, :discussion)) ] }
      format.html { redirect_to decision_path(@decision), status: :see_other }
    end
  end

  private
    def set_decision
      @decision = Decision.find_by!(slug: params[:decision_id])
    end

    def comment_params
      params.expect(comment: [ :body ])
    end

    def dom_id(...) = ActionView::RecordIdentifier.dom_id(...)
end
