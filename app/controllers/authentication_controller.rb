class AuthenticationController < ApplicationController
  
  def index
    redirect_to :action=>:login
  end
  
  def retrieve
     retrieve_report(params[:id])
  end

  def render_f
    render :report=>params[:id], :key=>1, :output=>pdf
    #render_report(params[:id])    
  end

  def login
    @login = 'lf'
    if request.post?
#      raise Exception.new params[:screen_width].to_s+'/'+params[:screen_width].class.to_s
      session[:body_width] = params[:screen_width].to_i-50 if params[:screen_width]
      user = User.authenticate(params[:user][:name], params[:user][:password])
      if user
        init_session(user)
        redirect_to :controller=>session[:last_controller]||:guide, :action=>session[:last_action]||:index unless session[:user_id].blank?
      else
        flash[:error] = lc :no_authenticated # 'User can not be authenticated. Please retry.'
      end
      session[:user_name] = params[:user][:name]
    end
  end

  def register
    if request.post?
      if session[:company_id].nil?
        @company = Company.new(params[:company])
      else
        @company = Company.find(session[:company_id])
        @company.attributes = params[:company]
      end
      if @company.save
        session[:company_id] = @company.id
        params[:user][:company_id] = @company.id
        @user = User.new(params[:user])
        @user.role_id = @company.admin_role.id
        if @user.save
          init_session(@user)
          redirect_to :controller=>:guide, :action=>:welcome
        end
      end
    else
      session[:company_id] = nil
    end
  end
  
  def logout
    session[:user_id] = nil    
    session[:last_controller] = nil
    session[:last_action] = nil
    reset_session
    redirect_to :action=>:login
  end

  protected

  def init_session(user)
    session[:user_id] = user.id
    session[:last_query] = Time.now.to_i
    session[:expiration] = 3600
  end
  
end
