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
  class TaxPaymentsController < Backend::BaseController
    manage_restfully

    unroll

    list(line_class: :status, order: { created_at: :desc, number: :desc }) do |t|
      t.action :edit, if: :editable?
      t.action :destroy, if: :destroyable?
      t.column :number, url: true
      t.column :nature
      t.column :amount, currency: true, datatype: :decimal
      t.column :paid_at, datatype: :date
      t.column :created_at
      t.column :description, hidden: true
      t.status
    end

    def confirm
      return unless @tax_payment = find_and_check

      @tax_payment.confirm
      redirect_to action: :show, id: @tax_payment.id
    end

  end
end
