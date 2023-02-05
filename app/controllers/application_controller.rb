class ApplicationController < ActionController::Base
  before_action do
    ActiveStorage::Current.host = 'http://localhost:3000'
  end
  
  protected 
  
  def authenticate_admin!
    authenticate_user!
    redirect_to root_path, status: :forbidden unless current_user.admin?
  end
  
end
