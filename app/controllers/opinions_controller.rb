class OpinionsController < ApplicationController
  #before_action :authenticate_user!, :except => [:index, :show]
  before_action :authenticate_admin!, :except => [:index, :show]
  before_action :set_opinion, only: %i[ show edit update destroy ]

  # GET /opinions or /opinions.json
  def index
    @opinions = Opinion.order(id: :asc)
  end

  # GET /opinions/1 or /opinions/1.json
  def show
    @opinion = Opinion.find(params[:id])

    # Read the content of the HTML file
    # @full_decision = File.read(Rails.root.join('public', 'opinions', @opinion.filename))
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
    
    
    # Save the content of the opinion to a separate HTML file
    filename = "#{Time.now.strftime('%Y%m%d%H%M%S')}.html"
    File.write(Rails.root.join('public', 'opinions', filename), @opinion.full_decision)

    @opinion.filename = filename

    respond_to do |format|
      if @opinion.save
        puts "Files after save: #{opinion_params[:files].inspect}"
        format.html { redirect_to opinion_url(@opinion), notice: "Opinion was successfully created." }
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
        format.html { redirect_to opinion_url(@opinion), notice: "Opinion was successfully updated." }
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
      format.html { redirect_to opinions_url, notice: "Opinion was successfully destroyed." }
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
      @opinion = Opinion.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def opinion_params
      params.require(:opinion).permit(:title, :holding, :full_decision, :filename, :decision_date, :user_id, files: [])
    end
end
