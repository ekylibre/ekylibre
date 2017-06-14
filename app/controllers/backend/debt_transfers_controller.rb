# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2015 Brice Texier, David Joulin
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
  class DebtTransfersController < Backend::BaseController
    manage_restfully only: %i[destroy]

    def create
      # target: Affair which absorb the debt transfer
      # debt transfer: Affair whose balance is used to transfer

      debt_transfer_affair = Affair.find_by(id: permitted_params[:deal_affair_id])
      target_affair = Affair.find_by(id: permitted_params[:id])

      return :unprocessable_entity unless [debt_transfer_affair, target_affair].all?

      transfer = DebtTransfer.create_and_reflect!(
        affair: target_affair,
        debt_transfer_affair: debt_transfer_affair
      )

      redirect_to params[:redirect] || backend_debt_transfer_url(transfer)
    end

    protected

    def permitted_params
      params.permit(:deal_affair_id, :id)
    end
  end
end
