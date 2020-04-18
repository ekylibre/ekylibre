# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2015 Brice Texier, David Joulin
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
  class TrialBalancesController < Backend::BaseController

    def show
      set_period_params

      dataset_params = {
        states: params[:states],
        natures: params[:natures],
        balance: params[:balance],
        accounts: params[:accounts],
        centralize: params[:centralize],
        period: params[:period],
        started_on: params[:started_on],
        stopped_on: params[:stopped_on],
        vat_details: params[:vat_details],
        previous_year: params[:previous_year]
      }

      respond_to do |format|
        format.html do
          dataset = Journal.trial_balance_dataset(dataset_params)
          @balance = dataset[:balance]
          @prev_balance = dataset[:prev_balance]
        end

        format.ods do
          return unless template = DocumentTemplate.find_by_nature(:trial_balance)
          printer = Printers::TrialBalancePrinter.new(template: template, **dataset_params)
          send_data printer.run_ods.bytes, filename: "#{printer.document_name}.ods"
        end

        format.csv do
          return unless template = DocumentTemplate.find_by_nature(:trial_balance)
          printer = Printers::TrialBalancePrinter.new(template: template, **dataset_params)
          csv_string = CSV.generate(headers: true) do |csv|
            printer.run_csv(csv)
          end
          send_data csv_string, filename: "#{printer.document_name}.csv"
        end

        format.xcsv do
          return unless template = DocumentTemplate.find_by_nature(:trial_balance)
          printer = Printers::TrialBalancePrinter.new(template: template, **dataset_params)
          csv_string = CSV.generate(headers: true, col_sep: ';', encoding: 'CP1252') do |csv|
            printer.run_csv(csv)
          end
          send_data csv_string, filename: "#{printer.document_name}.csv"
        end

        format.pdf do
          return unless template = find_and_check(:document_template, params[:template])
          PrinterJob.perform_later('Printers::TrialBalancePrinter', template: template, perform_as: current_user, **dataset_params)
          notify_success(:document_in_preparation)
          redirect_to :back
        end
      end
    end
  end
end
