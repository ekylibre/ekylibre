# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2012-2013 David Joulin, Brice Texier
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

module Backend
  class PurchaseOrdersController < Backend::PurchasesController
  	
  	def self.purchase_orders_conditions
      code = ''
      code = search_conditions(purchase_order: %i[number reference_number supplier created_at pretax_amount], entities: %i[number full_name]) + " ||= []\n"
      code << "if params[:period].present? && params[:period].to_s != 'all'\n"
      code << "  c[0] << ' AND #{PurchaseOrder.table_name}.invoiced_at::DATE BETWEEN ? AND ?'\n"
      code << "  if params[:period].to_s == 'interval'\n"
      code << "    c << params[:started_on]\n"
      code << "    c << params[:stopped_on]\n"
      code << "  else\n"
      code << "    interval = params[:period].to_s.split('_')\n"
      code << "    c << interval.first\n"
      code << "    c << interval.second\n"
      code << "  end\n"
      code << "end\n"
      code << "if params[:state].is_a?(Array) && !params[:state].empty?\n"
      code << "  c[0] << ' AND #{PurchaseOrder.table_name}.state IN (?)'\n"
      code << "  c << params[:state]\n"
      code << "end\n "
      code << "if params[:responsible_id].to_i > 0\n"
      code << "  c[0] += ' AND #{PurchaseOrder.table_name}.responsible_id = ?'\n"
      code << "  c << params[:responsible_id]\n"
      code << "end\n"
      code << "c\n "
			code.c
    end

    list(conditions: purchase_orders_conditions, joins: :supplier, order: {created_at: :desc, number: :desc }) do |t|
    	t.action :edit
    	t.action :destroy
    	t.column :number, url: :true
      t.column :reference_number, url: true
      t.column :supplier, url: true
      t.column :created_at
      t.column :pretax_amount, currency: true, on_select: :sum, hidden: true
    end

    def index; end
  end
end
