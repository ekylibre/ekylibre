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

module Backend
  class ContractsController < Backend::BaseController
    manage_restfully currency: 'Preference[:currency]'.c

    respond_to :csv, :ods, :xlsx, :pdf, :odt, :docx, :html, :xml, :json

    # params:
    #   :q Text search
    #   :state State search
    #   :period Two dates with "_" separator
    def self.conditions
      code = ''
      code = search_conditions(contracts: %i[pretax_amount number description], entities: %i[number full_name]) + " ||= []\n"
      code << "if params[:responsible_id].to_i > 0\n"
      code << "  c[0] += \" AND \#{Contract.table_name}.responsible_id = ?\"\n"
      code << "  c << params[:responsible_id]\n"
      code << "end\n"
      code << "c\n "
      code.c
    end

    list(conditions: conditions, joins: :supplier, line_class: :status, order: { created_at: :desc, number: :desc }) do |t|
      t.action :edit
      t.action :destroy, if: :destroyable?
      t.column :number, url: true
      t.column :reference_number, url: true
      t.column :created_at
      t.column :started_on
      t.column :stopped_on, hidden: true
      t.column :supplier, url: true
      t.column :responsible, url: true, hidden: true
      t.column :description, hidden: true
      t.status
      t.column :state_label
      t.column :pretax_amount, currency: true
    end

    list(:items, model: :contract_items, conditions: { contract_id: 'params[:id]'.c }) do |t|
      t.column :variant, url: true
      t.column :quantity
      t.column :unit_pretax_amount, currency: true
      t.column :pretax_amount, currency: true
    end

    list(:receptions, model: :receptions, children: :items, conditions: { contract_id: 'params[:id]'.c }) do |t|
      t.action :edit, if: :draft?
      t.action :destroy, if: :draft?
      t.column :number, url: true
      t.column :reference_number, url: true
      t.column :content_sentence, label: :contains
      t.column :address, hidden: true
      t.column :given_at
      t.status
      t.column :pretax_amount, currency: true
    end

    Contract.state_machine.events.each do |event|
      define_method event.name do
        fire_event(event.name)
      end
    end
  end
end
