# -*- coding: utf-8 -*-
# == License
# Ekylibre ERP - Simple agricultural ERP
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

class Backend::DocumentTemplatesController < BackendController
  manage_restfully language: "Preference[:language]".c, except: :show

  unroll

  list(order: :name) do |t|
    t.column :active
    t.column :name
    t.column :nature
    t.column :by_default
    t.column :archiving
    t.column :language
    t.action :edit
    t.action :destroy, if: :destroyable?
  end

  # Loads ou reloads.all managed document templates
  def load
    DocumentTemplate.load_defaults
    notify_success(:update_is_done)
    redirect_to action: :index
  end

end
