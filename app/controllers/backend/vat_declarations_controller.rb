# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2016 Brice Texier, David Joulin
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
  class VatDeclarationsController < Backend::BaseController
    manage_restfully

    unroll

    list(line_class: :status, order: { created_at: :desc, number: :desc }) do |t|
      t.action :edit
      t.action :destroy, if: :destroyable?
      t.column :number, url: true
      t.column :responsible
      t.column :reference_number, url: true
      t.column :created_at
      t.column :started_on
      t.column :stopped_on
      t.column :description, hidden: true
      t.status
    end

    list(:items, model: :vat_declaration_items, conditions: { vat_declaration_id: 'params[:id]'.c }) do |t|
      t.column :tax, url: true
      t.column :deductible_vat_amount, currency: true
      t.column :collected_vat_amount, currency: true
    end

    # Displays details of one vat declaration selected with +params[:id]+
    def show
      return unless @vat_declaration = find_and_check
      respond_with(@vat_declaration, methods: [],
                              include: {}) do |format|
        format.html do
          t3e @vat_declaration.attributes
        end
      end
    end

    def new
      unless financial_year = FinancialYear.current || FinancialYear.opened.first
        notify_error :need_an_opened_financial_year_to_start_new_vat_declaration
        redirect_to action: :index
        return
      end
      @vat_declaration = VatDeclaration.new(financial_year: financial_year, currency: financial_year.currency)
    end

    def propose
      return unless @vat_declaration = find_and_check
      @vat_declaration.propose
      redirect_to action: :show, id: @vat_declaration.id
    end

    def confirm
      return unless @vat_declaration = find_and_check
      @vat_declaration.confirm
      redirect_to action: :show, id: @vat_declaration.id
    end

  end
end
