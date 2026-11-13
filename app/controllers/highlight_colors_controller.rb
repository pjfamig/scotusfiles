class HighlightColorsController < ApplicationController
  def update
    if current_user.update(highlight_color: params.require(:highlight_color))
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("highlight_picker", partial: "highlight_colors/picker") }
        format.html { redirect_back_or_to root_path }
      end
    else
      head :unprocessable_entity
    end
  end
end
