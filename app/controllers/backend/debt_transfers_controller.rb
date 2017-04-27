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
    manage_restfully except: :create
    def create
      # target: Affair which absorb the debt transfer
      # debt transfer: Affair whose balance is used to transfer

      debt_transfer_affair = Affair.find_by(id: debt_transfer_params[:deal_affair_id])
      target_affair = Affair.find_by(id: debt_transfer_params[:id])

      return :unprocessable_entity unless [debt_transfer_affair, target_affair].all?

      transfer = DebtTransfer.create_and_reflect!(affair: target_affair, debt_transfer_affair: debt_transfer_affair)

      redirect_to backend_debt_transfer_url(transfer)
    end

    list(joins: [:debt_transfer_affair], order: { created_at: :desc, number: :desc }) do |t|
      t.action :destroy, if: :destroyable?
      t.column :number, url: { action: :show }
      t.column :created_at
      t.column :accounted_at
      t.column :nature
    end

    def debt_transfer_params
      params.permit(:deal_affair_id, :id)
    end
  end
end
