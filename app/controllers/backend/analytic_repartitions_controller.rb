# coding: utf-8
# == License
# Ekylibre - Simple ERP
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

class Backend::AnalyticRepartitionsController < BackendController
  manage_restfully

  unroll

  list do |t|
    t.column :affected_on
    t.column :production, url: true
    # t.column :journal_entry_item, url: true
    t.column :state
    t.action :show, :url => {:format => :pdf}, :image => :print
    t.action :edit
    t.action :destroy, :if => :destroyable?
  end

  # Displays the main page with the list of analytic_repartitions.
  def index
    if Production.count.zero?
      notify(:need_to_create_productions)
      redirect_to :controller => :productions
      return
    end
    respond_to do |format|
      format.html
      format.xml  { render :xml => AnalyticRepartition.all }
      format.json { render :json => AnalyticRepartition.all }
    end
  end

end
