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

  def major_accounts_tag
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
        link_to(account.label, :action=>:accounts, :prefix=>account.number)
      end
    end
    if majors.size>1
      return content_tag(:div, majors.to_sentence, :class=>'menu major_accounts')
    end
    return ""
  end

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
        link_to(account.label, :action=>:accounts, :prefix=>account.number)
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
        url = {:action=>:journal, :id=>@journal.id, :view=>mode, :period_mode=>params[:period_mode]}
        if url[:period_mode] == "automatic"
          url[:period] = params[:period]
        else
          url[:start] = params[:start]
          url[:finish] = params[:finish]
        end
        code += link_to tc("journal_view.#{mode}"), url
      end
    end
    return content_tag(:div, code, :class=>:view)
  end

  def journal_periods_tag(value=nil)
    list = []
    for year in @current_company.financial_years
      list << [tc(:all_periods), year.started_on.to_s+"_"+Date.today.to_s] if list.empty?
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
    options_for_select(list, value)
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
