# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple ERP
# Copyright (C) 2008-2011 Brice Texier, Thibaud Merigon
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

class Backend::MandatesController < BackendController
  manage_restfully

  autocomplete_for :family
  autocomplete_for :organization
  autocomplete_for :title

  unroll

  def self.mandates_conditions(options={})
    code = ""
    code += "conditions = ['1=1']\n"
    code += "if session[:mandates].is_a? Hash\n"
    code += "  unless session[:mandates][:organization].blank?\n"
    code += "    conditions[0] += ' AND organization = ?'\n"
    code += "    conditions << session[:mandates][:organization]\n"
    code += "  end\n"
    code += "  unless session[:mandates][:viewed_on].blank?\n"
    code += "    conditions[0] += ' AND (? BETWEEN COALESCE(started_on, stopped_on, ?)  AND COALESCE(stopped_on, ?) )'\n"
    code += "    conditions << session[:mandates][:viewed_on]\n"
    code += "    conditions << session[:mandates][:viewed_on]\n"
    code += "    conditions << session[:mandates][:viewed_on]\n"
    code += "  end\n"
    code += "end\n"
    code += "conditions\n"
    code
  end

  list(:conditions => mandates_conditions) do |t|
    t.column :full_name, :through => :entity, :url => true
    t.column :title
    t.column :organization
    t.column :family
    t.column :started_on
    t.column :stopped_on
    t.action :edit
    t.action :destroy
  end

  # Displays the main page with the list of mandates
  def index
    notify_now(:no_existing_mandates) if Mandate.count.zero?
    @organizations = Mandate.select(' DISTINCT organization ')
    session[:mandates] ||= {}
    session[:mandates][:organization] = params[:organization]||session[:mandates][:organization]||''
    session[:mandates][:viewed_on] = (params[:viewed_on]||session[:mandates][:viewed_on]).to_date rescue Date.today
  end

  def configure
    notify_now(:no_existing_mandates) if Mandate.count.zero?

    filters = { :no_filters => '', :contains => '%X%', :is => 'X', :begins => 'X%', :finishes => '%X', :not_contains => '%X%', :not_is  => 'X', :not_begins => 'X%', :not_finishes => '%X' }
    shortcuts = { :fam => :family, :org => :organization, :tit => :title }
    @filters = filters.collect{|f,k| [tc(f), f]}.sort

    if request.post?
      notify_error_now(:specify_updates) unless params[:columns].detect{|k,v| !v[:update].blank?}
      notify_error_now(:specify_filter)  unless params[:columns].detect{|k,v| !v[:filter].blank?}
      return if has_notifications?

      conditions = ["1=1"]
      updates = "updated_at = CURRENT_TIMESTAMP"
      for p, v in params[:columns] do
        if v[:filter].to_sym != :no_filters
          conditions[0] += " AND LOWER(#{p}) "+(v[:filter].to_s.match(/^not_/) ? "NOT " : "").to_s+"LIKE ?"
          conditions << filters[v[:filter].to_sym].gsub(/X/, v[:search].lower.to_s)
        end
        updates += ", #{p} = '#{v[:new_value].gsub(/\'/,'\'\'').gsub(/\@...\@/){|x| '\'||'+shortcuts[x[1..-2].to_sym].to_s+'||\''}}'" if v[:update]
      end
      Mandate.update_all(updates, conditions)
    end

  end

end
