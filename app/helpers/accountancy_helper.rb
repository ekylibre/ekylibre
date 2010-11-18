# ##### BEGIN LICENSE BLOCK #####
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
# ##### END LICENSE BLOCK #####

module AccountancyHelper


  def major_accounts_tabs_tag
    majors = []
    majors << if params[:prefix].blank?
                content_tag(:strong, tc(:all_accounts))
              else
                link_to(tc(:all_accounts), :action=>:accounts, :prefix=>nil)
              end
    majors += @current_company.major_accounts.collect do |account| 
      if params[:prefix] == account.number.to_s
        content_tag(:strong, account.label)
      else
        link_to(account.label, params.merge(:action=>:accounts, :prefix=>account.number))
      end
    end
    if majors.size>0
      return content_tag(:div, majors.join.html_safe, :class=>'major-accounts')
    end
    return ""
  end


  def journals_tag
    render :partial=>"journals"
  end


  def journal_view_tag
    code = content_tag(:span, tg(:view))
    for mode in controller.journal_views
      if @journal_view == mode
        code += content_tag(:strong, tc("journal_view.#{mode}"))
      else
        code += link_to tc("journal_view.#{mode}"), params.merge(:view=>mode)
      end
    end
    return content_tag(:div, code, :class=>:view)
  end

  # Create a widget with all the possible periods
  def journal_period_crit(name=:period, value=nil, options={})
    configuration = {:custom=>:interval}
    configuration.update(options) if options.is_a?(Hash)
    configuration[:id] ||= name.to_s.gsub(/\W+/, '_').gsub(/(^_|_$)/, '')
    value = params[name]
    list = []
    list << [tc(:all_periods), "all"]
    for year in @current_company.financial_years.order(:started_on)
      list << [year.code, year.started_on.to_s+"_"+year.stopped_on.to_s]
      list2 = []
      date = year.started_on
      while date<year.stopped_on and date < Date.today
        date2 = date.end_of_month
        list2 << [tc(:month_period, :year=>date.year, :month=>t("date.month_names")[date.month], :code=>year.code), date.to_s+"_"+date2.to_s]
        date = date2+1
      end
      list += list2.reverse
    end
    code = ""
    code += content_tag(:label, tc(:period), :for=>configuration[:id])+" "
    fy = @current_company.current_financial_year
    params[:period] = value = value || (fy ? fy.started_on.to_s+"_"+fy.stopped_on.to_s : :all)
    if configuration[:custom]
      params[:started_on] = params[:started_on].to_date rescue (fy ? fy.started_on : Date.today)
      params[:stopped_on] = params[:stopped_on].to_date rescue (fy ? fy.stopped_on : Date.today)
      params[:stopped_on] = params[:started_on] if params[:started_on] > params[:stopped_on]
      list.insert(0, [tc(configuration[:custom]), configuration[:custom]])
      custom_id = "#{configuration[:id]}_#{configuration[:custom]}"
      toggle_method = "toggle#{custom_id.camelcase}"
      code += select_tag(name, options_for_select(list, value), :id=>configuration[:id], :onchange=>"#{toggle_method}()", :onkeyup=>"#{toggle_method}()")
      code += " "+content_tag(:span, tc(:manual_period, :start=>calendar_field_tag(:started_on, params[:started_on], :size=>8), :finish=>calendar_field_tag(:stopped_on, params[:stopped_on], :size=>8)).html_safe, :id=>custom_id)
      code += javascript_tag("window.#{toggle_method} = function() { toggleElement('#{custom_id}', ($('#{configuration[:id]}').value == '#{configuration[:custom]}')); }; #{toggle_method}();")
    else
      code += select_tag(name, options_for_select(list, value), :id=>configuration[:id])
    end
    return code.html_safe
  end

  # Create a widget to select states of entries (and entry lines)
  def journal_entries_states_crit
    code = ""
    code += content_tag(:label, tc(:journal_entries_states))
    states = JournalEntry.states
    params[:states] = {} unless params[:states].is_a? Hash
    no_state = !states.detect{|x| params[:states].has_key?(x)}
    for state in states
      key = state.to_s
      name, id = "states[#{key}]", "states_#{key}"
      if active = (params[:states][key]=="1" or no_state)
        params[:states][key] = "1"
      else
        params[:states].delete(key)
      end
      code += " "+check_box_tag(name, "1", active, :id=>id)
      code += " "+content_tag(:label, JournalEntry.state_label(state), :for=>id)
    end
    return code.html_safe
  end

  # Create a widget to select some journals
  def journals_crit
    code, field = "", :journals
    code += content_tag(:label, Company.human_attribute_name("journals"))
    journals = @current_company.journals # .find(:all, :conditions=>["id IN (SELECT journal_id FROM journal_entry_lines WHERE company_id=? AND state=?)", @current_company.id, "draft"])
    params[field] = {} unless params[field].is_a? Hash
    no_journal = !journals.detect{|x| params[field].has_key?(x.id.to_s)}
    for journal in journals
      key = journal.id.to_s
      name, id = "#{field}[#{key}]", "#{field}_#{key}"
      if active = (params[field][key] == "1" or no_journal)
        params[field][key] = "1"
      else
        params[field].delete(key)
      end
      code += " "+check_box_tag(name, "1", active, :id=>id)
      code += " "+content_tag(:label, journal.name, :for=>id)
    end
    return code.html_safe
  end


  # Create a widget to select ranges of account
  # See Account#range_condition
  def accounts_range_crit
    id = :accounts
    params[id] = Account.clean_range_condition(params[id])
    code = ""
    code += content_tag(:label, tc(:accounts), :for=>id)
    code += " "+text_field_tag(id, params[id], :size=>30)
    return code.html_safe
  end




  def lettering_modes_tag
    code = content_tag(:span, tc("lettering_modes.title"))
    for mode in [:clients, :suppliers, :attorneys]
      if params[:id].to_s == mode.to_s
        code += content_tag(:strong, tc("lettering_modes.#{mode}"))
      else
        code += link_to tc("lettering_modes.#{mode}"), {:action=>:unmarked_journal_entry_lines, :id=>mode}
      end
    end
    return content_tag(:div, code, :class=>:view)
  end


end
