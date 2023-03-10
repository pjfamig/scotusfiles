class OpinionsController < ApplicationController
  #before_action :authenticate_user!, :except => [:index, :show]
  before_action :authenticate_admin!, :except => [:index, :show]
  before_action :set_opinion, only: %i[ show edit update destroy ]

  # GET /opinions or /opinions.json
  def index
    @opinions = Opinion.order(decision_date: :desc).page(params[:page]).per(10)
  end

  # GET /opinions/1 or /opinions/1.json
  def show
    @opinion = Opinion.friendly.find(params[:id])

    # Find and load HTML file for opinion
    # @full_decision = File.read(Rails.root.join('public', 'opinions', @opinion.filename))
    # @full_decision = @full_decision.html_safe
  end

  # GET /opinions/new
  def new
    @opinion = Opinion.new
  end

  # GET /opinions/1/edit
  def edit
  end

  # POST /opinions or /opinions.json
  def create
    params[:opinion][:user_id] = current_user.id

    @opinion = Opinion.new(opinion_params)
    puts "Files before save: #{opinion_params[:files].inspect}"
    
    # Convert full_decision to html_safe text in preparation for saving
    # full_decision_html = @opinion.full_decision.html_safe
  
    # Save the HTML content to a separate file
    # filename = "#{@opinion.title.parameterize}-#{Time.now.strftime('%Y%m%d%H%M%S')}.html"
    # File.write(Rails.root.join('public', 'opinions', filename), full_decision_html)
    
    # @opinion.filename = filename

    respond_to do |format|
      if @opinion.save
        puts "Files after save: #{opinion_params[:files].inspect}"
        format.html { redirect_to opinion_url(@opinion), notice: "Opinion successfully created!" }
        format.json { render :show, status: :created, location: @opinion }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @opinion.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /opinions/1 or /opinions/1.json
  def update
    params[:opinion][:user_id] = current_user.id
    
    respond_to do |format|
      if @opinion.update(opinion_params)
        # Convert the updated rich text content to HTML format
        # full_decision_html = @opinion.full_decision.html_safe
  
        # Save the HTML content to the existing file
        # File.write(Rails.root.join('public', 'opinions', @opinion.filename), full_decision_html)

        format.html { redirect_to opinion_url(@opinion), notice: "Opinion successfully updated!" }
        format.json { render :show, status: :ok, location: @opinion }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @opinion.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /opinions/1 or /opinions/1.json
  def destroy
    @opinion.destroy

    respond_to do |format|
      format.html { redirect_to opinions_url, alert: "Opinion destroyed." }
      format.json { head :no_content }
    end
  end
  
  # DELETE FILES ASSOCIATED WITH /opinions/1 or /opinions/1.json
  def delete_file
    file = ActiveStorage::Attachment.find(params[:id])
    file.purge
    redirect_back(fallback_location: opinions_path)
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_opinion
      @opinion = Opinion.friendly.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def opinion_params
      params.require(:opinion).permit(:title, :holding, :full_decision, 
      :filename, :decision_date, :user_id, :syllabus, :majority_opinion, 
      :dissent, files: [])
    end
end
