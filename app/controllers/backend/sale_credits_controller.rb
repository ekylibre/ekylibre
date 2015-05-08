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

class Backend::SaleCreditsController < Backend::BaseController
  manage_restfully only: []

  def index
    redirect_to controller: :sales, action: :index
  end

  def new
    credited_sale = Sale.find_by(id: params[:credited_sale_id])
    unless credited_sale.cancellable?
      notify_error :the_sales_invoice_is_not_cancellable
      redirect_to params[:redirect] || {action: :index}
      return
    end
    @sale_credit = credited_sale.build_credit
    t3e @sale_credit.credited_sale
  end

  def create
    @sale_credit = SaleCredit.new(permitted_params)
    saved = false
    if @sale_credit.save
      @sale_credit.reload
      @sale_credit.propose!
      @sale_credit.confirm!
      @sale_credit.invoice!
      saved = true
    end
    return if save_and_redirect(@sale_credit, saved: saved, url: ({controller: :sales, action: :show, id: "id".c}))
    t3e @sale_credit.credited_sale
  end

end
