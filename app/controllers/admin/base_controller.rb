class Admin::BaseController < ApplicationController
  PER_PAGE = 50

  before_action :require_admin
  before_action { response.headers["X-Robots-Tag"] = "noindex" }

  private
    # Loads one page of records plus one extra to tell whether a next page exists.
    def paginate(scope)
      @page = [ params[:page].to_i, 1 ].max
      records = scope.limit(PER_PAGE + 1).offset((@page - 1) * PER_PAGE).to_a
      @next_page = @page + 1 if records.size > PER_PAGE
      records.first(PER_PAGE)
    end
end
