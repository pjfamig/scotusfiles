class UsersController < ApplicationController
  before_action :authenticate_admin!
  
  def index
    @users = User.order(id: :desc)
  end
  
  def show
    @user = User.find(params[:id])
  end
end
