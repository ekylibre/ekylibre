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
  class TaxDeclarationsController < Backend::BaseController
    manage_restfully except: %i[new show]

    unroll

    list(line_class: :status, order: { created_at: :desc, number: :desc }) do |t|
      t.action :edit, if: :editable?
      t.action :destroy, if: :destroyable?
      t.column :number, url: true
      t.column :responsible
      t.column :reference_number, url: true
      t.column :created_at
      t.column :started_on
      t.column :stopped_on
      t.column :deductible_tax_amount_balance, hidden: true
      t.column :collected_tax_amount_balance, hidden: true
      t.column :global_balance
      t.column :description, hidden: true
      t.status
    end

    # Displays details of one tax declaration selected with +params[:id]+
    def show
      return unless @tax_declaration = find_and_check
      respond_with(@tax_declaration, methods: [],
                                     include: {}) do |format|
        format.html do
          t3e @tax_declaration.attributes
        end
      end
    end

    def new
      financial_year = FinancialYear.find(params[:financial_year_id])
      if financial_year.tax_declaration_mode_none?
        redirect_to params[:redirect] || { action: :index }
      elsif !financial_year.previous_consecutives?
        notify_error :financial_years_missing
        redirect_to params[:redirect] || { action: :index }
      elsif financial_year.missing_tax_declaration?
        tax_declaration = TaxDeclaration.create!(financial_year: financial_year)
        redirect_to action: :show, id: tax_declaration.id
      else
        notify_error :all_tax_declarations_have_already_existing
        redirect_to params[:redirect] || { action: :index }
      end
    end

    def propose
      return unless @tax_declaration = find_and_check
      @tax_declaration.propose
      redirect_to action: :show, id: @tax_declaration.id
    end

    def confirm
      return unless @tax_declaration = find_and_check
      @tax_declaration.confirm
      redirect_to action: :show, id: @tax_declaration.id
    end
  end
end
