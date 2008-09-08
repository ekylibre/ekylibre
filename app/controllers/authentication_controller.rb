class AuthenticationController < ApplicationController

  def index
  	redirect_to :action=>:login
  end

  def login
    if request.post? and session[:user_id].blank?
      user = User.authenticate(params[:user][:name], params[:user][:password])
      if user
        session[:user_id] = user.id
#		    redirect_to :controller=>:guide, :action=>:index unless session[:user_id].blank?
      else
        flash[:warning] = 'User can not be authenticated. Please retry.'
      end
    end
  end

  def logout
    session[:user_id] = nil    
    redirect_to :action=>:login
  end

end
