class AuthenticationController < ApplicationController
  
  def index
    redirect_to :action=>:login
  end
  
  def test
  end

  def login
    send_data render_report(Template.find(1).content, 1), :filename=>'enfin2.pdf'
    if request.post?
      user = User.authenticate(params[:user][:name], params[:user][:password])
      if user
        session[:user_id] = user.id
        session[:last_query] = Time.now.to_i        
        redirect_to :controller=>:guide, :action=>:index unless session[:user_id].blank?
      else
        flash[:error] = lc :no_authenticated # 'User can not be authenticated. Please retry.'
      end
    end
  end
  
  def logout
    session[:user_id] = nil    
    redirect_to :action=>:login
  end
  
end
