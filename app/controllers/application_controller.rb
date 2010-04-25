# == License
# Ekylibre - Simple ERP
# Copyright (C) 2009 Brice Texier, Thibaud Mérigon
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  before_filter :i18nize, :except=>[:i18nize]
  before_filter :authorize, :except=>[:login, :logout, :register, :i18nize]
  attr_accessor :current_user
  attr_accessor :current_company
  layout :xhr_or_not

  include Userstamp
  include ExceptionNotifiable
  local_addresses.clear

  for k, v in EKYLIBRE_REFERENCES
    for c, t in v
      raise Exception.new("#{k}.#{c} is not filled.") if t.blank?
      t.to_s.classify.constantize if t.is_a? Symbol
    end
  end

  ActiveRecord::Base.connection.execute("UPDATE document_templates SET nature='balance_sheet' WHERE nature='financialyear' AND code LIKE 'BILAN%'")
  ActiveRecord::Base.connection.execute("UPDATE document_templates SET nature='income_statement' WHERE nature='financialyear'")
  # ActiveRecord::Base.connection.execute("UPDATE document_templates SET source=REPLACE(source, 'employee', 'responsible'), cache=REPLACE(cache, 'employee', 'responsible')")
  
  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  # protect_from_forgery # :secret => '232b3ccf31f8f5fefcbb9d2ac3a00415'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password").  
  # filter_parameter_logging :password


  def accessible?(url={})
    #puts url.inspect
    if url.is_a?(Hash)
      url[:controller]||=controller_name 
      url[:action]||=:index
    end
    if @current_user
      raise Exception.new(url.inspect) if url[:controller].blank? or url[:action].blank?
      if @current_user.authorization(url[:controller], url[:action], session[:rights]).nil?
        true
      else
        false
      end
    else
      true
    end
  end


  def i18nize
    locale = params[:locale]
    if locale.is_a? String
      if locale.size == 3
        if ::I18n.active_locales.include?(locale.to_sym)
          session[:locale] = locale.to_sym
        end
      end
    end
    # Initialize locale
    session[:locale] ||= ::I18n.locale
    ::I18n.locale = session[:locale]
    if action_name.to_s == "i18nize"
      if request.xhr?
        render :text=>'' 
      else
        redirect_to_current
      end
    end
  end


  
  protected  
  
  def render_form(options={})
    a = action_name.split '_'
    @_operation  = a[-1].to_sym
    @partial = options[:partial]||a[0..-2].join('_')+'_form'
    @options = options
    begin
      render :template=>options[:template]||'shared/form_'+@_operation.to_s
    rescue ActionController::DoubleRenderError
    end
  end


  def self.search_conditions(model_name, columns)
    model = model_name.to_s.classify.constantize
    columns = [columns] if [String, Symbol].include? columns.class 
    columns = columns.collect{|k,v| v.collect{|x| "#{k}.#{x}"}} if columns.is_a? Hash
    columns.flatten!
    raise Exception.new("Bad columns: "+columns.inspect) unless columns.is_a? Array
    code = ""
    code+="c=['#{model.table_name}.company_id=?', @current_company.id]\n"
    code+="session[:#{model.name.underscore}_key].to_s.lower.split(/\\s+/).each{|kw| kw='%'+kw+'%';"
    # This line is incompatible with MySQL...
    # code+="c[0]+=' AND (#{columns.collect{|x| 'LOWER(CAST('+x.to_s+' AS TEXT)) LIKE ?'}.join(' OR ')})';c+=[#{(['kw']*columns.size).join(',')}]}\n"
    if ActiveRecord::Base.connection.adapter_name == "MySQL"
      code+="c[0]+=' AND ("+columns.collect{|x| 'LOWER(CAST('+x.to_s+' AS CHAR)) LIKE ?'}.join(' OR ')+")';\n"
    else
      code+="c[0]+=' AND ("+columns.collect{|x| 'LOWER(CAST('+x.to_s+' AS VARCHAR)) LIKE ?'}.join(' OR ')+")';\n"
    end
    code+="c+=[#{(['kw']*columns.size).join(',')}]"
    code+="}\n"
    code+="c"
    code
  end


  def find_and_check(model, id=nil, options={})
    model = model.to_s
    id ||= params[:id]
    klass = model.classify.constantize
    record = klass.find_by_id_and_company_id(id.to_s.to_i, @current_company.id)
    if record.nil?
      notify(:unavailable_model, :error, :model=>klass.human_name, :id=>id)
      redirect_to_back
    end
    record
  end

  def save_and_redirect(record, options={})
    url = options[:url] || :back
    record.attributes = options[:attributes] if options[:attributes]
    if record.save or options[:saved]
      if params[:dialog]
        render :json=>{:id=>record.id}, :status=>250
      else
        # TODO: notif
        if url == :back
          redirect_to_back
        else
          if url.is_a? Hash
            url0 = {}
            url.each{|k,v| url0[k] = (v.is_a?(String) ? record.send(v) : v)}
            url = url0
          end
          redirect_to(url) 
        end
      end
    end
  end

  # For title I18n : t3e :)
  def t3e(*args)
    @title ||= {}
    for arg in args
      raise ArgumentError.new("Hash expected, got #{arg.class.name}:#{arg.inspect}") unless arg.is_a? Hash
      arg.each do |k,v| 
        @title[k.to_sym] = if [Date, DateTime, Time].include? v.class
                             ::I18n.localize(v)
                           else
                             v
                           end
      end
    end
  end


  def notify(message, nature=:information, mode=:next, options={})
    options = mode if mode.is_a? Hash
    mode = :now if nature == :now
    nature = :information if !nature.is_a? Symbol or nature == :now
    notistore = ((mode==:now or nature==:now) ? flash.now : flash)
    notistore[:notifications] = {} unless notistore[:notifications].is_a? Hash
    notistore[:notifications][nature] = [] unless notistore[:notifications][nature].is_a? Array
    notistore[:notifications][nature] << ::I18n.t("notifications."+message.to_s, options)
  end
 
  def has_notifications?(nature=nil)
    return false unless flash[:notifications].is_a? Hash
    if nature.nil?
      for nature, messages in flash[:notifications]
        return true if messages.size > 0
      end
    elsif flash[:notifications][nature].is_a?(Array)
      return true if flash[:notifications][nature].size > 0
    end
    return false
  end



  private

  def xhr_or_not()
    (request.xhr? ? "dialog" : "application")
  end
 
  def historize()
    if request.url == session[:history][1]
      session[:history].delete_at(0)
    elsif request.url != session[:history][0]
      session[:history].insert(0,request.url)
      session[:history].delete_at(127)
    end
    session[:last_page][self.controller_name] = request.url unless (request.url.match(/_(print|dyta|extract)(\/\d+(\.\w+)?)?$/) or (controller_name == "company" and action_name == "print")) or params[:format] 
  end
  



  def authorize()
    response.headers["Last-Modified"] = Time.now.httpdate
    response.headers["Expires"] = '0'
    # HTTP 1.0
    response.headers["Pragma"] = "no-cache"
    # HTTP 1.1 'pre-check=0, post-check=0' (IE specific)
    response.headers["Cache-Control"] = 'no-store, no-cache, must-revalidate, max-age=0, pre-check=0, post-check=0'

    session[:last_page] ||= {}
    session[:help_history] ||= []
    if request.get? and not request.xhr? and not [:authentication, :help].include?(controller_name.to_sym)
      session[:last_url] = request.url
    end
    help_search(self.controller_name+'-'+self.action_name) if session[:help] and not [:authentication, :help, :search].include?(controller_name.to_sym)

    if !session[:last_query].is_a?(Integer)
      redirect_to_login
      return
    elsif session[:last_query].to_i<Time.now.to_i-session[:expiration]
      notify(:expired_session)
      if request.xhr?
        render :text=>"<script>window.location.replace('#{url_for(:controller=>:authentication, :action=>:login)}')</script>"
      else
        redirect_to_login
      end
      return
    else
      session[:last_query] = Time.now.to_i
      historize if request.get? and not request.xhr?
    end

    # Load @current_user and @current_company
    @current_user = User.find_by_id(session[:user_id]) # User.current_user
    unless @current_user
      redirect_to_login 
      return
    end
    @current_company = @current_user.company
    # User.stamper = @current_user

    # TODO: Dynamic theme choosing
    @current_theme = "tekyla"

    # Check rights before allowing access
    message = @current_user.authorization(controller_name, action_name, session[:rights])
    if message
      notify(:access_denied, :error, :reason=>message, :url=>request.url.inspect)
      redirect_to_back unless @current_user.admin
    end
  end

  def help_search(article)
    @article = article
    session[:help_history] << @article if @article != session[:help_history].last
    session[:help]=true
  end

  def redirect_to_login()
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





  # Build standard actions to manage records of a model
  def self.manage(name, defaults={})
    operations = [:create, :update, :delete]

    t3e = defaults.delete(:t3e)
    url = defaults.delete(:redirect_to)
    record_name = name.to_s.singularize
    model = name.to_s.singularize.classify.constantize
    code = ''
    methods_prefix = record_name
    
    if operations.include? :create
      code += "def #{methods_prefix}_create\n"
      code += "  if request.post?\n"
      code += "    @#{record_name} = #{model.name}.new(params[:#{record_name}])\n"
      code += "    @#{record_name}.company_id = @current_company.id\n"
      code += "    return if save_and_redirect(@#{record_name}#{',  :url=>'+url if url})\n"
      code += "  else\n"
      values = defaults.collect{|k,v| ":#{k}=>(#{v})"}.join(", ")
      code += "    @#{record_name} = #{model.name}.new(#{values})\n"
      code += "  end\n"
      code += "  render_form\n"
      code += "end\n"
    end
    
    if operations.include? :update
      # this action updates an existing record with a form.
      code += "def #{methods_prefix}_update\n"
      code += "  return unless @#{record_name} = find_and_check(:#{record_name})\n"
      code += "  if request.post? or request.put?\n"
      raise Exception.new("You must put :company_id in attr_readonly of #{model.name}") if model.readonly_attributes.nil? or not model.readonly_attributes.include?("company_id")
      code += "    @#{record_name}.attributes = params[:#{record_name}]\n"
      code += "    return if save_and_redirect(@#{record_name}#{', :url=>('+url+')' if url})\n"
      code += "  end\n"
      code += "  t3e(@#{record_name}.attributes"+(t3e ? ".merge("+t3e.collect{|k,v| ":#{k}=>(#{v})"}.join(", ")+")" : "")+")\n"
      code += "  render_form\n"
      code += "end\n"
    end

    if operations.include? :delete
      # this action deletes or hides an existing record.
      code += "def #{methods_prefix}_delete\n"
      code += "  return unless @#{record_name} = find_and_check(:#{record_name})\n"
      code += "  if request.delete? or request.post?\n"
      if model.instance_methods.include?("destroyable?")
        code += "    if @#{record_name}.destroyable?\n"
        code += "      #{model.name}.destroy(@#{record_name}.id)\n"
        code += "      notify(:record_has_been_correctly_removed, :success)\n"
        code += "    else\n"
        code += "      notify(:record_cannot_be_removed, :error)\n"
        code += "    end\n"
      else
        code += "    #{model.name}.destroy(@#{record_name}.id)\n"
        code += "    notify(:record_has_been_correctly_removed, :success)\n"        
      end
      code += "  else\n"
      code += "    notify(:record_has_not_been_removed, :error)\n"
      code += "  end\n"
      code += "  redirect_to_current\n"
      code += "end\n"
    end

    # list = code.split("\n"); list.each_index{|x| puts((x+1).to_s.rjust(4)+": "+list[x])}
    
    class_eval(code)
    
  end




end
