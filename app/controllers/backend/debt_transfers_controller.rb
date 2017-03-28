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
    # manage_restfully
    #
    # unroll
    #
    # list do |t|
    #   t.action :edit
    #   t.action :destroy
    #   t.column :name, url: true
    # end
  end

  def create
    # target: Affair which absorb the debt transfer
    # Deal affair: Affair whose balance is used to transfer

    deal_affair = Affair.find_by(id: debt_transfer_params[:deal_affair_id])
    target_affair = Affair.find_by(id: debt_transfer_params[:id])

    return :unprocessable_entity unless [deal_affair, target_affair].all?

    amount = deal_affair.third_credit_balance
    amount = -amount.abs if deal_affair.type.is_a?(PurchaseAffair)

    DebtTransfer.create!(target_affair.type.underscore => target_affair, deal_affair.type.underscore => deal_affair, amount: amount)
  end

  def debt_transfer_params
    params.permit!(:deal_affair_id)
  end
end
