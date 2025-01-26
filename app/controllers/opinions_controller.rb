class OpinionsController < ApplicationController
  #before_action :authenticate_user!, :except => [:index, :show]
  before_action :authenticate_admin!, :except => [:index, :show]
  before_action :set_opinion, only: %i[ show edit update destroy ]

  # GET /opinions or /opinions.json
  def index
    @opinions = Opinion.order(decision_date: :desc).page(params[:page]).per(40)
  end

  # GET /opinions/1 or /opinions/1.json
  def show
    @opinion = Opinion.friendly.find(params[:id])
    @opinions = Opinion.order(decision_date: :desc).page(params[:page]).per(10)
    @synopsis = @opinion.synopses.last

    # Find and load HTML file for opinion
    # @full_decision = File.read(Rails.root.join('public', 'opinions', @opinion.filename))
    # @full_decision = @full_decision.html_safe
  end

  # GET /opinions/new
  def new
    @opinion = Opinion.create!
    redirect_to edit_opinion_path(@opinion.id)
  end

  # GET /opinions/1/edit
  def edit
    @synopsis = @opinion.synopses.last
  end

  # POST /opinions or /opinions.json
  def create
    params[:opinion][:user_id] = current_user.id

    @opinion = Opinion.new(opinion_params)

    # Define the escape_inner_double_quotes method
    def escape_inner_double_quotes(input)
      input.gsub('"', '\"')
    end

    # Split the full_decision text into sentences
    escaped_decision = escape_inner_double_quotes(@opinion.full_decision)
    sentences = escaped_decision.split(/(?<=[.!?])\s+/)

    # Create a separate record in the "quotes" database for each sentence
    sentences.each do |sentence|
      Quote.create(content: sentence, opinion_id: @opinion.id)
    end

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
    @synopsis = Synopsis.new(opinion: @opinion)
    message_creator = MessageCreator.new(params: synopsis_params)
    response = message_creator.call
    
    ActiveRecord::Base.transaction do
      @opinion.update!(synopsis_params)
      @synopsis.assign_attributes(body: response)
      @synopsis.save!
    end

    redirect_to opinion_path(@opinion)
    
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
      :dissent, :concurrence, files: [])
    end
    
    def synopsis_params
      params.require(:opinion).permit(:title, :holding, :full_decision, 
      :filename, :decision_date, :user_id, :syllabus, :majority_opinion, 
      :dissent, :concurrence, files: [])
    end
end
