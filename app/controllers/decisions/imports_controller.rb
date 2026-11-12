class Decisions::ImportsController < ApplicationController
  before_action :require_admin

  def create
    decision = Decision.find_by!(slug: params[:decision_id])
    decision.pending!
    decision.import_later
    redirect_to decision, notice: "Re-importing from the Court’s PDF…"
  end
end
