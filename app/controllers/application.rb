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
    mode    = a[a.size-1].to_sym
    partial = a[0..a.size-2].join('_')+'_form'
    @options = {:partial=>partial, :submit=>mode, :title=>:title}.merge(options)
    begin
      render :template=>'shared/formalize'
#      render :text=>ApplicationHelper::formalize(options), :layout=>true
    rescue ActionController::DoubleRenderError
    end
  end  
  
  # this function tries to find the file matching to the ID passing in parameter and launches a download of it. 
  def retrieve_xil(xil,options={})
    # the document is archived except the archive option is unmentioned
    unless options[:archive].false?
      template = Template.find(xil).content
      Report.find(:all, :conditions=>['key = ?', options[:key]])||false 
    end
  end
  

  private
  
  def authorize
    begin
      User.current_user = User.find_by_id(session[:user_id])
      @current_user = User.current_user
      @current_company = @current_user.company
      session[:actions] = @current_user.role.actions_array
      if session[:last_query].to_i<Time.now.to_i-3600
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
