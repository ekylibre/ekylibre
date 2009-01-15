# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  before_filter :authorize, :except=>[:login, :register]
  attr_accessor :current_user
  attr_accessor :current_company
    
  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '232b3ccf31f8f5fefcbb9d2ac3a00415'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password

  protected  

  def render_form(options={})
    a = action_name.split '_'
    mode    = a[-1].to_sym
    @partial = options[:partial]||a[0..-2].join('_')+'_form'
    @options = options
    begin
      render :template=>options[:template]||'shared/form_'+mode.to_s
    rescue ActionController::DoubleRenderError
    end
  end

  def search_conditions(options={})
    conditions = ["company_id = ?", @current_company.id]
    keywords = options[:key].to_s.split(" ")
    if keywords.size>0 and options[:attributes].size>0
      conditions[0] += " AND ("
      for attribute in options[:attributes]
        for word in keywords
          conditions[0] += attribute.to_s+"::text ILIKE ? OR "
          conditions << '%'+word+'%'
        end
      end 
      conditions[0] = conditions[0][0..-5]+")"
    else
      conditions[0] += " AND false"
    end
    conditions
  end

  def find_and_check(model, id, options={})
    model = model.to_s
    record = model.classify.constantize.find_by_id_and_company_id(id, @current_company.id)
    if record.blank?
      flash[:error] = l(:unavailable, model.to_sym)
      redirect_to :action=>options[:url]||model.pluralize
    end
    record
  end

  private
  
  def authorize
    session[:help_history] = [] if session[:help_history].nil?
    help_search(self.controller_name+'-'+self.action_name) if session[:help] and self.controller_name!='help'
    begin
      User.current_user = User.find_by_id(session[:user_id])
      @current_user = User.current_user
      @current_company = @current_user.company
      session[:actions] = @current_user.role.actions_array
      if session[:last_query].to_i<Time.now.to_i-session[:expiration]
        flash[:error] = lc :expired_session
        if controller_name.to_s!='authentication'
          session[:last_controller] = controller_name 
          session[:last_action]     = action_name
        end
        redirect_to_login
      else
        session[:last_query] = Time.now.to_i
        if request.get?
          session[:history] = [] if session[:history].nil?
          if session[:history][0] != request.url
            10.times{|i| session[:history][i+1] = session[:history][i]}
            session[:history][0] = request.url
          end
        end
      end
    rescue
      reset_session
      redirect_to_login
    end
  end
  
  def help_search(id)
    @id = id
    session[:help_history] << @id if @id != session[:help_history].last
    session[:help]=true
  end

  def redirect_to_login
    redirect_to :controller=>:authentication, :action=>:login
  end
  
  def redirect_to_back
    if session[:history][1]
      redirect_to session[:history][1]
    else
      redirect_to :back
    end
  end

  def can_access?(action=:all)
    return false unless @current_user
    return session[:actions].include?(:all) ? true : session[:actions].include?(action)
  end
  
  def access(action=:all)
    if @current_user
      unless can_access?(action)
        flash[:error]=lc :access_denied
        redirect_to :back
      end
    else
      redirect_to_login unless @current_user
    end
  end
  
end
