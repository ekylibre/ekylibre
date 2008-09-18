class AuthenticationController < ApplicationController
  
  def index
    redirect_to :action=>:login
  end
  
  def test
    send_data render_report(Template.find(params[:id]).content, 1), :filename=>'enfin'+params[:id].to_s+'.pdf'
  end

  def login
    if request.post?
      user = User.authenticate(params[:user][:name], params[:user][:password])
      if user
        session[:user_id] = user.id
        session[:last_query] = Time.now.to_i
        session[:expiration] = 3600
        redirect_to :controller=>session[:last_controller]||:guide, :action=>session[:last_action]||:index unless session[:user_id].blank?
      else
        flash[:error] = lc :no_authenticated # 'User can not be authenticated. Please retry.'
      end
    end
  end

  def register
    @step = (params[:step]||1).to_i
    @step = 1 if @step<1
    @last = 3
  end
  
  def logout
    session[:user_id] = nil    
    session[:last_controller] = nil
    session[:last_action] = nil
    redirect_to :action=>:login
  end
  
end
