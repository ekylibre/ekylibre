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
  class LoanRepaymentsController < Backend::BaseController
    manage_restfully except: %i[new create show destroy], t3e: { loan_name: :name }

    def index
      redirect_to backend_loans_path
    end

    def new
      loan = Loan.find(params[:loan])
      last_repayment = loan.repayments.last
      next_due_date = last_repayment.due_on + 1.send(loan.repayment_period)
      next_position = last_repayment.position + 1
      @loan_repayment = LoanRepayment.new(loan_id: params[:loan], due_on: next_due_date, position: next_position)
    end

    def create
      @loan_repayment = resource_model.new(permitted_params)
      return if save_and_redirect(@loan_repayment, url: backend_loan_path(permitted_params[:loan_id]), notify: :record_x_created, identifier: :id)
      render(locals: { cancel_url: {:action=>:index}, with_continue: false })
    end

    def show
      if @loan_repayment = LoanRepayment.find_by(id: params[:id])
        redirect_to backend_loan_path(@loan_repayment.loan_id)
      else
        redirect_to backend_root_path
      end
    end
  end
end
