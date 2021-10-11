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
    before_action :save_search_preference, only: :show

    def show
      set_period_params

      unsafe_params = params.to_unsafe_h

      dataset_params = {
        states: unsafe_params[:states],
        natures: unsafe_params[:natures],
        balance: unsafe_params[:balance],
        accounts: unsafe_params[:accounts],
        centralize: unsafe_params[:centralize],
        period: unsafe_params[:period],
        started_on: unsafe_params[:started_on],
        stopped_on: unsafe_params[:stopped_on],
        vat_details: unsafe_params[:vat_details],
        previous_year: unsafe_params[:previous_year],
        levels: unsafe_params.select{|k, v| k =~ /\Alevel_/ && v.to_s == "1"}.map{|k, _v| k.sub('level_', '').to_i}
      }

      respond_to do |format|
        format.html do
          @balance = Journal.trial_balance_dataset(dataset_params)
          @empty_balances = @balance.length <= 1
          notify_now(:please_select_a_period_containing_journal_entries) if @empty_balances
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
          redirect_back(fallback_location: { action: :index })
        end
      end
    end
  end
end
