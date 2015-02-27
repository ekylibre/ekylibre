# -*- coding: utf-8 -*-
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

class Backend::DocumentsController < Backend::BaseController
  unroll

  manage_restfully

  respond_to :html, :json, :xml

  list do |t|
    t.column :number, url: true
    t.column :name, url: true
    t.column :nature
    t.column :created_at
    t.action :edit
    t.action :destroy, if: :destroyable?
  end

  list(:archives, model: :document, conditions: {:document_id => 'params[:id]'.c}) do |t|
    t.column :file_updated_at, url: {format: :pdf}
    t.column :template, url: true
    t.column :file_pages_count
    t.column :file_file_size
    t.column :file_content_text, hidden: true
    t.column :file_fingerprint, hidden: true
    t.action :destroy, if: :destroyable?
  end

end
