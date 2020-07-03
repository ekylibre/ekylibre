# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2013 Brice Texier, David Joulin
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
  class LoansController < Backend::BaseController
    manage_restfully

    unroll

    before_action :save_search_preference, only: :index

    respond_to :pdf, :odt, :docx, :xml, :json, :html, :csv

    def self.list_conditions
      code = ''
      code = search_conditions(loans: %i[name amount], cashes: [:bank_name]) + " ||= []\n"
      code << "if params[:period].present? && params[:period].to_s != 'all'\n"
      code << "  c[0] << ' AND #{Loan.table_name}.started_on BETWEEN ? AND ?'\n"
      code << "  if params[:period].to_s == 'interval'\n"
      code << "    c << params[:started_on]\n"
      code << "    c << params[:stopped_on]\n"
      code << "  else\n"
      code << "    interval = params[:period].to_s.split('_')\n"
      code << "    c << interval.first\n"
      code << "    c << interval.second\n"
      code << "  end\n"
      code << "end\n"
      code << "unless params[:state].blank?\n"
      code << "  c[0] << ' AND #{Loan.table_name}.state IN (?)'\n"
      code << "  c << params[:state]\n"
      code << "end\n"
      code << "if params[:repayment_period].present?\n"
      code << "  c[0] << ' AND #{Loan.table_name}.repayment_period IN (?)'\n"
      code << "  c << params[:repayment_period]\n"
      code << "end\n"
      code << "if params[:cash_id].to_i > 0\n"
      code << "  c[0] += ' AND #{Loan.table_name}.cash_id = ?'\n"
      code << "  c << params[:cash_id]\n"
      code << "end\n"
      code << "c\n"
      code.c
    end

    list(conditions: list_conditions) do |t|
      t.action :edit, if: :editable?
      t.action :destroy, if: :destroyable?
      t.column :name, url: true
      t.column :amount, currency: true
      t.column :cash, url: true
      t.status
      t.column :state_label, hidden: true
      t.column :started_on
      t.column :repayment_duration
      t.column :repayment_period
      t.column :shift_duration
    end

    list :repayments, model: :loan_repayments, conditions: { loan_id: 'params[:id]'.c } do |t|
      t.action :edit, if: :updateable?
      t.column :position
      t.column :accountable
      t.column :locked
      t.column :due_on
      t.column :amount, currency: true
      t.column :base_amount, currency: true
      t.column :interest_amount, currency: true
      t.column :insurance_amount, currency: true
      t.column :remaining_amount, currency: true
      t.column :journal_entry, url: true, hidden: true
    end

    # Show a list of loans
    def index
      @loans = Loan.reorder(:started_on).all
      # passing a parameter to Jasper for company full name and id
      @entity_of_company_full_name = Entity.of_company.full_name
      @entity_of_company_id = Entity.of_company.id

      respond_with @loans, methods: [:current_remaining_amount], include: %i[lender loan_account interest_account insurance_account cash journal_entry]
    end

    def confirm
      return unless @loan = find_and_check
      @loan.confirm
      redirect_to action: :show, id: @loan.id
    end

    def repay
      return unless @loan = find_and_check
      @loan.repay
      redirect_to action: :show, id: @loan.id
    end

    def bookkeep
      begin
        bookkeep_until = Date.parse(params[:until])
      rescue
        notify_error(:the_bookkeep_date_format_is_invalid)
        return redirect_to(params[:redirect] || { action: :index })
      end

      count = Loan.bookkeep_repayments(until: bookkeep_until)
      notify_success(:x_loan_repayments_have_been_bookkept_successfully, count: count)

      redirect_to(params[:redirect] || { action: :index })
    end
  end
end
