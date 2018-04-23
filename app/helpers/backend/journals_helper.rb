# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2011 Brice Texier, Thibaud Merigon
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
  module JournalsHelper
    def budget_columns_count(value = 1)
      if current_user.can?(:read, :activities) && ActivityBudget.opened.any?
        return value
      end
      0
    end

    def team_columns_count(value = 1)
      return value if Team.any?
      0
    end

    def journals_tag
      render partial: 'backend/journals/index'
    end

    # Show the 3 modes of view for a journal
    def journal_view_tag
      code = content_tag(:dt, :view.tl)
      for mode in controller.journal_views
        code << content_tag(:dd, link_to(h("journal_view.#{mode}".tl(default: ["labels.#{mode}".to_sym, mode.to_s.humanize])), params.merge(view: mode)), (@journal_view == mode ? { class: :active } : nil)) # content_tag(:i) + " " +
      end
      content_tag(:dl, code, id: 'journal-views')
    end

    # Create a widget with all the possible periods
    def journal_period_crit(*args)
      options = args.extract_options!
      name = args.shift || :period
      value = if preference = current_user.preferences.find_by(name: 'accounts_interval.period') && args.present? && args.first[:use_search_preference]
                preference.value
              elsif current_user.preferences.find_by(name: 'accounts_interval.started_on').present? && args.present? && args.first[:use_search_preference]
                :interval
              else
                args.shift
              end

      configuration = { custom: :interval }.merge(options)
      configuration[:id] ||= name.to_s.gsub(/\W+/, '_').gsub(/(^_|_$)/, '')
      value ||= params[name] || options[:default]
      list = []
      list << [:all_periods.tl, 'all']
      for year in FinancialYear.reorder(started_on: :desc)
        list << [year.code, year.started_on.to_s << '_' << year.stopped_on.to_s]
        list2 = []
        date = year.started_on
        while date < year.stopped_on && date < Time.zone.today
          date2 = date.end_of_month
          list2 << [:month_period.tl(year: date.year, month: 'date.month_names'.t[date.month], code: year.code), date.to_s << '_' << date2.to_s]
          date = date2 + 1
        end
        list += list2.reverse
      end
      code = ''
      code << content_tag(:label, options[:label] || :period.tl, for: configuration[:id]) + ' '
      fy = FinancialYear.current
      params[:period] = value ||= :all # (fy ? fy.started_on.to_s + "_" + fy.stopped_on.to_s : :all)
      custom_id = "#{configuration[:id]}_#{configuration[:custom]}"
      toggle_method = "toggle#{custom_id.camelcase}"
      if configuration[:custom]
        params[:started_on] = begin
                                current_user.preferences.value('accounts_interval.started_on')&.to_date || params[:started_on].to_date
                              rescue
                                (fy ? fy.started_on : Time.zone.today)
                              end
        params[:stopped_on] = begin
                                current_user.preferences.value('accounts_interval.stopped_on')&.to_date || params[:stopped_on].to_date
                              rescue
                                (fy ? fy.stopped_on : Time.zone.today)
                              end
        params[:stopped_on] = params[:started_on] if params[:started_on] > params[:stopped_on]
        list.insert(0, [configuration[:custom].tl, configuration[:custom]])
      end

      if replacement = options.delete(:include_blank)
        list.insert(0, [(replacement.is_a?(Symbol) ? tl(replacement) : replacement.to_s), ''])
      end

      code << select_tag(name, options_for_select(list, value), :id => configuration[:id], 'data-show-value' => "##{configuration[:id]}_")

      code << ' ' << content_tag(:span, :manual_period.tl(start: date_field_tag(:started_on, params[:started_on], size: 10), finish: date_field_tag(:stopped_on, params[:stopped_on], size: 10)).html_safe, id: custom_id)
      code.html_safe
    end

    # Create a widget to select states of entries (and entry items)
    def journal_entries_states_crit(*_args)
      code = ''
      code << content_tag(:label, :journal_entries_states.tl)
      states = JournalEntry.states
      params[:states] = {} unless params[:states].is_a? Hash
      no_state = !states.detect { |x| params[:states].key?(x) }
      for state in states
        key = state.to_s
        name = "states[#{key}]"
        id = "states_#{key}"
        if active = (params[:states][key] == '1' || no_state)
          params[:states][key] = '1'
        else
          params[:states].delete(key)
        end
        code << ' ' << check_box_tag(name, '1', active, id: id)
        code << ' ' << content_tag(:label, JournalEntry.state_label(state), for: id)
      end
      code.html_safe
    end

    # Create a widget to select some journals
    def journals_crit(*_args)
      code = ''
      field = :journals
      code << content_tag(:label, Backend::JournalsController.human_action_name(:index))
      journals = Journal.all
      params[field] = {} unless params[field].is_a? Hash
      no_journal = !journals.detect { |x| params[field].key?(x.id.to_s) }
      for journal in journals
        key = journal.id.to_s
        name = "#{field}[#{key}]"
        id = "#{field}_#{key}"
        if active = (params[field][key] == '1' || no_journal)
          params[field][key] = '1'
        else
          params[field].delete(key)
        end
        code << ' ' << check_box_tag(name, '1', active, id: id)
        code << ' ' << content_tag(:label, journal.name, for: id)
      end
      code.html_safe
    end

    def mask_lettered_items_button(*args)
      options = args.extract_options!
      list_id = args.shift || options[:list_id] || :journal_entry_items
      mask_context = options[:context] || list_id
      options[:controller] ||= controller_path
      label_tag do
        check_box_tag(:masked, 'true', current_user.mask_lettered_items?(controller: options[:controller].dup, context: mask_context),
                      data: {
                        mask_lettered_items: '#' + list_id.to_s,
                        preference_url: url_for(controller: options[:controller], action: :mask_lettered_items, context: mask_context)
                      }) +
          :mask_lettered_items.tl
      end
    end
  end
end
