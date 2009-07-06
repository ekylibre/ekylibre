require "digest/sha2"

class AuthenticationController < ApplicationController
  
  def index
    redirect_to :action=>:login
  end
  
  def login
    session[:help] = false
    if request.post?
      user = User.authenticate(params[:user][:name], params[:user][:password])
      if user
        init_session(user)
        #raise Exception.new session[:rights].inspect
        unless session[:user_id].blank?
          redirect_to session[:last_url]||{:controller=>:guide, :action=>:index}
        end
      else
        flash[:error] = tc(:no_authenticated)
      end
      session[:user_name] = params[:user][:name]
    end
  end
  
  def register
    if request.post?
      if defined?(Ekylibre::DONT_REGISTER)
        hash = Digest::SHA256.hexdigest(params[:register_password].to_s)
        puts hash
        redirect_to :action=>:login unless defined?(Ekylibre::DONT_REGISTER_PASSWORD)
        redirect_to :action=>:login if hash!=Ekylibre::DONT_REGISTER_PASSWORD
      end
      
      @company = Company.new(params[:company])
      @user = User.new(params[:user])
      saved = true
     
      ActiveRecord::Base.transaction do
        saved = @company.save
        if saved
          @user.company_id = @company.id
          @user.role_id = @company.admin_role.id
          saved = false unless @user.save
        end
        raise ActiveRecord::Rollback unless saved            
      end
      if saved
        init_session(@user)
        redirect_to :controller=>:guide, :action=>:welcome
      end
  
    else
      @company = Company.new
      @user = User.new
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
    session[:help] = true
    session[:user_id] = user.id
    session[:last_query] = Time.now.to_i
    session[:expiration] = 3600
    session[:help_history] = []
    session[:rights] = user.role.rights.split(" ").collect{|x| x.to_sym}
#    session[:menu_guide] = user.company.menu("guide") 
#    session[:menu_user]  = user.company.menu("user")
    
  end
  
end
