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

class Backend::LoansController < Backend::BaseController
  manage_restfully
  manage_restfully_attachments

  unroll

  list do |t|
    t.action :edit
    t.action :destroy
    t.column :name, url: true
    t.column :amount, currency: true
    t.column :cash, url: true
    t.column :started_on
    t.column :repayment_duration
    t.column :repayment_period
    t.column :shift_duration
  end

  list :repayments, model: :loan_repayments, conditions: { loan_id: 'params[:id]'.c } do |t|
    t.column :position
    t.column :due_on
    t.column :amount, currency: true
    t.column :base_amount, currency: true
    t.column :interest_amount, currency: true
    t.column :insurance_amount, currency: true
    t.column :remaining_amount, currency: true
    t.column :journal_entry, url: true, hidden: true
  end
end
