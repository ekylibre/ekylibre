# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  before_filter :authorize, :except=>:login

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '232b3ccf31f8f5fefcbb9d2ac3a00415'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password


  private
  
  def authorize
    if session[:user_id].blank?
      redirect_to :controller=>:authentication, :action=>:login
    else
      User.current_user = User.find(session[:user_id])
      if session[:last_query].to_i+3600<Time.now.to_i
        flash[:error] = lc :expired_session
        redirect_to :controller=>:authentication, :action=>:login
      else
        session[:last_query] = Time.now.to_i
      end
      #    Company.current_company = User.current_user.nil? ? nil : User.current_user.company
    end
  end

end
