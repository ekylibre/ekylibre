# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2009-2012 Brice Texier
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

module Backend
  class BaseController < ::BaseController
    include Autocomplete
    include RestfullyManageable
    include Unrollable
    protect_from_forgery

    layout :dialog_or_not

    before_action :authenticate_user!
    before_action :authorize_user!
    before_action :set_versioner
    before_action :set_current_campaign
    before_action :set_current_period_interval
    before_action :set_current_period
    before_action :publish_backend_action
    before_action :first_run_or_backend

    include Userstamp

    helper_method :current_campaign
    helper_method :current_period_interval
    helper_method :current_period

    protected

    def first_run_or_backend
      unless(Preference.get('first_run.executed').value || params[:controller].include?('hajimari') || session[:allow_access_backend])
        redirect_to hajimari_path
      end
    end

    def current_campaign
      @current_campaign ||= current_user.current_campaign
    end

    def set_current_campaign
      if params[:current_campaign]
        campaign = Campaign.find_or_create_by!(harvest_year: params[:current_campaign])

        if current_campaign != campaign
          @current_campaign = campaign
          current_user.current_campaign = @current_campaign
        end
      end
    end

    def current_period_interval
      @current_period_interval ||= current_user.current_period_interval
    end

    def set_current_period_interval
      if params[:current_period_interval]
        period_interval = params[:current_period_interval].to_sym
        current_period_interval = current_user.current_period_interval.to_sym
        if period_interval != current_period_interval
          @current_period_interval = period_interval
          current_user.current_period_interval = @current_period_interval
        end
      end
    end

    def current_period
      @current_period ||= current_user.current_period
    end

    def set_current_period
      if params[:current_period]
        period = params[:current_period].to_date
        current_period = current_user.current_period.to_date
        if period != current_period
          @current_period = period
          current_user.current_period = @current_period.to_s
        end
      end
    end

    # Overrides respond_with method in order to use specific parameters for reports
    # Adds :with and :key, :name parameters
    def respond_with_with_template(*resources, &block)
      resources << {} unless resources.last.is_a?(Hash)
      resources[-1][:with] = (params[:template].to_s =~ /^\d+$/ ? params[:template].to_i : params[:template].to_s) if params[:template]
      for param in %i[key name]
        resources[-1][param] = params[param] if params[param]
      end
      respond_with_without_template(*resources, &block)
    end

    hide_action :respond_with, :respond_with_without_template
    alias_method_chain :respond_with, :template

    # Find a record with the current environment or given parameters and check availability of it
    def find_and_check(*args)
      options = args.extract_options!
      model = args.shift || options[:model] || controller_name.singularize
      id    = args.shift || options[:id] || params[:id]
      klass = nil
      begin
        klass = model.to_s.camelize.constantize
      rescue
        notify_error(:unexpected_resource_type, type: model.inspect)
        return false
      end
      unless klass < Ekylibre::Record::Base
        notify_error(:unexpected_resource_type, type: klass.model_name)
        return false
      end
      list = options[:scope] ? klass.send(options[:scope]) : klass
      record = list.find_by(id: id)
      unless record
        notify_error(:unavailable_resource, type: klass.model_name.human, id: id)
        redirect_to_back
        return false
      end
      record
    end

    def save_and_redirect(record, options = {})
      record.attributes = options[:attributes] if options[:attributes]
      ActiveRecord::Base.transaction do
        if options[:saved] || record.send(:save)
          response.headers['X-Return-Code'] = 'success'
          response.headers['X-Saved-Record-Id'] = record.id.to_s
          if params[:dialog]
            head :ok
            return true
          end
          if options[:notify]
            model = record.class
            notify_success(options[:notify],
                           record: model.model_name.human,
                           column: model.human_attribute_name(options[:identifier]),
                           name: record.send(options[:identifier]))
          end
          url = options[:url]
          record.reload
          if url.is_a? Hash
            url.each do |k, v|
              url[k] = (v.is_a?(CodeString) ? record.send(v) : v)
            end
          end
          redirect_to(url)
          return true
        end
      end
      response.headers['X-Return-Code'] = 'invalid'
      false
    end

    # For title I18n : t3e :)
    def t3e(*args)
      @title ||= {}
      for arg in args
        arg = arg.attributes if arg.respond_to?(:attributes)
        unless arg.is_a? Hash
          raise ArgumentError, "Hash expected, got #{arg.class.name}:#{arg.inspect}"
        end
        arg.each do |k, v|
          @title[k.to_sym] = (v.respond_to?(:localize) ? v.localize : v.to_s)
        end
      end
    end

    private

    def dialog_or_not
      (request.xhr? ? 'popover' : params[:dialog] ? 'dialog' : 'backend')
    end

    # Set HTTP headers to block page caching
    def no_cache
      # Change headers to force zero cache
      response.headers['Last-Modified'] = Time.zone.now.httpdate
      response.headers['Expires'] = '0'
      # HTTP 1.0
      response.headers['Pragma'] = 'no-cache'
      # HTTP 1.1 'pre-check=0, post-check=0' (IE specific)
      response.headers['Cache-Control'] = 'no-store, no-cache, must-revalidate, max-age=0, pre-check=0, post-check=0'
    end

    def set_versioner
      Version.current_user = current_user
    end

    def set_theme
      # TODO: Dynamic theme choosing
      if current_user
        if %w[margarita tekyla tekyla-sunrise].include?(params[:theme])
          current_user.prefer!('theme', params[:theme])
        end
        @current_theme = current_user.preference('theme', 'tekyla').value
      else
        @current_theme = 'tekyla'
      end
    end

    # Controls access to every action/view in Ekylibre.
    def authorize_user!
      unless authorized?(controller: controller_path, action: action_name)
        notify_error(:access_denied, reason: 'RESTRICTED', url: request.url.inspect)
        redirect_to root_path
        return false
      end
      true
    end

    def publish_backend_action
      Ekylibre::Hook.publish(:backend_action, action: action_name, controller: controller_name, user: current_user)
    end

    def search_article(article = nil)
      # session[:help_history] = [] unless session[:help_history].is_a? [].class
      article ||= "#{controller_path}-#{action_name}"
      file = nil
      for locale in [I18n.locale, I18n.default_locale]
        for f, attrs in Ekylibre.helps
          next if attrs[:locale].to_s != locale.to_s
          file_name = [article, article.split('-')[0] + '-index'].detect { |name| attrs[:name] == name }
          (file = f) && break if file_name.present?
        end
        break unless file.nil?
      end
      # if file and session[:side] and article != session[:help_history].last
      #   session[:help_history] << file
      # end
      file ||= article.to_sym
      file
    end

    def redirect_to_back(options = {})
      if params[:redirect].present?
        redirect_to params[:redirect], options
      elsif request.referer && request.referer != request.fullpath
        redirect_to request.referer, options
      else
        redirect_to(root_path)
      end
    end

    def redirect_to_current(options = {})
      ActiveSupport::Deprecation.warn('Use redirect_to_back instead of redirect_to_current')
      redirect_to_back(options.merge(direct: true))
    end

    def fire_event(event)
      return unless record = find_and_check
      state, msg = record.send(event)
      if state == false && msg.respond_to?(:map)
        notify_error(map.collect(&:messages).map(&:values).flatten.join(', '))
      end
      redirect_to params[:redirect] || { action: :show, id: record.id }
    end

    class << self
      # search is a hash like {table: [columns...]}
      def search_conditions(search = {}, options = {})
        conditions = options[:conditions] || 'c'
        options[:except] ||= []
        options[:filters] ||= {}
        variable ||= options[:variable] || 'params[:q]'
        tables = search.keys.reject { |t| options[:except].include? t }
        code = "\n#{conditions} = ['1=1']\n"
        columns = search.collect do |table, filtered_columns|
          filtered_columns.collect do |column|
            (table.is_a?(Symbol) ? table.to_s.classify.constantize.table_name : table).to_s +
              '.' +
              column.to_s
          end
        end.flatten
        code << "#{variable}.to_s.lower.split(/\\s+/).each do |kw|\n"
        code << "  kw = '%'+kw+'%'\n"
        filters = columns.collect do |x|
          'unaccent(' + x.to_s + '::VARCHAR) ILIKE unaccent(?)'
        end
        exp_count = columns.size
        if options[:expressions]
          filters += options[:expressions].collect do |x|
            'unaccent(' + x.to_s + ') ILIKE unaccent(?)'
          end
          exp_count += options[:expressions].count
        end
        values = '[' + (['kw'] * exp_count).join(', ') + ']'
        options[:filters].each do |k, v|
          filters << k
          v = '[' + v.join(', ') + ']' if v.is_a? Array
          values += '+' + v
        end
        if filters.any?
          code << "  #{conditions}[0] += \" AND (#{filters.join(' OR ')})\"\n"
          code << "  #{conditions} += #{values}\n"
        end
        code << "end\n"
        code << conditions.to_s
        code.c
      end

      # accountancy -> accounts_range_crit
      def accounts_range_crit(variable, conditions = 'c')
        variable = "params[:#{variable}]" unless variable.is_a? String
        code = ''
        # code << "ac, #{variable}[:accounts] = \n"
        code << "#{conditions}[0] += ' AND '+Account.range_condition(#{variable}[:accounts])\n"
        code.c
      end

      # accountancy -> crit_params
      def crit_params(hash)
        nh = {}
        keys = JournalEntry.state_machine.states.collect(&:name)
        keys += %i[period started_at stopped_at accounts centralize]
        for k, v in hash
          nh[k] = hash[k] if k.to_s.match(/^(journal|level)_\d+$/) || keys.include?(k.to_sym)
        end
        nh
      end

      # accountancy -> journal_entries_states_crit
      def journal_entries_states_crit(variable, conditions = 'c')
        variable = "params[:#{variable}]" unless variable.is_a? String
        code = ''
        code << "#{conditions}[0] += ' AND '+JournalEntry.state_condition(#{variable}[:states])\n"
        code.c
      end

      # accountancy -> journal_period_crit
      def journal_period_crit(variable, conditions = 'c')
        variable = "params[:#{variable}]" unless variable.is_a? String
        code = ''
        code << "#{conditions}[0] += ' AND '+JournalEntry.period_condition(#{variable}[:period], #{variable}[:started_on], #{variable}[:stopped_on])\n"
        code.c
      end

      # accountancy -> journals_crit
      def journals_crit(variable, conditions = 'c')
        variable = "params[:#{variable}]" unless variable.is_a? String
        code = ''
        code << "#{conditions}[0] += ' AND '+JournalEntry.journal_condition(#{variable}[:journals])\n"
        code.c
      end

      def journal_letter_crit(variable, _conditions = 'c', _table_name = nil)
        variable = "params[:#{variable}]" unless variable.is_a? String
        code = ''
        code << "unless #{variable}[:lettering_state].blank?\n"
        code << "  #{variable}[:lettering_state].each_with_index do |current_lettering_state, index|\n"
        code << "    if index == 0\n"
        code << "      c[0] << ' AND('\n"
        code << "      if current_lettering_state == 'lettered'\n"
        code << "        c[0] << '(#{JournalEntryItem.table_name}.letter IS NOT NULL AND #{JournalEntryItem.table_name}.letter NOT ILIKE ?)'\n"
        code << "        c << '%*'\n"
        code << "      end\n"

        code << "      if current_lettering_state == 'unlettered'\n"
        code << "        c[0] << '#{JournalEntryItem.table_name}.letter IS NULL'\n"
        code << "      end\n"

        code << "      if current_lettering_state == 'partially_lettered'\n"
        code << "        c[0] << '(#{JournalEntryItem.table_name}.letter IS NOT NULL AND #{JournalEntryItem.table_name}.letter ILIKE ?)'\n"
        code << "        c << '%*'\n"
        code << "      end\n"
        code << "    else\n"
        code << "      if current_lettering_state == 'lettered'\n"
        code << "        c[0] << ' OR (#{JournalEntryItem.table_name}.letter IS NOT NULL AND #{JournalEntryItem.table_name}.letter NOT ILIKE ?)'\n"
        code << "        c << '%*'\n"
        code << "      end\n"

        code << "      if current_lettering_state == 'unlettered'\n"
        code << "        c[0] << ' OR #{JournalEntryItem.table_name}.letter IS NULL'\n"
        code << "      end\n"

        code << "      if current_lettering_state == 'partially_lettered'\n"
        code << "        c[0] << ' OR (#{JournalEntryItem.table_name}.letter IS NOT NULL AND #{JournalEntryItem.table_name}.letter ILIKE ?)'\n"
        code << "        c << '%*'\n"
        code << "      end\n"
        code << "    end\n"
        code << "  end\n"
        code << "  c[0] << ')'\n"
        code << "end\n"
        code.c
      end

      def amount_range_crit(variable, _conditions = 'c')
        variable = "params[:#{variable}]" unless variable.is_a? String
        code = ''
        code << "unless #{variable}[:minimum_amount].blank? && #{variable}[:maximum_amount].blank?\n"
        code << "  if #{variable}[:minimum_amount].blank?\n"
        code << "    c[0] << ' AND (#{JournalEntryItem.table_name}.absolute_credit <= ' + params[:maximum_amount] + ' AND #{JournalEntryItem.table_name}.absolute_debit <= ' + params[:maximum_amount] + ')'\n"
        code << "  end\n"

        code << "  if #{variable}[:maximum_amount].blank?\n"
        code << "    c[0] << ' AND (#{JournalEntryItem.table_name}.absolute_credit >= ' + params[:minimum_amount] + ' OR #{JournalEntryItem.table_name}.absolute_debit >= ' + params[:minimum_amount] + ')'\n"
        code << "  end\n"

        code << "  if !#{variable}[:minimum_amount].blank? && !#{variable}[:maximum_amount].blank?\n"
        code << "    c[0] << ' AND ((#{JournalEntryItem.table_name}.absolute_credit >= ' + params[:minimum_amount] + ' AND #{JournalEntryItem.table_name}.absolute_credit <= ' + params[:maximum_amount] + ') OR (#{JournalEntryItem.table_name}.absolute_debit >= ' + params[:minimum_amount] + ' AND #{JournalEntryItem.table_name}.absolute_debit <= ' + params[:maximum_amount] +'))'\n"
        code << "  end\n"

        code << "end\n"

        code.c
      end
    end
  end
end
