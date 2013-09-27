# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple ERP
# Copyright (C) 2013-2013 Brice Texier
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
class Backend::PeopleController < Backend::EntitiesController
  manage_restfully

  unroll

  list do |t|
    t.column :name, url: true
  end

  # Displays the main page with the list of people.
  def index
    respond_to do |format|
      format.html
      format.xml  { render :xml => Person.all }
      format.json { render :json => Person.all }
    end
  end

  # Displays the page for one person.
  def show
    return unless @person = find_and_check
    respond_to do |format|
      format.html { t3e(@person) }
      format.xml  { render :xml => @person }
      format.json { render :json => @person }
    end
  end

end
