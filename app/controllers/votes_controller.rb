class VotesController < ApplicationController
  before_action :set_comment
  rate_limit to: 60, within: 1.minute, with: -> { head :too_many_requests }

  def update
    @vote = @comment.votes.find_or_initialize_by(user: current_user)

    if @vote.update(direction: params.expect(:direction))
      render_votes
    else
      head :unprocessable_entity
    end
  end

  def destroy
    @comment.votes.find_by(user: current_user)&.destroy
    render_votes
  end

  private
    def set_comment
      @decision = Decision.find_by!(slug: params[:decision_id])
      @comment = @decision.comments.find(params[:comment_id])
    end

    def render_votes
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(ActionView::RecordIdentifier.dom_id(@comment, :votes),
            partial: "comments/votes", locals: { comment: @comment.reload, vote: @vote&.persisted? ? @vote : nil })
        end
        format.html { redirect_to decision_path(@decision, s: @comment.passage&.key), status: :see_other }
      end
    end

    # Guests vote from the passage panel, which already remembered the
    # decision to return to; the vote URL itself can't be revisited with GET.
    def request_authentication
      redirect_to new_session_path
    end
end
