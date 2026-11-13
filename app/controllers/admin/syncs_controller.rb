class Admin::SyncsController < ApplicationController
  before_action :require_admin

  def create
    term = params[:term_id].to_i
    SyncTermJob.perform_later(term)
    redirect_to term_path(term), notice: "Checking supremecourt.gov for October Term #{term} opinions…"
  end
end
