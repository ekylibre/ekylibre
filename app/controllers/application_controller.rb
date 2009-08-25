# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  before_filter :authorize, :except=>[:login, :logout, :register]
  attr_accessor :current_user
  attr_accessor :current_company
  # after_filter :reset_stamper

  # def reset_stamper
  #    User.reset_stamper
  #  end

  include Userstamp
  
  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  # protect_from_forgery # :secret => '232b3ccf31f8f5fefcbb9d2ac3a00415'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password").  
  # filter_parameter_logging :password

  def accessible?(url={})
    if url.is_a?(Hash)
      url[:controller]||=controller_name 
      url[:action]||=:index
    end
    if @current_user
      raise Exception.new(url.inspect) if url[:controller].blank? or url[:action].blank?
      #if @current_user.admin or session[:rights].include?((User.rights[url[:controller].to_sym]||{})[url[:action].to_sym])
      if @current_user.authorization(session[:rights], url[:controller], url[:action]).nil?
        true
      else
        false
      end
    else
      true
    end
  end
  
  protected  
  
  def render_form(options={})
    a = action_name.split '_'
    @operation    = a[-1].to_sym
    @partial = options[:partial]||a[0..-2].join('_')+'_form'
    @options = options
    begin
      render :template=>options[:template]||'shared/form_'+@operation.to_s
    rescue ActionController::DoubleRenderError
    end
  end


  def self.search_conditions(model_name, columns)
    model = model_name.to_s.classify.constantize
    columns = [columns] if [String, Symbol].include? columns.class 
    columns = columns.collect{|k,v| v.collect{|x| "#{k}.#{x}"}} if columns.is_a? Hash
    columns.flatten!
    raise Exception.new "Bad columns: "+columns.inspect unless columns.is_a? Array
    code = ""
    code+="c=['#{model.table_name}.company_id=?', @current_company.id]\n"
    code+="session[:#{model.name.underscore}_key].to_s.lower.split(/\\s+/).each{|kw| kw='%'+kw+'%';"
    code+="c[0]+=' AND (#{columns.collect{|x| 'LOWER(CAST('+x.to_s+' AS VARCHAR)) LIKE ?'}.join(' OR ')})';c+=[#{(['kw']*columns.size).join(',')}]}\n"
    code+="c"
    code
  end


  def search_conditions(options={})
    conditions = ["company_id = ?", @current_company.id]
    keywords = options[:key].to_s.split(" ")
    if keywords.size>0 and options[:attributes].size>0
      conditions[0] += " AND ("
      for attribute in options[:attributes]
        for word in keywords
          conditions[0] += 'LOWER(CAST('+attribute.to_s+" AS VARCHAR)) LIKE ? OR "
          conditions << '%'+word.lower+'%'
        end
      end 
      conditions[0] = conditions[0][0..-5]+")"
    else
      conditions[0] += " AND CAST ('true' AS BOOLEAN)"
    end
    conditions
  end

  def find_and_check(model, id, options={})
    model = model.to_s
    record = model.classify.constantize.find_by_id_and_company_id(id, @current_company.id)
    if record.nil?
      flash[:error] = tg("unavailable.#{model.to_s}", :value=>id)
      redirect_to_back # :action=>options[:url]||model.pluralize
    end
    record
  end

  private
  
  def authorize()
    session[:help_history] ||= []
    if request.get? and not request.xhr? and not [:authentication, :help].include?(controller_name.to_sym)
      session[:last_url] = request.url
    end
    help_search(self.controller_name+'-'+self.action_name) if session[:help] and not [:authentication, :help, :search].include?(controller_name.to_sym)

    session[:last_query] ||= 0
    session[:expiration] ||= 0
    if session[:last_query].to_i<Time.now.to_i-session[:expiration]
      flash[:error] = tc :expired_session
      redirect_to_login
      return
    else
      session[:last_query] = Time.now.to_i
      if request.get? and not request.xhr?
        if request.url == session[:history][1]
          session[:history].delete_at(0)
        elsif request.url != session[:history][0]
          session[:history].insert(0,request.url)
          session[:history].delete_at(127)
        end
      end
    end

    # Load @current_user and @current_company
    @current_user = User.find_by_id(session[:user_id]) # User.current_user
    unless @current_user
      redirect_to_login 
      return
    end
    @current_company = @current_user.company
    # User.stamper = @current_user

    # Check rights before allowing access
    message = @current_user.authorization(session[:rights], controller_name, action_name)
    if message
      flash[:error] = message+request.url.inspect
      redirect_to_back unless @current_user.admin
    end
  end

  def help_search(article)
    @article = article
    session[:help_history] << @article if @article != session[:help_history].last
    session[:help]=true
  end


  def print(object, options={})
    if @current_company
      options[:view] = self
      filename = options.delete(:filename)
      filename += '.pdf' if filename and not filename.to_s.match(/\./)
      result = @current_company.print(object, options)
      if result.is_a? Document
        send_file(result.file_path, :type=>Mime::PDF, :disposition=>'inline', :filename=>filename||result.original_name)
      else
        send_data(result, :type=>Mime::PDF, :disposition=>'inline', :filename=>filename)
      end
    end
  end

  def redirect_to_login()
    reset_session
    session[:help] = false
    redirect_to :controller=>:authentication, :action=>:login
  end
  
  def redirect_to_back(options={})
    if session[:history] and session[:history][1]
      session[:history].delete_at(0)
      redirect_to session[:history][0], options
    elsif request.referer
      redirect_to request.referer, options
    else
      redirect_to_login
    end
  end

  def redirect_to_current()
    redirect_to session[:history][0]
  end

end
