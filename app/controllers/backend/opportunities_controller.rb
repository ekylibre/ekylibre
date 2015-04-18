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

class Backend::OpportunitiesController < Backend::BaseController
  manage_restfully

  respond_to :csv, :ods, :xlsx, :pdf, :odt, :docx, :html, :xml, :json

  # management -> sales_conditions
  def self.opportunities_conditions
    code = ""
    code = search_conditions(:opportunities => [:pretax_amount, :number, :description], :entities => [:number, :full_name]) + " ||= []\n"

    code << "if params[:responsible_id].to_i > 0\n"
    code << "  c[0] += \" AND \#{Opportunity.table_name}.responsible_id = ?\"\n"
    code << "  c << params[:responsible_id]\n"
    code << "end\n"
    code << "c\n "
    return code.c
  end

  list(conditions: opportunities_conditions, joins: :client, order: {created_at: :desc, number: :desc}) do |t|
    t.column :number, url: {action: :show, step: :default}
    t.column :created_at
    t.column :dead_line_at
    t.column :client, url: true
    t.column :responsible, hidden: true
    t.column :description, hidden: true
    t.status
    t.column :state_label
    t.column :pretax_amount, currency: true
    # t.action :show, url: {format: :pdf}, image: :print
    t.action :edit, if: :draft?
    t.action :cancel, if: :cancelable?
    t.action :destroy, if: :aborted?
  end


end
