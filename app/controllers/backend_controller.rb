# encoding: utf-8
# == License
# Ekylibre - Simple ERP
# Copyright (C) 2009-2012 Brice Texier
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

class BackendController < BaseController
  protect_from_forgery
  # # before_filter :no_cache
  # before_filter :i18nize
  before_filter :authenticate_user!
  # # before_filter :identify
  # before_filter :authorize
  # after_filter  :historize
  # # attr_accessor :current_user
  layout :dialog_or_not

  include Userstamp
  # include ExceptionNotifiable
  # local_addresses.clear


  class << self
    attr_reader :unrolls

    # Create unroll action for all scopes in the model corresponding to the controller
    # including the default scope
    def unroll_all(options = {})
      model = (options[:model] || self.controller_name).classify.constantize
      # Named scopes
      for scope in (model.scopes || [])
        self.unroll(scope, options.dup)
      end
      # Default scope
      self.unroll(options.dup)
    end

    # Create unroll action for one given scope
    def unroll(*args)
      options = (args[-1].is_a?(Hash) ? args.delete_at(-1) : {})
      name = args[-1]

      model = (options.delete(:model) || controller_name).to_s.classify.constantize
      foreign_record  = model.name.underscore
      foreign_records = foreign_record.pluralize
      scope_name = options.delete(:scope) || name
      max = options[:max] || 80
      if label = options.delete(:label)
        label = (label.is_a?(Symbol) ? "{#{label}:%X%}" : label.to_s)
      else
        base = "unroll." + self.controller_path
        label = I18n.translate(base + ".#{name || :all}", :default => [(base + ".all").to_sym, ""])
        if label.blank?
          available_methods = model.columns_hash.keys.collect{|x| x.to_sym}
          label = '{' + [:title, :label, :full_name, :name, :code, :number].select{|x| available_methods.include?(x)}.first.to_s + ':%X%}'
        end
      end


      columns = []
      item_label = label.inspect.gsub(/\{[a-z\_]+(\:\%?X\%?)?\}/) do |word|
        ca = word[1..-2].split(":")
        column = model.columns_hash[ca[0]]
        raise Exception.new("Unknown column #{ca[0]} for #{model.name}") unless column
        columns << {column: column, name: column.name.to_sym, filter: ca[1]|| "X%"}
        i = "item.#{column.name}"
        "\" + (#{i}.nil? ? '' : #{i}.l) + \""
      end

      fill_in = (options.has_key?(:fill_in) ? options[:fill_in] : columns.size == 1 ? columns.first[:name] : model.columns_hash["name"] ? :name : nil)
      fill_in = fill_in.to_sym unless fill_in.nil?

      if !fill_in.nil? and !columns.detect{|c| c[:name] == fill_in }
        raise StandardError.new("Label (#{label}, #{columns.inspect}) of unroll must include the primary column: #{fill_in.inspect}")
      end

      haml  = ""
      haml << "-if items.count > 0\n"
      haml << "  %ul.items-list\n"
      haml << "    -for item in items.limit(items.count > #{(max*1.5).round} ? #{max} : #{max*2})\n"
      haml << "      %li.item{'data-item-label' => #{item_label}, 'data-item-id' => item.id}\n"
      if options[:partial]
        haml << "        =render :partial => '#{partial}', :object => item\n"
      else
        haml << "        =highlight(#{item_label}, keys)\n"
      end
      haml << "  -if items.count > #{(max*1.5).round}\n"
      haml << "    %span.items-status.items-status-too-many-records\n"
      haml << "      =I18n.t('labels.x_items_remain_on_y', :count => (items.count - #{max}))\n"
      haml << "-else\n"
      haml << "  %ul.items-list\n"
      unless fill_in.nil?
        haml << "    -unless search.blank?\n"
        haml << "      %li.item.special{'data-new-item' => search, 'data-new-item-parameter' => '#{fill_in}'}=I18n.t('labels.add_x', :x => content_tag(:strong, search)).html_safe\n"
      end
      haml << "    %li.item.special{'data-new-item' => ''}=I18n.t('labels.add_#{model.name.underscore}', :default => [:'labels.add_new_record'])\n"
      # haml << "  %span.items-status.items-status-empty\n"
      # haml << "    =I18n.t('labels.no_results')\n"

      # Write haml in cache
      file_name = (name || "__default__").to_s
      dir = Rails.root.join("tmp", "cache", "unroll", *(self.name.underscore.gsub(/_controller$/, '').split('/')))
      FileUtils.mkdir_p(dir)
      File.open(dir.join("#{file_name}.html.haml"), "wb") do |f|
        f.write(haml)
      end
      method_name = "unroll#{'_' + name.to_s if name}".to_sym
      @unrolls ||= []
      @unrolls << method_name

      code  = "def #{method_name}\n"
      code << "  conditions = []\n"
      code << "  keys = params[:q].to_s.strip.mb_chars.downcase.normalize.split(/[\\s\\,]+/)\n"
      code << "  # " + columns.collect{|c| c[:column].name}.to_sentence + "\n"
      code << "  if params[:id]\n"
      code << "    conditions = {:id => params[:id]}\n"
      searchable_columns = columns.delete_if{ |c| c[:column].type == :boolean }
      if searchable_columns.size > 0
        code << "  elsif keys.size > 0\n"
        code << "    conditions[0] = '('\n"
        code << "    keys.each_with_index do |key, index|\n"
        code << "      conditions[0] << ') AND (' if index > 0\n"
        code << "      conditions[0] << " + searchable_columns.collect{|column| "LOWER(CAST(#{model.table_name}.#{column[:name]} AS VARCHAR)) LIKE ?"}.join(' OR ').inspect + "\n"
        code << "      conditions += [" + searchable_columns.collect{|column| column[:filter].inspect.gsub('X', '" + key + "').gsub(/(^\"\"\+|\+\"\"\+|\+\"\")/, '')}.join(", ") + "]\n"
        code << "    end\n"
        code << "    conditions[0] << ')'\n"
      else
        ActiveSupport::Deprecation.warn("No searchable columns for #{self.controller_path}##{method_name}")
      end
      code << "  end\n"
      code << "  items = #{model.name}#{'.' + scope_name.to_s if scope_name}.where(conditions)\n"

      code << "  respond_to do |format|\n"
      code << "    format.html { render :file => '#{dir.join(file_name).relative_path_from(Rails.root)}', :locals => { :items => items, :keys => keys, :search => params[:q].to_s.capitalize.strip }, :layout => false }\n"
      code << "    format.json { render :json => items.collect{|item| {:label => #{item_label}, :id => item.id}}.to_json }\n"
      code << "    format.xml  { render  :xml => items.collect{|item| {:label => #{item_label}, :id => item.id}}.to_xml }\n"
      code << "  end\n"
      code << "end"
      # puts code
      class_eval(code)
      return method_name
    end

  end
  







  # Generate render_print_* method which send data corresponding to a nature of
  # document template. It use special method +print_fastly!+.
  for nature, parameters in DocumentTemplate.document_natures
    method_name = "render_print_#{nature}"
    code  = "" # "hide_action :#{method_name}\n"
    code << "def #{method_name}("+parameters.collect{|p| p[0]}.join(', ')+", template=nil)\n"
    code << "  template ||= params[:template]\n"
    code << "  template = if template.is_a? String or template.is_a? Symbol\n"
    code << "    DocumentTemplate.find_by_active_and_nature_and_code(true, '#{nature}', template.to_s)\n"
    code << "  else\n"
    code << "    DocumentTemplate.find_by_active_and_nature_and_by_default(true, '#{nature}', true)\n"
    code << "  end\n"
    code << "  unless template\n"
    code << "    notify_error(:cannot_find_document_template, :nature => '#{nature}', :template => template.inspect)\n"
    code << "    redirect_to_back\n"
    code << "    return\n"
    code << "  end\n"
    code << "  headers['Cache-Control'] = 'maxage=3600'\n"
    code << "  headers['Pragma'] = 'public'\n"
    code << "  begin\n"
    for p in parameters
      code << "    #{p[0]} = #{p[1].name}.find_by_id(#{p[0]}.to_s.to_i) unless #{p[0]}.is_a? #{p[1].name}\n" if p[1].ancestors.include?(ActiveRecord::Base)
      code << "    #{p[0]} = #{p[0]}.to_date if #{p[0]}.is_a?(String)\n" if p[1] == Date
      code << "    raise ArgumentError.new('#{p[1].name} expected, got '+#{p[0]}.class.name+':'+#{p[0]}.inspect) unless #{p[0]}.is_a?(#{p[1].name})\n"
    end
    code << "    data, filename = template.print_fastly!("+parameters.collect{|p| p[0]}.join(', ')+")\n"
    code << "    send_data(data, :filename => filename, :type => Mime::PDF, :disposition => 'inline')\n"
    code << "  rescue Exception => e\n"
    code << "    notify_error(:print_failure, :class => e.class.to_s, :error => e.message.to_s, :cache => template.cache.to_s)\n"
    code << "    redirect_to_back\n"
    code << "  end\n"
    code << "end\n"
    # raise code
    eval(code)
  end


  protected

  # def render_restfully_form(options = {})
  #   # operation = self.action_name.to_sym
  #   # operation = (operation == :create ? :new : operation == :update ? :edit : operation)
  #   # partial   = options[:partial] || 'form'
  #   # options[:form_options] = {} unless options[:form_options].is_a?(Hash)
  #   # options[:form_options][:multipart] = true if options[:multipart]
  #   # render(:template => options[:template]||"forms/#{operation}", :locals => {:operation => operation, :partial => partial, :options => options})
  #   render(:template  => "forms/#{self.action_name}", :locals => {:options => options})
  # end


  def find_and_check(model = nil, id = nil, options={})
    model ||= self.controller_name
    model, record, klass = model.to_s, nil, nil
    id ||= params[:id]
    begin
      klass = model.to_s.classify.constantize
      record = klass.find_by_id(id.to_s.to_i)
    rescue
      notify_error(:unavailable_model, :model => model.inspect, :id => id)
      redirect_to_current
      return false
    end
    if record.nil?
      notify_error(:unavailable_model, :model => klass.model_name.human, :id => id)
      redirect_to_current
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
          render :json => {:id => record.id}
        else
          # TODO: notify if success
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
      arg = arg.attributes if arg.respond_to?(:attributes)
      raise ArgumentError.new("Hash expected, got #{arg.class.name}:#{arg.inspect}") unless arg.is_a? Hash
      arg.each do |k,v|
        @title[k.to_sym] = if v.respond_to?(:strftime) or v.is_a?(Numeric)
                             ::I18n.localize(v)
                           else
                             v.to_s
                           end
      end
    end
  end



  protected

  # def current_user
  #   @current_user = Entity.find_by_id(session[:user_id]) unless @current_user
  #   return @current_user
  # end

  private

  def dialog_or_not()
    return (request.xhr? ? "popover" : params[:dialog] ? "dialog" : "backend")
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
        codes[::I18n.translate("i18n.iso2", :locale => l).to_s] = l
      end
      session[:locale] = codes[request.env["HTTP_ACCEPT_LANGUAGE"].to_s.split(/[\,\;]+/).select{|x| !x.match(/^q\=/)}.detect{|x| codes[x[0..1]]}[0..1]]
    end
    session[:locale] ||= ::I18n.locale||::I18n.default_locale
    ::I18n.locale = session[:locale]
  end

  # Load @current_user
  def identify()
    # Load current_user if connected
    @current_user = nil
    @current_user = User.find(:first, :conditions => {:id => session[:user_id]}, :readonly => true) if session[:user_id]
  end



  # Controls access to every view in Ekylibre.
  def authorize()
    # Get action rights
    controller_rights = {} unless controller_rights = User.rights[self.controller_name.to_sym]
    action_rights = controller_rights[self.action_name.to_sym]||[]

    # Search help article
    @article = "#{self.controller_path}-#{self.action_name}" # search_article

    # Returns if action is public
    return true if action_rights.include?(:__public__)

    # Check current_user
    unless current_user
      notify_error(:access_denied, :reason => "NOT PUBLIC", :url => request.url.inspect)
      redirect_to_login(request.url)
      return false
    end

    # Set session variables and check state
    session[:last_page] ||= {}
    if request.get? and not request.xhr? and not [:sessions, :help].include?(self.controller_name.to_sym)
      session[:last_url] = request.path
    end
    # TODO: Dynamic theme choosing
    @current_theme = "tekyla" # "zenky"

    # # Check expiration
    # if !session[:last_query].is_a?(Integer)
    #   redirect_to_login(request.path)
    #   return false
    # elsif session[:last_query].to_i<Time.now.to_i-session[:expiration].to_i
    #   notify(:expired_session)
    #   if request.xhr?
    #     render :text => "<script>window.location.replace('#{new_session_url}')</script>"
    #   else
    #     redirect_to_login(request.path)
    #   end
    #   return false
    # else
    #   session[:last_query] = Time.now.to_i
    # end

    # Check access for registered actions
    return true if action_rights.include?(:__minimum__)

    # Check rights before allowing access
    if message = @current_user.authorization(self.controller_name, self.action_name, session[:rights])
      if @current_user.admin
        notify_error_now(:access_denied, :reason => message, :url => request.path.inspect)
      else
        notify_error(:access_denied, :reason => message, :url => request.path.inspect)
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
      session[:history].delete_if { |h| h[:path] == request.path }
      session[:history].insert(0, {:title => self.human_action_name, :path => request.path}) # :url => request.url, :reverse => Ekylibre.menu.page(self.controller_name, self.action_name)
      session[:history].delete_at(30)
    end
  end



  def search_article(article = nil)
    session[:help_history] = [] unless session[:help_history].is_a? [].class
    article ||= "#{self.controller_path}-#{self.action_name}"
    file = nil
    for locale in [I18n.locale, I18n.default_locale]
      for f, attrs in Ekylibre.helps
        next if attrs[:locale].to_s != locale.to_s
        file_name = [article, article.split("-")[0] + "-index"].detect{|name| attrs[:name] == name}
        file = f and break unless file_name.blank?
      end
      break unless file.nil?
    end
    if file and session[:side] and article != session[:help_history].last
      session[:help_history] << file
    end
    file ||= article.to_sym
    return file
  end

  def redirect_to_login(url = nil)
    raise "Why?"
    reset_session
    @current_user = nil
    redirect_to(new_user_session_url(:redirect => url))
  end

  def redirect_to_back(options={})
    if !params[:redirect].blank?
      redirect_to params[:redirect], options
    elsif session[:history].is_a?(Array) and session[:history][1].is_a?(Hash)
      session[:history].delete_at(0) unless options[:direct]
      redirect_to session[:history][0][:path], options
    elsif request.referer and request.referer != request.path
      redirect_to request.referer, options
    else
      redirect_to(root_url)
    end
  end

  def redirect_to_current(options={})
    redirect_to_back(options.merge(:direct => true))
  end

  # # Autocomplete helper
  # def self.autocomplete_for(model_name, column)
  #   item =  model_name.to_s
  #   items = item.pluralize
  #   items = "many_#{items}" if items == item
  #   code =  "def #{__method__}_#{model_name}_#{column}\n"
  #   code << "  if params[:term]\n"
  #   code << "    pattern = '%'+params[:term].to_s.mb_chars.downcase.strip.gsub(/\s+/,'%').gsub(/[#{String::MINUSCULES.join}]/,'_')+'%'\n"
  #   code << "    @#{items} = #{model_name.to_s.classify}.select('DISTINCT #{column}').where('LOWER(#{column}) LIKE ?', pattern).order('#{column} ASC').limit(80)\n"
  #   code << "    respond_to do |format|\n"
  #   code << "      format.html { render :inline => \"<%=content_tag(:ul, @#{items}.map { |#{item}| content_tag(:li, #{item}.#{column})) }.join.html_safe)%>\" }\n"
  #   code << "      format.json { render :json => @#{items}.collect{|#{item}| #{item}.#{column}}.to_json }\n"
  #   code << "    end\n"
  #   code << "  else\n"
  #   code << "    render :text => '', :layout => true\n"
  #   code << "  end\n"
  #   code << "end\n"
  #   class_eval(code, "#{__FILE__}:#{__LINE__}")
  # end

  # Autocomplete helper
  def self.autocomplete_for(column, options = {})
    model = (options.delete(:model) || controller_name).to_s.classify.constantize
    item =  model.name.underscore.to_s
    items = item.pluralize
    items = "many_#{items}" if items == item
    code =  "def #{__method__}_#{column}\n"
    code << "  if params[:term]\n"
    code << "    pattern = '%'+params[:term].to_s.mb_chars.downcase.strip.gsub(/\s+/,'%').gsub(/[#{String::MINUSCULES.join}]/,'_')+'%'\n"
    code << "    @#{items} = #{model.name}.select('DISTINCT #{column}').where('LOWER(#{column}) LIKE ?', pattern).order('#{column} ASC').limit(80)\n"
    code << "    respond_to do |format|\n"
    code << "      format.html { render :inline => \"<%=content_tag(:ul, @#{items}.map { |#{item}| content_tag(:li, #{item}.#{column})) }.join.html_safe)%>\" }\n"
    code << "      format.json { render :json => @#{items}.collect{|#{item}| #{item}.#{column}}.to_json }\n"
    code << "    end\n"
    code << "  else\n"
    code << "    render :text => '', :layout => true\n"
    code << "  end\n"
    code << "end\n"
    class_eval(code, "#{__FILE__}:#{__LINE__}")
  end


  # Build standard RESTful actions to manage records of a model
  def self.manage_restfully(defaults = {})
    name = self.controller_name
    t3e = defaults.delete(:t3e)
    url = defaults.delete(:redirect_to)
    xhr = defaults.delete(:xhr)
    durl = defaults.delete(:destroy_to)
    record_name = name.to_s.singularize
    model = name.to_s.classify.constantize

    aname = self.controller_path.underscore
    base_url = aname.gsub(/\//, "_")

    # url = base_url.singularize + "_url(@#{record_name})" if url.blank?

    if url.blank?
      named_url = base_url.singularize + "_url"
      if instance_methods(true).include?(:show)
        url = "{:controller => :'#{aname}', :action => :show, :id => 'id'}"
      else
        named_url = base_url + "_url"
        url = named_url if instance_methods(true).include?(named_url.to_sym)
      end
    end


    render_form_options = []
    if defaults.has_key?(:partial)
      render_form_options << ":partial => '#{defaults.delete(:partial)}'"
    end
    if defaults.has_key?(:multipart)
      render_form_options << ":multipart => true" if defaults.delete(:multipart)
    end
    render_form = "render(" + render_form_options.join(", ") + ")"

    code = ''

    code << "def new\n"
    values = model.accessible_attributes.to_a.inject({}) do |hash, attr|
      hash[attr] = "params[:#{attr}]" unless attr.blank? or attr.to_s.match(/_attributes$/)
      hash
    end.merge(defaults).collect{|k,v| ":#{k} => (#{v})"}.join(", ")
    code << "  @#{record_name} = #{model.name}.new(#{values})\n"
    if xhr
      code << "  if request.xhr?\n"
      code << "    render :partial => #{xhr.is_a?(String) ? xhr.inspect : 'detail_form'.inspect}\n"
      code << "  else\n"
      code << "    #{render_form}\n"
      code << "  end\n"
    else
      code << "  #{render_form}\n"
    end
    code << "end\n"

    code << "def create\n"
    code << "  @#{record_name} = #{model.name}.new(params[:#{record_name}])\n"
    # code << "  @#{record_name}.save!\n"
    code << "  return if save_and_redirect(@#{record_name}#{', :url => '+url if url})\n"
    code << "  #{render_form}\n"
    code << "end\n"

    # this action updates an existing record with a form.
    code << "def edit\n"
    code << "  return unless @#{record_name} = find_and_check(:#{name})\n"
    code << "  t3e(@#{record_name}.attributes"+(t3e ? ".merge("+t3e.collect{|k,v| ":#{k} => (#{v})"}.join(", ")+")" : "")+")\n"
    code << "  #{render_form}\n"
    code << "end\n"

    code << "def update\n"
    code << "  return unless @#{record_name} = find_and_check(:#{name})\n"
    code << "  t3e(@#{record_name}.attributes"+(t3e ? ".merge("+t3e.collect{|k,v| ":#{k} => (#{v})"}.join(", ")+")" : "")+")\n"
    code << "  @#{record_name}.attributes = params[:#{record_name}]\n"
    code << "  return if save_and_redirect(@#{record_name}#{', :url => ('+url+')' if url})\n"
    code << "  #{render_form}\n"
    code << "end\n"

    # this action deletes or hides an existing record.
    code << "def destroy\n"
    code << "  return unless @#{record_name} = find_and_check(:#{name})\n"
    if model.instance_methods.include?("destroyable?")
      code << "  if @#{record_name}.destroyable?\n"
      code << "    #{model.name}.destroy(@#{record_name}.id)\n"
      code << "    notify_success(:record_has_been_correctly_removed)\n"
      code << "  else\n"
      code << "    notify_error(:record_cannot_be_removed)\n"
      code << "  end\n"
    else
      code << "  #{model.name}.destroy(@#{record_name}.id)\n"
      code << "  notify_success(:record_has_been_correctly_removed)\n"
    end
    # code << "  redirect_to #{durl ? durl : model.name.underscore.pluralize+'_url'}\n"
    code << "  #{durl ? 'redirect_to '+durl : 'redirect_to_current'}\n"
    code << "end\n"

    # code.split("\n").each_with_index{|l, x| puts((x+1).to_s.rjust(4)+": "+l)}
    unless Rails.env.production?
      file = Rails.root.join("tmp", "auto-rest", "manage-restfully-#{controller_name}.rb")
      FileUtils.mkdir_p(file.dirname)
      File.open(file, "wb") do |f|
        f.write code
      end
    end

    class_eval(code)
  end


  # Build standard actions to manage records of a model
  def self.manage_restfully_list(order_by=:id)
    name = self.controller_name
    record_name = name.to_s.singularize
    model = name.to_s.singularize.classify.constantize
    records = model.name.underscore.pluralize
    raise ArgumentError.new("Unknown column for #{model.name}") unless model.columns_hash[order_by.to_s]
    code = ''

    sort = ""
    position, conditions = "#{record_name}_position_column", "#{record_name}_conditions"
    sort << "#{position}, #{conditions} = #{record_name}.position_column, #{record_name}.scope_condition\n"
    sort << "#{records}_count = #{model.name}.count(#{position}, :conditions => #{conditions})\n"
    sort << "unless #{records}_count == #{model.name}.count(#{position}, :conditions => #{conditions}, :distinct => true) and #{model.name}.sum(#{position}, :conditions => #{conditions}) == #{records}_count*(#{records}_count+1)/2\n"
    sort << "  #{records} = #{model.name}.find(:all, :conditions => #{conditions}, :order => #{position}+', #{order_by}')\n"
    sort << "  #{records}.each_index do |i|\n"
    sort << "    #{model.name}.update_all({#{position} => i+1}, {:id => #{records}[i].id})\n"
    sort << "  end\n"
    sort << "end\n"

    code << "def up\n"
    code << "  return unless #{record_name} = find_and_check(:#{record_name})\n"
    code << "  #{record_name}.move_higher\n"
    code << sort.gsub(/^/, "  ")
    code << "  redirect_to_current\n"
    code << "end\n"

    code << "def down\n"
    code << "  return unless #{record_name} = find_and_check(:#{record_name})\n"
    code << "  #{record_name}.move_lower\n"
    code << sort.gsub(/^/, "  ")
    code << "  redirect_to_current\n"
    code << "end\n"

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
    code << "c = ['1=1']\n"
    code << "session[:#{model.name.underscore}_key].to_s.lower.split(/\\s+/).each{|kw| kw='%'+kw+'%';"
    # This item is incompatible with MySQL...
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
    code = "\n#{conditions} = ['1=1']\n"
    columns = search.collect{|t, cs| cs.collect{|c| "#{ActiveRecord::Base.connection.quote_table_name(t.is_a?(Symbol) ? t.to_s.classify.constantize.table_name : t)}.#{ActiveRecord::Base.connection.quote_column_name(c)}"}}.flatten
    code << "for kw in #{variable}.to_s.lower.split(/\\s+/)\n"
    code << "  kw = '%'+kw+'%'\n"
    filters = columns.collect do |x|
      # This item is incompatible with MySQL...
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
    code << "  #{conditions}[0] += ' AND (#{filters.join(' OR ')})'\n"
    code << "  #{conditions} += #{values}\n"
    code << "end\n"
    code << "#{conditions}"
    return code
  end


  # accountancy -> accounts_range_crit
  def self.accounts_range_crit(variable, conditions='c')
    variable = "session[:#{variable}]" unless variable.is_a? String
    code = ""
    # code << "ac, #{variable}[:accounts] = \n"
    code << "#{conditions}[0] += ' AND '+Account.range_condition(#{variable}[:accounts])\n"
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
    code << "c=['1=1']\n"
    code << journal_period_crit("params")
    code << journal_entries_states_crit("params")
    code << accounts_range_crit("params")
    code << journals_crit("params")
    code << "c\n"
    # list = code.split("\n"); list.each_index{|x| puts((x+1).to_s.rjust(4)+": "+list[x])}
    return code # .gsub(/\s*\n\s*/, ";")
  end


  # accountancy -> journal_entries_states_crit
  def self.journal_entries_states_crit(variable, conditions='c')
    variable = "session[:#{variable}]" unless variable.is_a? String
    code = ""
    code << "#{conditions}[0] += ' AND '+JournalEntry.state_condition(#{variable}[:states])\n"
    return code
  end

  # accountancy -> journal_period_crit
  def self.journal_period_crit(variable, conditions='c')
    variable = "session[:#{variable}]" unless variable.is_a? String
    code = ""
    code << "#{conditions}[0] += ' AND '+JournalEntry.period_condition(#{variable}[:period], #{variable}[:started_on], #{variable}[:stopped_on])\n"
    return code
  end

  # accountancy -> journals_crit
  def self.journals_crit(variable, conditions='c')
    variable = "session[:#{variable}]" unless variable.is_a? String
    code = ""
    code << "#{conditions}[0] += ' AND '+JournalEntry.journal_condition(#{variable}[:journals])\n"
    return code
  end

  # management -> moved_conditions
  def self.moved_conditions(model, state='params[:s]')
    code = "\n"
    code << "c||=['1=1']\n"
    code << "if #{state}=='unconfirmed'\n"
    code << "  c[0] += ' AND moved_on IS NULL'\n"
    code << "elsif #{state}=='confirmed'\n"
    code << "  c[0] += ' AND moved_on IS NOT NULL'\n"
    code << "end\n"
    code << "c\n"
    return code
  end

  # management -> prices_conditions
  def self.prices_conditions(options={})
    code = "conditions=[]\n"
    code << "if session[:supplier_id] == 0 \n "
    code << " conditions = ['#{ProductPriceTemplate.table_name}.active = ?', true] \n "
    code << "else \n "
    code << " conditions = ['#{ProductPriceTemplate.table_name}.supplier_id = ? AND #{ProductPriceTemplate.table_name}.active = ?', session[:supplier_id], true]"
    code << "end \n "
    code << "conditions \n "
    code
  end

end
