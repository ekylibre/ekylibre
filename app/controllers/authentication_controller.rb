require "digest/sha2"

class AuthenticationController < ApplicationController
  
  def index
    redirect_to :action=>:login
  end
  
  def login
    if request.post?
      puts "POST : "+session[:last_session].inspect+" jhbjbjb"+session.inspect+" all !!! "+session.inspect
      name = params[:user][:name]
      company = nil
      sep = /[^a-z0-9\.\_]+/i
      if name.match sep
        lname = name.split(sep)
        session[:user_name] = lname[0].upper+'-'+lname[-1]
        company = Company.find_by_code(lname[0].upper)
        name = lname[-1]
      else
        if User.count(:conditions=>{:name=>name})>1
          flash.now[:warning] = tc(:need_company_code_to_login)
          return
        end
        session[:user_name] = name
      end
      user = User.authenticate(name, params[:user][:password], company)
      if user
        init_session(user)
        #raise Exception.new session[:rights].inspect
        unless session[:user_id].blank?
          redirect_to session[:last_url]||{:controller=>:company, :action=>:index}
        end
      else
        flash.now[:error] = tc(:no_authenticated)
      end
    end
  end
  
  def register
    if request.post?
      #raise Exception.new params.inspect
      if defined?(Ekylibre::DONT_REGISTER)
        hash = Digest::SHA256.hexdigest(params[:register_password].to_s)
        redirect_to :action=>:login unless defined?(Ekylibre::DONT_REGISTER_PASSWORD)
        redirect_to :action=>:login if hash!=Ekylibre::DONT_REGISTER_PASSWORD
        return
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
        if params[:demo][:load_data]
          Company.load_demo_data("fr-FR", @company)
        end
        raise ActiveRecord::Rollback unless saved            
      end
      if saved
        init_session(@user)
        redirect_to :controller=>:company, :action=>:welcome
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
    session[:expiration]   = 3600
    session[:help]         = true
    session[:help_history] = []
    session[:history]      = []
    session[:last_page]    = {}
    session[:last_query]   = Time.now.to_i
    session[:rights]       = user.rights.to_s.split(" ").collect{|x| x.to_sym}
    session[:side]         = true
    session[:user_id]      = user.id
  end
  
end
