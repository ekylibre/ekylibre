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

class Backend::ProductionSupportMarkersController < BackendController
  manage_restfully # (:t3e => {:name => :name})

  unroll includes: [{production: [:activity, :campaign, :variant]}, :storage]

  list do |t|
    t.column :campaign, url: true
    t.column :activity, url: true, hidden: true
    t.column :support, url: true
    t.column :indicator, datatype: :item
    t.column :aim
    t.column :subject_label
    t.column :derivative, hidden: true
    t.column :subject, hidden: true
    t.column :value, datatype: :measure
  end

end
