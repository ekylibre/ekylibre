# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2013 David Joulin, Brice Texier
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

class Backend::IssuesController < Backend::BaseController
  manage_restfully t3e: { name: :target_name }, observed_at: 'Time.zone.now'.c
  manage_restfully_picture

  respond_to :pdf, :odt, :docx, :xml, :json, :html, :csv

  unroll

  list do |t|
    t.action :edit
    t.action :new, url: { controller: :interventions, issue_id: 'RECORD.id'.c, id: nil }
    t.action :destroy, if: :destroyable?
    t.column :name, url: true
    t.column :nature
    t.column :observed_at
    t.status
    t.column :gravity,  hidden: true
    t.column :priority, hidden: true
  end

  list(:interventions, conditions: { issue_id: 'params[:id]'.c }, order: { started_at: :desc }) do |t|
    t.column :reference_name, label_method: :name, url: true
    t.column :casting, hidden: true
    t.column :started_at
    t.column :stopped_at, hidden: true
    t.column :production, url: true, hidden: true
    t.status
  end

  def close
    return unless @issue = find_and_check
    @issue.close if @issue.can_close?
    redirect_to_back
  end

  def abort
    return unless @issue = find_and_check
    @issue.abort if @issue.can_abort?
    redirect_to_back
  end

  def reopen
    return unless @issue = find_and_check
    @issue.reopen if @issue.can_reopen?
    redirect_to_back
  end
end
