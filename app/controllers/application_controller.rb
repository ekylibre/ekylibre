# == License
# Ekylibre - Simple ERP
# Copyright (C) 2009 Brice Texier, Thibaud Merigon
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

class ApplicationController < ActionController::Base
  # helper :all # include all helpers, all the time
  before_filter :i18nize
  before_filter :authorize
  attr_accessor :current_user
  attr_accessor :current_company
  layout :xhr_or_not
  

  include Userstamp
  # include ExceptionNotifiable
  # local_addresses.clear

  for k, v in Ekylibre.references
    for c, t in v
      raise Exception.new("#{k}.#{c} is not filled.") if t.blank?
      t.to_s.classify.constantize if t.is_a? Symbol
    end
  end

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

  def self.authorized?(url={})
    if url.is_a?(Hash)
      url[:controller]||=controller_name 
      url[:action]||=:index
    end
    if @current_user
      raise Exception.new("Uncheckable URL: "+url.inspect) if url[:controller].blank? or url[:action].blank?
      if @current_user.authorization(url[:controller], url[:action], session[:rights]).nil?
        true
      else
        false
      end
    else
      true
    end
  end


  # Initialize locale
  def i18nize()
    if (locale = params[:locale].to_s).size == 3
      session[:locale] = locale.to_sym if ::I18n.active_locales.include?(locale.to_sym)
    elsif not session[:locale] and not request.env["HTTP_ACCEPT_LANGUAGE"].blank?
      codes = {}
      for l in ::I18n.active_locales
        codes[::I18n.translate("i18n.iso2", :locale=>l).to_s] = l
      end
      session[:locale] = codes[request.env["HTTP_ACCEPT_LANGUAGE"].to_s.split(/[\,\;]+/).select{|x| !x.match(/^q\=/)}.detect{|x| codes[x[0..1]]}[0..1]]
    end
    session[:locale] ||= ::I18n.locale||::I18n.default_locale
    ::I18n.locale = session[:locale]
  end



  def default_url_options(options={})
    options.merge(:company =>(params ? params[:company] : @company ? @company.name : nil))
  end


  
  protected  

  #   # 1 Session by company
  #   def sessany
  #     return (@current_company ? session[@current_company.code] ||= {} : session)
  #   end

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


  def render_restfully_form(options={})
    @_operation = action_name.to_sym
    @_operation = (@_operation==:create ? :new : @_operation==:update ? :edit : @_operation)
    @partial    = options[:partial]||'form'
    @options    = options
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

  def self.light_search_conditions(search={}, options={})
    conditions = options[:conditions] || 'c'
    options[:except] ||= []
    options[:filters] ||= {}
    variable ||= options[:variable] || "params[:q]"
    tables = search.keys.select{|t| !options[:except].include? t}
    code = "#{conditions} = ['"+tables.collect{|t| "#{t}.company_id=?"}.join(' AND ')+"'"+", @current_company.id"*tables.size+"]\n"
    columns = search.collect{|t, cs| cs.collect{|c| "#{t}.#{c}"}}.flatten
    code += "for kw in #{variable}.to_s.lower.split(/\\s+/)\n"
    code += "  kw = '%'+kw+'%'\n"
    filters = columns.collect do |x| 
      # This line is incompatible with MySQL...
      if ActiveRecord::Base.connection.adapter_name == "MySQL"
        'LOWER(CAST('+x.to_s+' AS CHAR)) LIKE ?'
      else
        'LOWER(CAST('+x.to_s+' AS VARCHAR)) LIKE ?'
      end
    end
    values = '['+(['kw']*columns.size).join(', ')+']'
    for k, v in options[:filters]
      filters << k
      v = '['+v.join(', ')+']' if v.is_a? Array
      values += "+"+v
    end
    code += "  #{conditions}[0] += ' AND (#{filters.join(' OR ')})'\n"
    code += "  #{conditions} += #{values}\n"
    code += "end\n"
    code += "#{conditions}"
    return code
  end


  def find_and_check(model, id=nil, options={})
    model, record, klass = model.to_s, nil, nil
    id ||= params[:id]
    begin
      klass = model.to_s.classify.constantize
      record = klass.find_by_id_and_company_id(id.to_s.to_i, @current_company.id)
    rescue
      notify(:unavailable_model, :error, :model=>model.inspect, :id=>id)
      redirect_to_back
      return false
    end
    if record.nil?
      notify(:unavailable_model, :error, :model=>klass.model_name.human, :id=>id)
      redirect_to_back
    end
    return record
  end

  def save_and_redirect(record, options={})
    url = options[:url] || :back
    record.attributes = options[:attributes] if options[:attributes]
    if record.send(:save) or options[:saved]
      if params[:dialog]
        render :json=>{:id=>record.id}
      else
        # TODO: notif
        if url == :back
          redirect_to_back
        else
          record.reload
          if url.is_a? Hash
            url0 = {}
            url.each{|k,v| url0[k] = (v.is_a?(String) ? record.send(v) : v)}
            url = url0
          end
          redirect_to(url) 
        end
      end
      return true
    end
    return false
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
                             v.to_s
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

  protected

  #   def current_user
  #     @current_user || User.find_by_id(session[:user_id])
  #   end

  private

  def xhr_or_not()
    (request.xhr? ? "dialog" : "application")
  end
  
  def historize()
    unless (request.url.match(/_(print|create_kame|extract)(\/\d+(\.\w+)?)?$/) or (controller_name.to_s == "company" and ["print", "configure"].include?(action_name.to_s))) or params[:format] or controller_name.to_s == "sessions"
      if request.url == session[:history][1]
        session[:history].delete_at(0)
      elsif request.url != session[:history][0]
        session[:history].insert(0,request.url)
        session[:history].delete_at(127)
      end
    end
    unless (request.url.match(/_(print|create_kame|extract|create|update)(\/\d+(\.\w+)?)?$/) or (controller_name.to_s == "company" and ["print", "configure"].include?(action_name.to_s))) or params[:format] 
      session[:last_page][self.controller_name] = request.url
    end
  end
  


  # Controls access to every view in Ekylibre. 
  def authorize()
    # Change headers to force zero cache
    response.headers["Last-Modified"] = Time.now.httpdate
    response.headers["Expires"] = '0'
    # HTTP 1.0
    response.headers["Pragma"] = "no-cache" 
    # HTTP 1.1 'pre-check=0, post-check=0' (IE specific)
    response.headers["Cache-Control"] = 'no-store, no-cache, must-revalidate, max-age=0, pre-check=0, post-check=0'

    # Load current_user if connected
    @current_user = User.find_by_id(session[:user_id]) if session[:user_id]
    
    # Load current_company if possible
    @current_company = Company.find_by_code(params[:company])
    if @current_user and @current_company and @current_company.id!=@current_user.company_id
      notify(:unknown_company, :error) unless params[:company].blank?
      return redirect_to_login
    end

    # Get action rights
    raise Exception.new("Controller #{controller_name.to_sym} is called but it has no actions or is undefined in #{User.rights_file}") unless controller_rights = User.rights[controller_name.to_sym]
    action_rights = controller_rights[action_name.to_sym]||[]

    # Returns if action is public
    return true if action_rights.include?(:__public__)

    # Check current_user
    unless @current_user
      notify(:access_denied, :error, :reason=>"NOT PUBLIC", :url=>request.url.inspect)
      return redirect_to_login
    end

    # Check current_company
    if not @current_company or @current_company.id!=@current_user.company_id
      notify(:unknown_company, :error) unless params[:company].blank?
      return redirect_to_login
    end

    # Set session variables and check state
    session[:last_page] ||= {}
    session[:help_history] ||= []
    if request.get? and not request.xhr? and not [:sessions, :help].include?(controller_name.to_sym)
      session[:last_url] = request.url
    end
    @article = "#{self.controller_name}-#{self.action_name}"
    session[:help_history] << @article if session[:side] and @article != session[:help_history].last
    # TODO: Dynamic theme choosing
    @current_theme = "tekyla"
    if params[:resized]
      preference = @current_user.preference("interface.general.resized", true, :boolean)
      preference.value = (params[:resized] == "1" ? true : false)
      preference.save!
    end
    # Check expiration
    if !session[:last_query].is_a?(Integer)
      redirect_to_login(request.url)
      return false
    elsif session[:last_query].to_i<Time.now.to_i-session[:expiration].to_i
      notify(:expired_session)
      if request.xhr?
        render :text=>"<script>window.location.replace('#{new_session_url}')</script>"
      else
        redirect_to_login(request.url)
      end
      return
    else
      session[:last_query] = Time.now.to_i
      historize if request.get? and not request.xhr?
    end

    # Check access for registered actions
    return true if action_rights.include?(:__minimum__)

    # Check rights before allowing access
    if message = @current_user.authorization(controller_name, action_name, session[:rights])
      notify(:access_denied, :error, :reason=>message, :url=>request.url.inspect)
      redirect_to_back unless @current_user.admin
    end
  end

  # def help_search(article)
  #   @article = article
  #   session[:help_history] << @article if @article != session[:help_history].last
  #   session[:help]=true
  # end

  def redirect_to_login(url=nil)
    reset_session
    @current_user = nil
    session[:help] = false
    redirect_to(new_session_url(:url=>url, :company=>params[:company]))
  end
  
  def redirect_to_back(options={})
    if session[:history] and session[:history][1]
      # session[:history].delete_at(0)
      redirect_to session[:history][1], options
    elsif request.referer and request.referer != request.url
      redirect_to request.referer, options
    else
      redirect_to :controller=>:dashboards
    end
  end

  def redirect_to_current()
    if session[:history].is_a?(Array) and session[:history][0]
      redirect_to session[:history][0]
    else
      redirect_to_back
    end
  end

 
  def init_session(user)
    reset_session
    session[:expiration]   = 3600*5
    session[:help]         = false # user.preference("interface.help.opened", true, :boolean).value
    session[:help_history] = []
    session[:history]      = []
    session[:last_page]    = {}
    session[:last_query]   = Time.now.to_i
    session[:rights]       = user.rights.to_s.split(" ").collect{|x| x.to_sym}
    session[:side]         = true
    session[:user_id]      = user.id
    # Build and cache customized menu for all the session
    session[:menus] = ActiveSupport::OrderedHash.new
    for menu, submenus in Ekylibre.menus
      fsubmenus = ActiveSupport::OrderedHash.new
      for submenu, menuitems in submenus
        fmenuitems = menuitems.select{|url| self.class.authorized?(url)}
        fsubmenus[submenu] = fmenuitems unless fmenuitems.size.zero?
      end
      session[:menus][menu] = fsubmenus unless fsubmenus.keys.size.zero?
    end
  end

  # Build standard actions to manage records of a model
  def self.manage(name, defaults={})
    operations = [:create, :update, :delete]

    t3e = defaults.delete(:t3e)
    url = defaults.delete(:redirect_to)
    partial = defaults.delete(:partial)
    partial =  ":partial=>'#{partial}'" if partial
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
      code += "  render_form #{partial}\n"
      code += "end\n"
    end
    
    if operations.include? :update
      # this action updates an existing record with a form.
      code += "def #{methods_prefix}_update\n"
      code += "  return unless @#{record_name} = find_and_check(:#{record_name})\n"
      code += "  t3e(@#{record_name}.attributes"+(t3e ? ".merge("+t3e.collect{|k,v| ":#{k}=>(#{v})"}.join(", ")+")" : "")+")\n"
      code += "  if request.post? or request.put?\n"
      raise Exception.new("You must put :company_id in attr_readonly of #{model.name}") if model.readonly_attributes.nil? or not model.readonly_attributes.include?("company_id")
      code += "    @#{record_name}.attributes = params[:#{record_name}]\n"
      code += "    return if save_and_redirect(@#{record_name}#{', :url=>('+url+')' if url})\n"
      code += "  end\n"
      code += "  render_form #{partial}\n"
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

  # Build standard actions to manage records of a model
  def self.manage_list(name, order_by=:id)
    operations = [:up, :down]

    record_name = name.to_s.singularize
    model = name.to_s.singularize.classify.constantize

    raise ArgumentError.new("Unknown column for #{model.name}") unless model.columns_hash[order_by.to_s]
    code = ''
    methods_prefix = record_name
    
    sort = ""
    #     sort += "items = #{model.name}.find(:all, :conditions=>['#{model.scope_condition}'], :order=>'#{model.position_column}, #{order_by}')\n"
    #     sort += "items.times do |x|\n"
    #     sort += "  #{model.name}.update_all({:#{model.position_column}=>x}, {:id=>items[x].id})\n"
    #     sort += "end\n"
    
    if operations.include? :up
      # this action deletes or hides an existing record.
      code += "def #{methods_prefix}_up\n"
      code += "  return unless #{record_name} = find_and_check(:#{record_name})\n"
      code += "  if request.post?\n"
      code += sort.gsub(/^/, "    ")
      code += "    #{record_name}.move_higher\n"
      code += "  end\n"
      code += "  redirect_to_current\n"
      code += "end\n"
    end

    if operations.include? :down
      # this action deletes or hides an existing record.
      code += "def #{methods_prefix}_down\n"
      code += "  return unless #{record_name} = find_and_check(:#{record_name})\n"
      code += "  if request.post?\n"
      code += sort.gsub(/^/, "    ")
      code += "    #{record_name}.move_lower\n"
      code += "  end\n"
      code += "  redirect_to_current\n"
      code += "end\n"
    end

    # list = code.split("\n"); list.each_index{|x| puts((x+1).to_s.rjust(4)+": "+list[x])}
    
    class_eval(code)
    
  end














  # Build standard RESTful actions to manage records of a model
  def self.manage_restfully(defaults={})
    name = controller_name
    t3e = defaults.delete(:t3e)
    url = defaults.delete(:redirect_to)
    partial = defaults.delete(:partial)
    partial =  ":partial=>'#{partial}'" if partial
    record_name = name.to_s.singularize
    model = name.to_s.singularize.classify.constantize
    code = ''
    
    code += "def new\n"
    values = defaults.collect{|k,v| ":#{k}=>(#{v})"}.join(", ")
    code += "  @#{record_name} = #{model.name}.new(#{values})\n"
    code += "  render_restfully_form #{partial}\n"
    code += "end\n"

    code += "def create\n"
    code += "  @#{record_name} = #{model.name}.new(params[:#{record_name}])\n"
    code += "  @#{record_name}.company_id = @current_company.id\n"
    code += "  return if save_and_redirect(@#{record_name}#{',  :url=>'+url if url})\n"
    code += "  render_restfully_form #{partial}\n"
    code += "end\n"

    # this action updates an existing record with a form.
    code += "def edit\n"
    code += "  return unless @#{record_name} = find_and_check(:#{record_name})\n"
    code += "  t3e(@#{record_name}.attributes"+(t3e ? ".merge("+t3e.collect{|k,v| ":#{k}=>(#{v})"}.join(", ")+")" : "")+")\n"
    code += "  render_restfully_form #{partial}\n"
    code += "end\n"

    code += "def update\n"
    code += "  return unless @#{record_name} = find_and_check(:#{record_name})\n"
    code += "  t3e(@#{record_name}.attributes"+(t3e ? ".merge("+t3e.collect{|k,v| ":#{k}=>(#{v})"}.join(", ")+")" : "")+")\n"
    raise Exception.new("You must put :company_id in attr_readonly of #{model.name}") if model.readonly_attributes.nil? or not model.readonly_attributes.include?("company_id")
    code += "  @#{record_name}.attributes = params[:#{record_name}]\n"
    code += "  return if save_and_redirect(@#{record_name}#{', :url=>('+url+')' if url})\n"
    code += "  render_restfully_form #{partial}\n"
    code += "end\n"

    # this action deletes or hides an existing record.
    code += "def destroy\n"
    code += "  return unless @#{record_name} = find_and_check(:#{record_name})\n"
    if model.instance_methods.include?("destroyable?")
      code += "  if @#{record_name}.destroyable?\n"
      code += "    #{model.name}.destroy(@#{record_name}.id)\n"
      code += "    notify(:record_has_been_correctly_removed, :success)\n"
      code += "  else\n"
      code += "    notify(:record_cannot_be_removed, :error)\n"
      code += "  end\n"
    else
      code += "  #{model.name}.destroy(@#{record_name}.id)\n"
      code += "  notify(:record_has_been_correctly_removed, :success)\n"        
    end
    code += "  redirect_to #{model.name.underscore.pluralize}_url\n"
    code += "end\n"

    # list = code.split("\n"); list.each_index{|x| puts((x+1).to_s.rjust(4)+": "+list[x])}    
    class_eval(code)
  end


  # Build standard actions to manage records of a model
  def self.manage_restfully_list(order_by=:id)
    name = controller_name
    record_name = name.to_s.singularize
    model = name.to_s.singularize.classify.constantize

    raise ArgumentError.new("Unknown column for #{model.name}") unless model.columns_hash[order_by.to_s]
    code = ''
    
    sort = ""
    #     sort += "items = #{model.name}.find(:all, :conditions=>['#{model.scope_condition}'], :order=>'#{model.position_column}, #{order_by}')\n"
    #     sort += "items.times do |x|\n"
    #     sort += "  #{model.name}.update_all({:#{model.position_column}=>x}, {:id=>items[x].id})\n"
    #     sort += "end\n"
    
    code += "def up\n"
    code += "  return unless #{record_name} = find_and_check(:#{record_name})\n"
    code += sort.gsub(/^/, "  ")
    code += "  #{record_name}.move_higher\n"
    code += "  redirect_to_current\n"
    code += "end\n"
    
    code += "def down\n"
    code += "  return unless #{record_name} = find_and_check(:#{record_name})\n"
    code += sort.gsub(/^/, "  ")
    code += "  #{record_name}.move_lower\n"
    code += "  redirect_to_current\n"
    code += "end\n"

    # list = code.split("\n"); list.each_index{|x| puts((x+1).to_s.rjust(4)+": "+list[x])}
    
    class_eval(code)
  end

  # accountancy -> account_reconciliation_conditions
  def self.account_reconciliation_conditions
    code  = search_conditions(:accounts, :accounts=>[:name, :number, :comment], :journal_entries=>[:number], JournalEntryLine.table_name=>[:name, :debit, :credit])+"[0] += ' AND accounts.reconcilable = ?'\n"
    code += "c << true\n"
    code += "c[0] += ' AND "+JournalEntryLine.connection.length(JournalEntryLine.connection.trim("COALESCE(letter, \\'\\')"))+" = 0'\n"
    code += "c"
    return code
  end

  # accountancy -> accounts_conditions
  def self.accounts_conditions
    code  = ""
    code += light_search_conditions(Account.table_name=>[:name, :number, :comment])
    code += "[0] += ' AND number LIKE ?'\n"
    code += "c << params[:prefix].to_s+'%'\n"
    code += "if params[:used_accounts].to_i == 1\n"
    code += "  c[0] += ' AND id IN (SELECT account_id FROM #{JournalEntryLine.table_name} AS jel JOIN #{JournalEntry.table_name} AS je ON (entry_id=je.id) WHERE '+JournalEntry.period_condition(params[:period], params[:started_on], params[:stopped_on], 'je')+' AND je.company_id = ? AND jel.company_id = ?)'\n"
    code += "  c += [@current_company.id, @current_company.id]\n"
    code += "end\n"
    code += "c\n"
    # list = code.split("\n"); list.each_index{|x| puts((x+1).to_s.rjust(4)+": "+list[x])}
    return code
  end

  # accountancy -> accounts_range_crit
  def self.accounts_range_crit(variable, conditions='c')
    variable = "session[:#{variable}]" unless variable.is_a? String
    code = ""
    # code += "ac, #{variable}[:accounts] = \n"
    code += "#{conditions}[0] += ' AND '+Account.range_condition(#{variable}[:accounts])\n"
    return code
  end

  # accountancy -> crit_params
  def self.crit_params(hash)
    nh = {}
    keys = JournalEntry.state_machine.states.collect{|s| s.name}
    keys += [:period, :started_on, :stopped_on, :accounts, :centralize]
    for k, v in hash
      nh[k] = hash[k] if k.to_s.match(/^(journal|level)_\d+$/) or keys.include? k.to_sym
    end
    return nh
  end

  # accountancy -> general_ledger_conditions
  def self.general_ledger_conditions(options={})
    conn = ActiveRecord::Base.connection
    code = ""
    code += "c=['journal_entries.company_id=?', @current_company.id]\n"
    code += journal_period_crit("params")
    code += journal_entries_states_crit("params")
    code += accounts_range_crit("params")
    code += journals_crit("params")
    code += "c\n"
    # list = code.split("\n"); list.each_index{|x| puts((x+1).to_s.rjust(4)+": "+list[x])}
    return code # .gsub(/\s*\n\s*/, ";")
  end

  # accountancy -> journal_entries_conditions
  def self.journal_entries_conditions(options={})
    code = ""
    search_options = {}
    filter = {JournalEntryLine.table_name => [:name, :debit, :credit]}
    unless options[:with_lines]
      code += light_search_conditions(filter, :conditions=>"cjel")+"\n"
      search_options[:filters] = {"#{JournalEntry.table_name}.id IN (SELECT entry_id FROM #{JournalEntryLine.table_name} WHERE '+cjel[0]+')"=>"cjel[1..-1]"}
      filter.delete(JournalEntryLine.table_name)
    end
    filter[JournalEntry.table_name] = [:number, :debit, :credit]
    code += light_search_conditions(filter, search_options)
    if options[:with_journals] 
      code += "\n"
      code += journals_crit("params")
    else
      code += "[0] += ' AND (#{JournalEntry.table_name}.journal_id=?)'\n"
      code += "c << params[:id]\n"
    end
    if options[:state]
      code += "c[0] += ' AND (#{JournalEntry.table_name}.state=?)'\n"
      code += "c << '#{options[:state]}'\n"
    else
      code += journal_entries_states_crit("params")
    end
    code += journal_period_crit("params")
    code += "c\n"
    # list = code.split("\n"); list.each_index{|x| puts((x+1).to_s.rjust(4)+": "+list[x])}
    return code.gsub(/\s*\n\s*/, ";")
  end

  # accountancy -> journal_entries_states_crit
  def self.journal_entries_states_crit(variable, conditions='c')
    variable = "session[:#{variable}]" unless variable.is_a? String
    code = ""
    code += "#{conditions}[0] += ' AND '+JournalEntry.state_condition(#{variable}[:states])\n"
    return code
  end

  # accountancy -> journal_period_crit
  def self.journal_period_crit(variable, conditions='c')
    variable = "session[:#{variable}]" unless variable.is_a? String
    code = ""
    code += "#{conditions}[0] += ' AND '+JournalEntry.period_condition(#{variable}[:period], #{variable}[:started_on], #{variable}[:stopped_on])\n"
    return code
  end

  # accountancy -> journals_crit
  def self.journals_crit(variable, conditions='c')
    variable = "session[:#{variable}]" unless variable.is_a? String
    code = ""
    code += "#{conditions}[0] += ' AND '+JournalEntry.journal_condition(#{variable}[:journals])\n"
    return code
  end

  # finances -> incoming_payments_conditions
  def self.incoming_payments_conditions(options={})
    code = search_conditions(:incoming_payments, :incoming_payments=>[:amount, :used_amount, :check_number, :number], :entities=>[:code, :full_name])+"||=[]\n"
    code += "if session[:incoming_payment_state] == 'unreceived'\n"
    code += "  c[0] += ' AND received=?'\n"
    code += "  c << false\n"
    code += "elsif session[:incoming_payment_state] == 'waiting'\n"
    code += "  c[0] += ' AND to_bank_on > ?'\n"
    code += "  c << Date.today\n"
    code += "elsif session[:incoming_payment_state] == 'undeposited'\n"
    code += "  c[0] += ' AND deposit_id IS NULL'\n"
    code += "elsif session[:incoming_payment_state] == 'unparted'\n"
    code += "  c[0] += ' AND used_amount != amount'\n"
    code += "end\n"
    code += "c\n"
    return code
  end

  # finances -> outgoing_payments_conditions
  def self.outgoing_payments_conditions(options={})
    code = search_conditions(:outgoing_payments, :outgoing_payments=>[:amount, :used_amount, :check_number, :number], :entities=>[:code, :full_name])+"||=[]\n"
    code += "if session[:outgoing_payment_state] == 'undelivered'\n"
    code += "  c[0] += ' AND delivered=?'\n"
    code += "  c << false\n"
    code += "elsif session[:outgoing_payment_state] == 'waiting'\n"
    code += "  c[0] += ' AND to_bank_on > ?'\n"
    code += "  c << Date.today\n"
    code += "elsif session[:outgoing_payment_state] == 'unparted'\n"
    code += "  c[0] += ' AND used_amount != amount'\n"
    code += "end\n"
    code += "c\n"
    return code
  end

  # management -> moved_conditions
  def self.moved_conditions(model)
    code = ""
    code += "c=['#{model.table_name}.company_id=?', @current_company.id]\n"
    code += "if params[:mode]=='unconfirmed'\n"
    code += "  c[0] += ' AND moved_on IS NULL'\n"
    code += "elsif params[:mode]=='confirmed'\n"
    code += "  c[0] += ' AND moved_on IS NOT NULL'\n"
    code += "end\n"
    code += "c\n"
    return code
  end

  # management -> prices_conditions
  def self.prices_conditions(options={})
    code = "conditions=[]\n"
    code += "if session[:entity_id] == 0 \n " 
    code += " conditions = ['#{Price.table_name}.company_id = ? AND #{Price.table_name}.active = ?', @current_company.id, true] \n "
    code += "else \n "
    code += " conditions = ['#{Price.table_name}.company_id = ? AND #{Price.table_name}.entity_id = ? AND #{Price.table_name}.active = ?', @current_company.id, session[:entity_id], true]"
    code += "end \n "
    code += "conditions \n "
    code
  end

  # management -> products_conditions
  def self.products_conditions(options={})
    code = ""
    code += "conditions = [ \" #{Product.table_name}.company_id = ? AND (LOWER(#{Product.table_name}.code) LIKE ? OR LOWER(#{Product.table_name}.name) LIKE ?) AND active = ? \" , @current_company.id, '%'+session[:product_key].to_s.lower+'%', '%'+session[:product_key].to_s.lower+'%', session[:product_active]] \n"
    code += "if session[:product_category_id].to_i != 0 \n"
    code += "  conditions[0] += \" AND #{Product.table_name}.category_id = ?\" \n" 
    code += "  conditions << session[:product_category_id].to_i \n"
    code += "end \n"
    code += "conditions \n"
    code
  end

  # management -> sales_conditions
  def self.sales_conditions
    code = ""
    code = search_conditions(:sale, :sales=>[:pretax_amount, :amount, :number, :initial_number, :comment], :entities=>[:code, :full_name])+"||=[]\n"
    code += "unless session[:sale_state].blank? \n "
    code += "  if session[:sale_state] == 'current' \n "
    code += "    c[0] += \" AND state IN ('estimate', 'order', 'invoice') \" \n " 
    code += "  elsif session[:sale_state] == 'unpaid' \n "
    code += "    c[0] += \"AND state IN ('order','invoice') AND paid_amount < amount\" \n "
    code += "  end\n "
    code += "end\n "
    code += "c\n "
    code
  end

  # management -> stocks_conditions
  def self.stocks_conditions(options={})
    code = ""
    code += "conditions = {} \n"
    code += "conditions[:company_id] = @current_company.id\n"
    code += "conditions[:warehouse_id] = session[:warehouse_id].to_i if session[:warehouse_id] and session[:warehouse_id].to_i > 0\n "
    code += "conditions \n "
    code
  end

  # management -> subscriptions_conditions
  def self.subscriptions_conditions(options={})
    code = ""
    code += "conditions = [ \" #{Subscription.table_name}.company_id = ? AND COALESCE(#{Subscription.table_name}.sale_id, 0) NOT IN (SELECT id FROM #{Sale.table_name} WHERE company_id = ? and state = 'E') \" , @current_company.id, @current_company.id]\n"
    code += "if session[:subscriptions].is_a? Hash\n"
    code += "  if session[:subscriptions][:nature].is_a? Hash\n"
    code += "    conditions[0] += \" AND #{Subscription.table_name}.nature_id = ?\" \n "
    code += "    conditions << session[:subscriptions][:nature]['id'].to_i\n"
    code += "  end\n"
    code += "  if session[:subscriptions][:nature]['nature'] == 'quantity'\n"
    code += "    conditions[0] += \" AND ? BETWEEN #{Subscription.table_name}.first_number AND #{Subscription.table_name}.last_number\"\n"
    code += "  elsif session[:subscriptions][:nature]['nature'] == 'period'\n"
    code += "    conditions[0] += \" AND ? BETWEEN #{Subscription.table_name}.started_on AND #{Subscription.table_name}.stopped_on\"\n"
    code += "  end\n"
    code += "  conditions << session[:subscriptions][:instant]\n"
    code += "end\n"
    code += "conditions\n"
    code
  end

  # relations -> mandates_conditions
  def self.mandates_conditions(options={}) 
    code = ""
    code += "conditions = ['mandates.company_id=?', @current_company.id]\n"
    code += "if session[:mandates].is_a? Hash\n"
    code += "  unless session[:mandates][:organization].blank? \n"
    code += "    conditions[0] += ' AND organization = ?'\n"
    code += "    conditions << session[:mandates][:organization] \n"
    code += "  end \n"
    code += "  unless session[:mandates][:date].blank? \n"
    code += "    conditions[0] += ' AND (? BETWEEN COALESCE(started_on, stopped_on, ?)  AND COALESCE(stopped_on, ?) )'\n"
    code += "    conditions << session[:mandates][:date].to_s \n"
    code += "    conditions << session[:mandates][:date].to_s \n"
    code += "    conditions << session[:mandates][:date].to_s \n"
    code += "  end \n"
    code += "end \n"
    code += "conditions \n"
    code
  end

end
