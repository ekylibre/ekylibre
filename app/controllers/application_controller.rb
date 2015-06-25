# encoding: utf-8
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
  include ActionView::Helpers::NumberHelper
  # helper :all # include all helpers, all the time
  around_filter(:profile) if Rails.env.development?
  before_filter :no_cache
  before_filter :i18nize
  before_filter :identify
  before_filter :authorize
  after_filter  :historize
  attr_accessor :current_user
  attr_accessor :current_company
  layout :dialog_or_not

  include Userstamp
  # include ExceptionNotifiable
  # local_addresses.clear

  # TODO: Move these lines to test
  # for k, v in Ekylibre.references
  #   for c, t in v
  #     raise Exception.new("#{k}.#{c} is not filled.") if t.blank?
  #     t.to_s.classify.constantize if t.is_a? Symbol
  #   end
  # end



  # Generate render_print_* method which send data corresponding to a nature of
  # document template. It use special method +print_fastly!+.
  for nature, parameters in DocumentTemplate.document_natures
    method_name = "render_print_#{nature}"
    code  = "" # "hide_action :#{method_name}\n"
    code << "def #{method_name}("+parameters.collect{|p| p[0]}.join(', ')+", template=nil)\n"
    code << "  template ||= params[:template]\n"
    code << "  template = if template.is_a? String or template.is_a? Symbol\n"
    code << "    @current_company.document_templates.find_by_active_and_nature_and_code(true, '#{nature}', template.to_s)\n"
    code << "  else\n"
    code << "    @current_company.document_templates.find_by_active_and_nature_and_by_default(true, '#{nature}', true)\n"
    code << "  end\n"
    code << "  unless template\n"
    code << "    notify_error(:cannot_find_document_template, :nature=>'#{nature}', :template=>template.inspect)\n"
    code << "    redirect_to_back\n"
    code << "    return\n"
    code << "  end\n"
    code << "  headers['Cache-Control'] = 'maxage=3600'\n"
    code << "  headers['Pragma'] = 'public'\n"
    code << "  begin\n"
    for p in parameters
      code << "    #{p[0]} = #{p[1].name}.find_by_id_and_company_id(#{p[0]}.to_s.to_i, @current_company.id) unless #{p[0]}.is_a? #{p[1].name}\n" if p[1].ancestors.include?(ActiveRecord::Base)
      code << "    #{p[0]} = #{p[0]}.to_date if #{p[0]}.is_a?(String)\n" if p[1] == Date
      code << "    raise ArgumentError.new('#{p[1].name} expected, got '+#{p[0]}.class.name+':'+#{p[0]}.inspect) unless #{p[0]}.is_a?(#{p[1].name})\n"
    end
    code << "    data, filename = template.print_fastly!("+parameters.collect{|p| p[0]}.join(', ')+")\n"
    code << "    send_data(data, :filename=>filename, :type=>Mime::PDF, :disposition=>'inline')\n"
    code << "  rescue Exception=>e\n"
    code << "    notify_error(:print_failure, :class=>e.class.to_s, :error=>e.message.to_s, :cache=>template.cache.to_s)\n"
    code << "    redirect_to_back\n"
     code << "  end\n"
    code << "end\n"
    # raise code
    eval(code)
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
      # url[:controller]||=controller_name 
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


  def self.human_action_name(action, options={})
    options = {} unless options.is_a?(Hash)
    root, action = "actions."+self.controller_name+".", action.to_s
    options[:default] ||= []
    options[:default] << (root+"new").to_sym  if action == "create"
    options[:default] << (root+"edit").to_sym if action == "update"
    return ::I18n.translate(root+action, options)
  end

  hide_action :human_action_name
  def human_action_name()
    return self.class.human_action_name(action_name, @title)
  end


  def default_url_options(options={})
    options[:company] ||= ((params and params[:company]) ? params[:company] : @current_company ? @current_company.code : nil)
    return options
  end


  

  
  protected  

  def render_restfully_form(options={})
    operation = action_name.to_sym
    operation = (operation==:create ? :new : operation==:update ? :edit : operation)
    partial   = options[:partial]||'form'
    render(:template=>options[:template]||"forms/#{operation}", :locals=>{:operation=>operation, :partial=>partial, :options=>options})
  end


  def find_and_check(model, id=nil, options={})
    model, record, klass = model.to_s, nil, nil
    id ||= params[:id]
    begin
      klass = model.to_s.classify.constantize
      record = klass.find_by_id_and_company_id(id.to_s.to_i, @current_company.id)
    rescue
      notify_error(:unavailable_model, :model=>model.inspect, :id=>id)
      redirect_to_back
      return false
    end
    if record.nil?
      notify_error(:unavailable_model, :model=>klass.model_name.human, :id=>id)
      redirect_to_back
    end
    return record
  end

  def save_and_redirect(record, options={}, &block)
    url = options[:url] || :back
    record.attributes = options[:attributes] if options[:attributes]
    ActiveRecord::Base.transaction do
      if record.send(:save) or options[:saved]
        yield record if block_given?
        response.headers["X-Return-Code"] = "success"
        response.headers["X-Saved-Record-Id"] = record.id.to_s
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
    end
    response.headers["X-Return-Code"] = "invalid"
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


  def notify(message, options={}, nature=:information, mode=:next)
    notistore = (mode==:now ? flash.now : flash)
    notistore[:notifications] = {} unless notistore[:notifications].is_a? Hash
    notistore[:notifications][nature] = [] unless notistore[:notifications][nature].is_a? Array
    notistore[:notifications][nature] << ::I18n.t("notifications."+message.to_s, options)    
  end
  def notify_error(message, options={});   notify(message, options, :error); end
  def notify_warning(message, options={}); notify(message, options, :warning); end
  def notify_success(message, options={}); notify(message, options, :success); end
  def notify_now(message, options={});         notify(message, options, :information, :now); end
  def notify_error_now(message, options={});   notify(message, options, :error, :now); end
  def notify_warning_now(message, options={}); notify(message, options, :warning, :now); end
  def notify_success_now(message, options={}); notify(message, options, :success, :now); end

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

  # def current_user
  #   @current_user = User.find_by_id(session[:user_id]) unless @current_user
  #   return @current_user
  # end

  private

  def dialog_or_not()
    #return (params[:dialog] ? "dialog" : "application")
    return (request.xhr? ? "dialog" : "application")
  end
  

  # Set HTTP headers to block page caching
  def no_cache()
    # Change headers to force zero cache
    response.headers["Last-Modified"] = Time.now.httpdate
    response.headers["Expires"] = '0'
    # HTTP 1.0
    response.headers["Pragma"] = "no-cache" 
    # HTTP 1.1 'pre-check=0, post-check=0' (IE specific)
    response.headers["Cache-Control"] = 'no-store, no-cache, must-revalidate, max-age=0, pre-check=0, post-check=0'
  end


  # Initialize locale with params[:locale] or HTTP_ACCEPT_LANGUAGE
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

  # Load @current_user and @current_company
  def identify()
    # Load current_user if connected
    @current_user = User.find(:first, :conditions=>{:id=>session[:user_id]}, :readonly=>true) if session[:user_id] # _by_id(session[:user_id])
    
    # Load current_company if possible
    @current_company = Company.find(:first, :conditions=>{:code=>params[:company]}, :readonly=>true) #_by_code(params[:company])
    if @current_user and @current_company and @current_company["id"]!=@current_user["company_id"]
      notify_error(:unknown_company) unless params[:company].blank?
      redirect_to_login
      return false
    end
  end
  


  # Controls access to every view in Ekylibre. 
  def authorize()
    # # Load current_user if connected
    # @current_user = User.find_by_id(session[:user_id]) if session[:user_id]
    
    # # Load current_company if possible
    # @current_company = Company.find_by_code(params[:company])
    # if @current_user and @current_company and @current_company.id!=@current_user.company_id
    #   notify_error(:unknown_company) unless params[:company].blank?
    #   redirect_to_login
    #   return false
    # end

    # Get action rights
    controller_rights = {} unless controller_rights = User.rights[controller_name.to_sym]
    action_rights = controller_rights[action_name.to_sym]||[]

    # Returns if action is public
    return true if action_rights.include?(:__public__)

    # Check current_user
    unless @current_user
      notify_error(:access_denied, :reason=>"NOT PUBLIC", :url=>request.url.inspect)
      redirect_to_login
      return false 
    end

    # Check current_company
    if not @current_company or @current_company.id!=@current_user.company_id
      notify_error(:unknown_company) unless params[:company].blank?
      redirect_to_login
      return false
    end

    # Set session variables and check state
    session[:last_page] ||= {}
    if request.get? and not request.xhr? and not [:sessions, :help].include?(controller_name.to_sym)
      session[:last_url] = request.url
    end
    @article = search_article
    # TODO: Dynamic theme choosing
    @current_theme = "tekyla"
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
      return false
    else
      session[:last_query] = Time.now.to_i
    end

    # Check access for registered actions
    return true if action_rights.include?(:__minimum__)

    # Check rights before allowing access
    if message = @current_user.authorization(controller_name, action_name, session[:rights])
      if @current_user.admin
        notify_error_now(:access_denied, :reason=>message, :url=>request.url.inspect)
      else
        notify_error(:access_denied, :reason=>message, :url=>request.url.inspect)
        redirect_to_back
        return false
      end
    end
    
    # Returns true if authorized
    return true
  end





  # Fill the history array
  def historize()
    if @current_user and request.get? and not request.xhr? and params[:format].blank?
      session[:history] = [] unless session[:history].is_a? Array
      if session[:history][1].is_a?(Hash) and session[:history][1][:url] == request.url
        session[:history].delete_at(0)
      elsif session[:history][0].nil? or (session[:history][0].is_a?(Hash) and session[:history][0][:url] != request.url)
        session[:history].insert(0, {:url=>request.url, :title=>self.human_action_name, :reverse=>Ekylibre.reverse_menus["#{controller_name}::#{action_name}"]||[], :path=>request.path})
        session[:history].delete_at(31)
      end
    end
  end

  # Generate HTML for a CallInfo object of RubyProf
  def self.call_info_tree(call_info, options={})
    options[:total_time] ||= call_info.total_time
    options[:threshold]  ||= 0.5
    options[:display] = true if options[:display].nil?
    options[:depth] ||= 0
    html = ""
    percentage = 100*call_info.total_time.to_f/options[:total_time].to_f
    return "" unless percentage >= options[:threshold]
    method_info = call_info.target
    # #{(255-3*depth).to_s(16)*3}
    
    html += "<div class='profile p#{call_info.parent.object_id}' style='margin-left: 8px; background: ##{(255-percentage).to_i.to_s(16)*3}; #{'display: none' unless options[:display]}'>"
    regexp = /\([^\)]+\)/

    html += "<div class='tit' title='#{h(method_info.source_file.gsub(Rails.root.to_s, 'RAILS_ROOT').gsub(Gem.dir, 'GEM_DIR'))}:#{h(method_info.line)} called at line #{h(call_info.line)}' onclick='$(\".p#{call_info.object_id}\").toggle();'>"
    html += "<span class='fil'><span class='cls'>"+h(method_info.klass_name.gsub(regexp, ''))+"</span>&nbsp;<span class='mth'>"+h(method_info.method_name)+"</span></span>"
    html += "<span class='md mdc'>"+percentage.round(1).to_s+"%</span>"
    html += "<span class='md mdc'>"+call_info.called.to_s+"&times;</span>"
    html += "<span class='md dec'>"+(call_info.total_time*1_000_000).round(1).to_s+"µs</span>"
    html += "<span class='md dec'>"+(call_info.self_time*1_000_000).round(1).to_s+"µs</span>"
    html += "</div>"
    child_options = options.dup
    child_options[:depth] += 1
    child_options[:display] = (percentage >= 33 ? true : false)
    for child in call_info.children.sort{|a,b| a.line <=> b.line}
      html += call_info_tree(child, child_options) 
    end
    html += "</div>"
    return html
  end

  # Generate HTML for a CallInfo object of RubyProf
  def self.method_info_tree(method_info)
    regexp = /\([^\)]+\)/
    html = ""
    html += "<div class='profile'>"
    html += "<div class='tit'>"
    html += "<span class='fil'>"+h(method_info.source_file.gsub(Rails.root.to_s, ''))+"</span>:<span class='lno'>"+h(method_info.line)+"</span> <span class='cls'>"+h(method_info.klass_name.gsub(regexp, ''))+"</span>&nbsp;<span class='mth'>"+h(method_info.method_name)+"</span>"
    html += "<span class='dec tot'>"+(method_info.total_time*1_000_000).round(1).to_s+"µs</span>"
    html += "<span class='dec sav'>"+(method_info.self_time*1_000_000).round(1).to_s+"µs</span>"
    html += "</div>"
    # html += "<h3>Called by</h3>"
    # html += "<h3>Calls</h3>"
    html += "</div>"
    return html
  end
  

  def profile()
    unless params[:profile]
      yield
      return 
    end
    # require 'ruby-prof'
    RubyProf.measure_mode = RubyProf::PROCESS_TIME
    result = RubyProf.profile do
      yield
    end
    if params[:profile] == "graph"
      printer = RubyProf::CallStackPrinter.new(result)
      name = "RubyProf-#{controller_name}-#{action_name}-#{Time.now.to_i.to_s(36)}.html"
      file = File.open(Rails.root.join("public", name), "wb")
      printer.print(file)
      self.response.body.sub! "</body>", "<a href='/#{name}'>Graph</a></body>" # <div>CallTree printed in STDOUT</div>
    else
      html = "<small>"
      for id, method_infos in result.threads
        html += "<h2>Thread: #{id}</h2>"
        ci  = method_infos[0].call_infos[0]
        until ci.root?
          ci = ci.parent
        end
        if params[:profile] == "tree"
          html += self.class.call_info_tree(ci, :threshold=>params[:threshold])
        elsif params[:profile] == "flat"
          for method_info in method_infos
            next unless method_info.source_file.match(Rails.root.to_s)
            html += self.class.method_info_tree(method_info)
          end
        end
      end
      html += "</small>"
      self.response_body = self.response.body.sub("</body>", html + "</body>")
    end
  end
  


  def search_article(article=nil)
    session[:help_history] = [] unless session[:help_history].is_a? [].class
    article ||= "#{self.controller_name}-#{self.action_name}"
    file = nil
    # raise [I18n.locale, I18n.default_locale]
    for locale in [I18n.locale, I18n.default_locale]
      for f, attrs in Ekylibre.helps
        next if attrs[:locale] != locale
        file_name = [article, article.split("-")[0].to_s+"-index"].detect{|name| attrs[:name]==name}
        file = f and break unless file_name.blank?
      end
    end
    if file and session[:side] and article != session[:help_history].last
      session[:help_history] << file
    end
    file ||= article.to_sym
    return file
  end

  def redirect_to_login(url=nil)
    reset_session
    @current_user = nil
    redirect_to(new_session_url(:redirect=>url, :company=>params[:company]))
  end
  
  def redirect_to_back(options={})
    if params[:redirect]
      redirect_to params[:redirect], options
    elsif session[:history].is_a?(Array) and session[:history][0].is_a?(Hash)
      redirect_to session[:history][0][:url], options
    elsif request.referer and request.referer != request.url
      redirect_to request.referer, options
    else
      redirect_to :controller=>:dashboards, :action=>:general
    end
  end

  def redirect_to_current(options={})
    redirect_to_back(options)
    # if session[:history].is_a?(Array) and session[:history][0].is_a?(Hash)
    #   redirect_to session[:history][0]
    # else
    #   redirect_to_back
    # end
  end

  
  def initialize_session(user)
    reset_session
    session[:expiration]   = 3600*5
    session[:history]      = []
    session[:last_page]    = {}
    session[:last_query]   = Time.now.to_i
    session[:rights]       = user.rights.to_s.split(" ").collect{|x| x.to_sym}.freeze
    session[:side]         = true
    session[:view_mode]    = user.preference("interface.general.view_mode", "printable", :string).value
    session[:user_id]      = user.id
    # Loads modules preferences
    session[:modules]      = {}
    show_modules = "interface.show_modules."
    for preference in user.preferences.where("name LIKE ?", "#{show_modules}%")
      session[:modules][preference.name[show_modules.length..-1]] = preference.value
    end
    # Build and cache customized menu for all the session
    session[:menus] = ActiveSupport::OrderedHash.new
    for menu, submenus in Ekylibre.menus
      fsubmenus = ActiveSupport::OrderedHash.new
      for submenu, menuitems in submenus
        fmenuitems = menuitems.collect do |url|
          if user.authorization(url[:controller], url[:action], session[:rights]).nil?
            url.merge(:url=>url_for(url.merge(:company=>user.company.code)))
          else
            nil
          end
        end.compact
        fsubmenus[submenu] = fmenuitems unless fmenuitems.size.zero?
      end
      session[:menus][menu] = fsubmenus unless fsubmenus.keys.size.zero?
    end
  end


  # Autocomplete helper
  def self.autocomplete_for(model_name, method)
    item =  model_name.to_s
    items = item.pluralize
    items = "many_#{items}" if items == item
    code =  "def #{__method__}_#{model_name}_#{method}\n"
    code << "  if params[:term]\n"
    code << "    pattern = '%'+params[:term].to_s.mb_chars.downcase.strip.gsub(/\s+/,'%').gsub(/[#{String::MINUSCULES.join}]/,'_')+'%'\n"
    code << "    @#{items} = @current_company.#{items}.select('DISTINCT #{method}').where('LOWER(#{method}) LIKE ?', pattern).order('#{method} ASC').limit(80)\n"
    code << "    respond_to do |format|\n"
    code << "      format.html { render :inline=>\"<%=content_tag(:ul, @#{items}.map { |#{item}| content_tag(:li, #{item}.#{method})) }.join.html_safe)%>\" }\n"
    code << "      format.json { render :json=>@#{items}.collect{|#{item}| #{item}.#{method}}.to_json }\n"
    code << "    end\n"
    code << "  else\n"
    code << "    render :text=>'', :layout=>true\n"
    code << "  end\n"
    code << "end\n"
    class_eval(code, "#{__FILE__}:#{__LINE__}")
  end


  # Build standard RESTful actions to manage records of a model
  def self.manage_restfully(defaults={})
    name = controller_name
    t3e = defaults.delete(:t3e)
    url = defaults.delete(:redirect_to)
    xhr = defaults.delete(:xhr)
    durl = defaults.delete(:destroy_to)
    partial = defaults.delete(:partial)
    partial = " :partial=>'#{partial}'" if partial
    record_name = name.to_s.singularize
    model = name.to_s.singularize.classify.constantize
    code = ''
    
    code += "def new\n"
    values = defaults.collect{|k,v| ":#{k}=>(#{v})"}.join(", ")
    code += "  @#{record_name} = #{model.name}.new(#{values})\n"
    if xhr
      code += "  if request.xhr?\n"
      code += "    render :partial=>#{xhr.is_a?(String) ? xhr.inspect : 'detail_form'.inspect}\n"
      code += "  else\n"
      code += "    render_restfully_form#{partial}\n"
      code += "  end\n"
    else
      code += "  render_restfully_form#{partial}\n"
    end
    code += "end\n"

    code += "def create\n"
    code += "  @#{record_name} = #{model.name}.new(params[:#{record_name}])\n"
    code += "  @#{record_name}.company_id = @current_company.id\n"
    code += "  return if save_and_redirect(@#{record_name}#{',  :url=>'+url if url})\n"
    code += "  render_restfully_form#{partial}\n"
    code += "end\n"

    # this action updates an existing record with a form.
    code += "def edit\n"
    code += "  return unless @#{record_name} = find_and_check(:#{record_name})\n"
    code += "  t3e(@#{record_name}.attributes"+(t3e ? ".merge("+t3e.collect{|k,v| ":#{k}=>(#{v})"}.join(", ")+")" : "")+")\n"
    code += "  render_restfully_form#{partial}\n"
    code += "end\n"

    code += "def update\n"
    code += "  return unless @#{record_name} = find_and_check(:#{record_name})\n"
    code += "  t3e(@#{record_name}.attributes"+(t3e ? ".merge("+t3e.collect{|k,v| ":#{k}=>(#{v})"}.join(", ")+")" : "")+")\n"
    raise Exception.new("You must put :company_id in attr_readonly of #{model.name} (#{model.readonly_attributes.inspect})") if model.readonly_attributes.nil? or not model.readonly_attributes.to_a.join.match(/company_id/)
    code += "  @#{record_name}.attributes = params[:#{record_name}]\n"
    code += "  return if save_and_redirect(@#{record_name}#{', :url=>('+url+')' if url})\n"
    code += "  render_restfully_form#{partial}\n"
    code += "end\n"

    # this action deletes or hides an existing record.
    code += "def destroy\n"
    code += "  return unless @#{record_name} = find_and_check(:#{record_name})\n"
    if model.instance_methods.include?("destroyable?")
      code += "  if @#{record_name}.destroyable?\n"
      code += "    #{model.name}.destroy(@#{record_name}.id)\n"
      code += "    notify_success(:record_has_been_correctly_removed)\n"
      code += "  else\n"
      code += "    notify_error(:record_cannot_be_removed)\n"
      code += "  end\n"
    else
      code += "  #{model.name}.destroy(@#{record_name}.id)\n"
      code += "  notify_success(:record_has_been_correctly_removed)\n"
    end
    # code += "  redirect_to #{durl ? durl : model.name.underscore.pluralize+'_url'}\n"
    code += "  #{durl ? 'redirect_to '+durl : 'redirect_to_current'}\n"
    code += "end\n"

    # list = code.split("\n"); list.each_index{|x| puts((x+1).to_s.rjust(4)+": "+list[x])}    
    class_eval(code)
  end


  # Build standard actions to manage records of a model
  def self.manage_restfully_list(order_by=:id)
    name = controller_name
    record_name = name.to_s.singularize
    model = name.to_s.singularize.classify.constantize
    records = model.name.underscore.pluralize

    raise ArgumentError.new("Unknown column for #{model.name}") unless model.columns_hash[order_by.to_s]
    code = ''
    
    sort = ""
    position, conditions = "#{record_name}_position_column", "#{record_name}_conditions"
    sort += "#{position}, #{conditions} = #{record_name}.position_column, #{record_name}.scope_condition\n"
    sort += "#{records}_count = #{model.name}.count(#{position}, :conditions=>#{conditions})\n"
    sort += "unless #{records}_count == #{model.name}.count(#{position}, :conditions=>#{conditions}, :distinct=>true) and #{model.name}.sum(#{position}, :conditions=>#{conditions}) == #{records}_count*(#{records}_count+1)/2\n"
    sort += "  #{records} = #{model.name}.find(:all, :conditions=>#{conditions}, :order=>#{position}+', #{order_by}')\n"
    sort += "  #{records}.each_index do |i|\n"
    sort += "    #{model.name}.update_all({#{position}=>i+1}, {:id=>#{records}[i].id})\n"
    sort += "  end\n"
    sort += "end\n"
    
    code += "def up\n"
    code += "  return unless #{record_name} = find_and_check(:#{record_name})\n"
    code += "  #{record_name}.move_higher\n"
    code += sort.gsub(/^/, "  ")
    code += "  redirect_to_current\n"
    code += "end\n"
    
    code += "def down\n"
    code += "  return unless #{record_name} = find_and_check(:#{record_name})\n"
    code += "  #{record_name}.move_lower\n"
    code += sort.gsub(/^/, "  ")
    code += "  redirect_to_current\n"
    code += "end\n"

    # list = code.split("\n"); list.each_index{|x| puts((x+1).to_s.rjust(4)+": "+list[x])}
    class_eval(code)
  end



  def self.search_conditions(model_name, columns)
    model = model_name.to_s.classify.constantize
    columns = [columns] if [String, Symbol].include? columns.class 
    columns = columns.collect{|k,v| v.collect{|x| "#{k}.#{x}"}} if columns.is_a? Hash
    columns.flatten!
    raise Exception.new("Bad columns: "+columns.inspect) unless columns.is_a? Array
    code = ""
    code << "c = ['#{model.table_name}.company_id=?', @current_company.id]\n"
    code << "session[:#{model.name.underscore}_key].to_s.lower.split(/\\s+/).each{|kw| kw='%'+kw+'%';"
    # This line is incompatible with MySQL...
    if ActiveRecord::Base.connection.adapter_name.match(/^mysql/i)
      code << "c[0] << ' AND ("+columns.collect{|x| 'LOWER(CAST('+x.to_s+' AS CHAR)) LIKE ?'}.join(' OR ')+")';\n"
    else
      code << "c[0] << ' AND ("+columns.collect{|x| 'LOWER(CAST('+x.to_s+' AS VARCHAR)) LIKE ?'}.join(' OR ')+")';\n"
    end
    code << "c += [#{(['kw']*columns.size).join(',')}]"
    code << "}\n"
    code << "c"
    code
  end

  def self.light_search_conditions(search={}, options={})
    conditions = options[:conditions] || 'c'
    options[:except] ||= []
    options[:filters] ||= {}
    variable ||= options[:variable] || "params[:q]"
    tables = search.keys.select{|t| !options[:except].include? t}
    code = "\n#{conditions} = ['"+tables.collect{|t| "#{ActiveRecord::Base.connection.quote_table_name(t.is_a?(Symbol) ? t.to_s.classify.constantize.table_name : t)}.company_id=?"}.join(' AND ')+"'"+", @current_company.id"*tables.size+"]\n"
    columns = search.collect{|t, cs| cs.collect{|c| "#{ActiveRecord::Base.connection.quote_table_name(t.is_a?(Symbol) ? t.to_s.classify.constantize.table_name : t)}.#{ActiveRecord::Base.connection.quote_column_name(c)}"}}.flatten
    code += "for kw in #{variable}.to_s.lower.split(/\\s+/)\n"
    code += "  kw = '%'+kw+'%'\n"
    filters = columns.collect do |x| 
      # This line is incompatible with MySQL...
      if ActiveRecord::Base.connection.adapter_name.match(/^mysql/i)
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

  # management -> moved_conditions
  def self.moved_conditions(model, state='params[:s]')
    code = "\n"
    code += "c||=['#{model.table_name}.company_id=?', @current_company.id]\n"
    code += "if #{state}=='unconfirmed'\n"
    code += "  c[0] += ' AND moved_on IS NULL'\n"
    code += "elsif #{state}=='confirmed'\n"
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

end
