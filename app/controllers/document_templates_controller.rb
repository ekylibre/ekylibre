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

class DocumentTemplatesController < AdminController
  manage_restfully :country => "Entity.of_company.country", :language => "Entity.of_company.language"

  unroll_all

  list(:order => "nature, name") do |t|
    t.column :active
    t.column :name
    t.column :code
    t.column :family
    t.column :nature
    t.column :by_default
    t.column :to_archive
    t.column :language
    t.column :country
    t.action :print, :format => :pdf
    t.action :duplicate, :method => :post
    t.action :edit
    t.action :destroy, :if => :destroyable?
  end

  # Displays the main page with the list of document templates
  def index
  end

  def duplicate
    return unless document_template = find_and_check(:document_template)
    copy = document_template.duplicate
    redirect_to :action => :edit, :id => copy.id
  end

  def print
    return unless @document_template = find_and_check(:document_template)
    send_data @document_template.sample, :filename => @document_template.name.simpleize, :type => Mime::PDF, :disposition => 'inline'
  end

  def load
    DocumentTemplate.load_defaults
    notify_success(:update_is_done)
    redirect_to :action => :index
  end

end
