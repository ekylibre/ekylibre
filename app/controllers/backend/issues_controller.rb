# coding: utf-8
# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2013 David Joulin, Brice Texier
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

# -*- coding: utf-8 -*-
class Backend::IssuesController < BackendController

  manage_restfully
  manage_restfully_picture

  respond_to :pdf, :odt, :docx, :xml, :json, :html, :csv

  unroll

  list do |t|
    t.column :name, url: true
    t.column :nature
    t.column :observed_at
    t.column :target_name
    t.status
    t.column :gravity,  hidden: true
    t.column :priority, hidden: true
    t.action :edit
    t.action :new, url: {controller: :interventions, issue_id: 'RECORD.id'.c, id: nil}
    t.action :destroy, if: :destroyable?
  end

  list(:interventions, conditions: {issue_id: 'params[:id]'.c}, order: {started_at: :desc}) do |t|
    t.column :reference_name, label_method: :name, url: true
    t.column :casting
    t.column :started_at
    t.column :stopped_at, hidden: true
    t.column :natures
    t.column :state
  end

  def close
    return unless @issue = find_and_check
    if @issue.can_close?
      @issue.close
    end
    redirect_to_back
  end

  def abort
    return unless @issue = find_and_check
    if @issue.can_abort?
      @issue.abort
    end
    redirect_to_back
  end

  def reopen
    return unless @issue = find_and_check
    if @issue.can_reopen?
      @issue.reopen
    end
    redirect_to_back
  end

end
