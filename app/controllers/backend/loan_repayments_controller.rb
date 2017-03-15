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
    
    def index
      redirect_to backend_loans_path
    end

    def show
      if @loan_repayment = LoanRepayment.find_by(id: params[:id])
        redirect_to backend_loan_path(@loan_repayment.loan_id)
      else
        redirect_to backend_root_path
      end
    end
 

    def edit
      return unless @loan_repayment = find_and_check(:loan_repayment)
      t3e(@loan_repayment.attributes)
      render(locals: { cancel_url: :back })
    end
  
     def update
       return unless @loan_repayment = find_and_check
       byebug
       return if save_and_redirect(@loan_repayment, attributes: permitted_params, url: { action: :show })
       t3e @loan_repayment
     end 
  
     protected

      def permitted_params
        params.require(:loan_repayment).permit(:due_on, :amount, :base_amount, :interest_amount, :insurance_amount, :remaining_amount)
      end 
  end
end
