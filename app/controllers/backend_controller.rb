# encoding: utf-8
# == License
# Ekylibre - Simple agricultural ERP
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
  include Unrollable, RestfullyManageable
  protect_from_forgery

  before_filter :authenticate_user!
  before_filter :authorize_user!
  before_filter :set_versioner
  before_filter :themize

  layout :dialog_or_not

  include Userstamp

  protected

  # Overrides respond_with method in order to use specific parameters for reports
  # Adds :with and :key, :name parameters
  def respond_with_with_template(*resources, &block)
    resources << {} unless resources.last.is_a?(Hash)
    resources[-1][:with] = (params[:template].to_s.match(/^\d+$/) ? params[:template].to_i : params[:template].to_s) if params[:template]
    for param in [:key, :name]
      resources[-1][param] = params[param] if params[param]
    end
    respond_with_without_template(*resources, &block)
  end

  hide_action :respond_with, :respond_with_without_template
  alias_method_chain :respond_with, :template

  # def render_restfully_form(options = {})
  #   # operation = self.action_name.to_sym
  #   # operation = (operation == :create ? :new : operation == :update ? :edit : operation)
  #   # partial   = options[:partial] || 'form'
  #   # options[:form_options] = {} unless options[:form_options].is_a?(Hash)
  #   # options[:form_options][:multipart] = true if options[:multipart]
  #   # render(:template => options[:template]||"forms/#{operation}", :locals => {:operation => operation, :partial => partial, :options => options})
  #   render(:template  => "forms/#{self.action_name}", :locals => {:options => options})
  # end


  # Find a record with the current environment or given parameters and check availability of it
  def find_and_check(*args)
    options = args.extract_options!
    model = args.shift || options[:model] || self.controller_name.singularize
    id    = args.shift || options[:id] || params[:id]
    begin
      return model.to_s.camelize.constantize.find(id)
    rescue
      notify_error(:unavailable_model, model: model.inspect, id: id)
      redirect_to_current
      return false
    end
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
          head :ok
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

  private

  def dialog_or_not
    return (request.xhr? ? "popover" : params[:dialog] ? "dialog" : "backend")
  end


  # Set HTTP headers to block page caching
  def no_cache
    # Change headers to force zero cache
    response.headers["Last-Modified"] = Time.now.httpdate
    response.headers["Expires"] = '0'
    # HTTP 1.0
    response.headers["Pragma"] = "no-cache"
    # HTTP 1.1 'pre-check=0, post-check=0' (IE specific)
    response.headers["Cache-Control"] = 'no-store, no-cache, must-revalidate, max-age=0, pre-check=0, post-check=0'
  end

  # # Load current user
  # def identify
  #   # Load current_user if connected
  #   @current_user = nil
  #   @current_user = User.find_by(id: session[:user_id]).readonly if session[:user_id]
  # end

  def set_versioner
    Version.current_user = current_user
  end

  def themize
    # TODO: Dynamic theme choosing
    if current_user
      if %w(margarita tekyla tekyla-sunrise).include?(params[:theme])
        current_user.prefer!("theme", params[:theme])
      end
      @current_theme = current_user.preference("theme", "tekyla").value
    else
      @current_theme = "tekyla"
    end
  end


  # Controls access to every view in Ekylibre.
  def authorize_user!
    unless current_user.administrator?
      # Get accesses matching the current action
      unless list = Ekylibre::Access.reversed_list["#{controller_path}##{action_name}"]
        return true
        notify_error(:access_denied, reason: "OUT OF SCOPE", url: request.url.inspect)
        redirect_to root_url
        return false
      end

      # Search for one of found access in rights of current user
      list &= current_user.resource_actions
      unless list.any?
        notify_error(:access_denied, reason: "RESTRICTED", url: request.url.inspect)
        redirect_to root_url
        return false
      end
    end
    return true
  end



  # # Fill the history array
  # def historize
  #   if @current_user and request.get? and not request.xhr? and params[:format].blank?
  #     session[:history] = [] unless session[:history].is_a? Array
  #     session[:history].delete_if { |h| h[:path] == request.path }
  #     session[:history].insert(0, {:title => self.human_action_name, :path => request.path}) # :url => request.url, :reverse => Ekylibre.menu.page(self.controller_name, self.action_name)
  #     session[:history].delete_at(30)
  #   end
  # end



  def search_article(article = nil)
    # session[:help_history] = [] unless session[:help_history].is_a? [].class
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
    # if file and session[:side] and article != session[:help_history].last
    #   session[:help_history] << file
    # end
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
      # elsif session[:history].is_a?(Array) and session[:history].second.is_a?(Hash)
      #   session[:history].delete_at(0) unless options[:direct]
      #   redirect_to session[:history][0][:path], options
    elsif request.referer and request.referer != request.path
      redirect_to request.referer, options
    else
      redirect_to(root_url)
    end
  end

  def redirect_to_current(options={})
    redirect_to_back(options.merge(:direct => true))
  end

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

  def self.deprecated_search_conditions(model_name, columns)
    ActiveSupport::Deprecation.warn("Use search_conditions instead of deprecated_search_conditions")
    model = model_name.to_s.classify.constantize
    columns = [columns] if [String, Symbol].include? columns.class
    columns = columns.collect{|k,v| v.collect{|x| "#{k}.#{x}"}} if columns.is_a? Hash
    columns.flatten!
    raise ArgumentError.new("Bad columns: "+columns.inspect) unless columns.is_a? Array
    code = ""
    code << "c = ['1=1']\n"
    code << "session[:#{model.name.underscore}_key].to_s.lower.split(/\\s+/).each{|kw| kw='%'+kw+'%';"
    code << "c[0] << ' AND ("+columns.collect{|x| 'LOWER(CAST('+x.to_s+' AS VARCHAR)) LIKE ?'}.join(' OR ')+")';\n"
    code << "c += [#{(['kw']*columns.size).join(',')}]"
    code << "}\n"
    code << "c"
    code.c
  end

  # search is a hash like {table: [columns...]}
  def self.search_conditions(search = {}, options={})
    conditions = options[:conditions] || 'c'
    options[:except]  ||= []
    options[:filters] ||= {}
    variable ||= options[:variable] || "params[:q]"
    tables = search.keys.select{|t| !options[:except].include? t}
    code = "\n#{conditions} = ['1=1']\n"
    columns = search.collect do |table, filtered_columns|
      filtered_columns.collect do |column|
        ActiveRecord::Base.connection.quote_table_name(table.is_a?(Symbol) ? table.to_s.classify.constantize.table_name : table) +
          "." +
          ActiveRecord::Base.connection.quote_column_name(column)
      end
    end.flatten
    code << "for kw in #{variable}.to_s.lower.split(/\\s+/)\n"
    code << "  kw = '%'+kw+'%'\n"
    filters = columns.collect do |x|
      'LOWER(CAST('+x.to_s+' AS VARCHAR)) LIKE ?'
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
    return code.c
  end


  # accountancy -> accounts_range_crit
  def self.accounts_range_crit(variable, conditions='c')
    variable = "params[:#{variable}]" unless variable.is_a? String
    code = ""
    # code << "ac, #{variable}[:accounts] = \n"
    code << "#{conditions}[0] += ' AND '+Account.range_condition(#{variable}[:accounts])\n"
    return code.c
  end

  # accountancy -> crit_params
  def self.crit_params(hash)
    nh = {}
    keys = JournalEntry.state_machine.states.collect{|s| s.name}
    keys += [:period, :started_at, :stopped_at, :accounts, :centralize]
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
    return code.c # .gsub(/\s*\n\s*/, ";")
  end


  # accountancy -> journal_entries_states_crit
  def self.journal_entries_states_crit(variable, conditions='c')
    variable = "params[:#{variable}]" unless variable.is_a? String
    code = ""
    code << "#{conditions}[0] += ' AND '+JournalEntry.state_condition(#{variable}[:states])\n"
    return code.c
  end

  # accountancy -> journal_period_crit
  def self.journal_period_crit(variable, conditions='c')
    variable = "params[:#{variable}]" unless variable.is_a? String
    code = ""
    code << "#{conditions}[0] += ' AND '+JournalEntry.period_condition(#{variable}[:period], #{variable}[:started_at], #{variable}[:stopped_at])\n"
    return code.c
  end

  # accountancy -> journals_crit
  def self.journals_crit(variable, conditions='c')
    variable = "params[:#{variable}]" unless variable.is_a? String
    code = ""
    code << "#{conditions}[0] += ' AND '+JournalEntry.journal_condition(#{variable}[:journals])\n"
    return code.c
  end

  # management -> moved_conditions
  def self.moved_conditions(model, state='params[:s]')
    code = "\n"
    code << "c||=['1=1']\n"
    code << "if #{state}=='unconfirmed'\n"
    code << "  c[0] += ' AND moved_at IS NULL'\n"
    code << "elsif #{state}=='confirmed'\n"
    code << "  c[0] += ' AND moved_at IS NOT NULL'\n"
    code << "end\n"
    code << "c\n"
    return code.c
  end

  # management -> shipping_conditions
  def self.shipping_conditions(model, state='params[:s]')
    code = "\n"
    code << "c||=['1=1']\n"
    code << "if #{state}=='unconfirmed'\n"
    code << "  c[0] += ' AND sent_at IS NULL'\n"
    code << "elsif #{state}=='confirmed'\n"
    code << "  c[0] += ' AND sent_at IS NOT NULL'\n"
    code << "end\n"
    code << "c\n"
    return code.c
  end

  # management -> prices_conditions
  def self.prices_conditions(options={})
    code = "conditions=[]\n"
    code << "if params[:supplier_id] == 0 \n "
    code << " conditions = ['#{ProductPriceTemplate.table_name}.active = ?', true] \n "
    code << "else \n "
    code << " conditions = ['#{ProductPriceTemplate.table_name}.supplier_id = ? AND #{ProductPriceTemplate.table_name}.active = ?', params[:supplier_id], true]"
    code << "end \n "
    code << "conditions \n "
    return code.c
  end

end
