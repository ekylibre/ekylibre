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
  class FinancialYearsController < Backend::BaseController
    manage_restfully except: %i[new show]

    unroll

    list(order: { started_on: :desc }) do |t|
      t.action :edit, if: :opened?
      t.action :destroy
      t.column :code, url: true
      t.column :state
      t.column :started_on, url: true
      t.column :stopped_on, url: true
      t.column :currency
      t.column :accountant, url: true
      # t.column :currency_precision
    end

    list(:account_balances, joins: :account, conditions: { financial_year_id: 'params[:id]'.c }, order: 'accounts.number') do |t|
      t.column :account, url: true
      t.column :account_number, through: :account, label_method: :number, url: true, hidden: true
      t.column :account_name,   through: :account, label_method: :name, url: true, hidden: true
      t.column :local_debit,  currency: true
      t.column :local_credit, currency: true
    end

    list(:fixed_asset_depreciations, conditions: { financial_year_id: 'params[:id]'.c }) do |t|
      t.column :fixed_asset, url: true
      t.column :started_on
      t.column :stopped_on
      t.column :amount, currency: true
    end

    list(:exchanges, model: :financial_year_exchanges, conditions: { financial_year_id: 'params[:id]'.c }) do |t|
      t.action :journal_entries_export, format: :csv, label: :journal_entries_csv_export.ta
      t.action :journal_entries_import, label: :journal_entries_import.ta, if: :opened?
      t.action :notify_accountant, if: :opened?
      t.action :close, if: :opened?
      t.column :started_on, url: true
      t.column :stopped_on, url: true
      t.column :closed_at
    end

    # Displays details of one financial year selected with +params[:id]+
    def show
      return unless @financial_year = find_and_check
      respond_to do |format|
        format.html do
          if @financial_year.closed? && @financial_year.account_balances.empty?
            @financial_year.compute_balances!
          end
          notify_now(:locked_exercice_info) if @financial_year.locked?
          t3e @financial_year.attributes

        end
        format.xml do
          FecExportJob.perform_later(@financial_year, params[:fiscal_position], params[:interval], current_user)
          notify_success(:document_in_preparation)
          redirect_to :back
        end
        format.pdf do
          if params[:n] == 'balance_sheet'
            render_print_balance_sheet(@financial_year)
          else
            render_print_income_statement(@financial_year)
          end
        end
        format.json
      end
    end

    def new
      @financial_year = FinancialYear.new
      f = FinancialYear.last
      @financial_year.started_on = f.stopped_on + 1 unless f.nil?
      @financial_year.started_on ||= Time.zone.today
      @financial_year.stopped_on = ((@financial_year.started_on - 1) >> 12).end_of_month
      @financial_year.code = @financial_year.default_code
      @financial_year.currency = @financial_year.previous.currency if @financial_year.previous
      @financial_year.currency ||= Preference[:currency]
      # render_restfully_form
    end

    def compute_balances
      return unless @financial_year = find_and_check
      if @financial_year.closed? && @financial_year.account_balances.empty?
        @financial_year.compute_balances!
      end
      redirect_to_back
    end

    def close
      # Launch close process
      return unless @financial_year = find_and_check
      if request.post? && @financial_year.closable?
        closed_on = params[:financial_year][:stopped_on].to_date
        if params[:result_journal_id] == '0'
          params[:result_journal_id] = Journal.create_one!(:result, @financial_year.currency).id
        end
        if params[:forward_journal_id] == '0'
          params[:forward_journal_id] = Journal.create_one!(:forward, @financial_year.currency).id
        end
        if params[:closure_journal_id] == '0'
          params[:closure_journal_id] = Journal.create_one!(:closure, @financial_year.currency).id
        end
        FinancialYearCloseJob.perform_later(@financial_year, current_user, closed_on.to_s, **params.symbolize_keys.slice(:result_journal_id, :forward_journal_id, :closure_journal_id))
        notify_success(:closure_process_started)

        return redirect_to(action: :index)
      end

      journal = Journal.where(currency: @financial_year.currency, nature: :result).first
      params[:result_journal_id] = (journal ? journal.id : 0)
      journal = Journal.where(currency: @financial_year.currency, nature: :forward).first
      params[:forward_journal_id] = (journal ? journal.id : 0)
      journal = Journal.where(currency: @financial_year.currency, nature: :closure).first
      params[:closure_journal_id] = (journal ? journal.id : 0)
      t3e @financial_year.attributes
    end

    def index
      @opened_financial_years_count = FinancialYear.opened.count
      @fy_to_close = FinancialYear.closable_or_lockable if FinancialYear.closable_or_lockable
      f = FinancialYear.order(stopped_on: :desc).first
      @fy_to_open = FinancialYear.new
      @fy_to_open.started_on = f.present? ? f.stopped_on + 1 : Time.now.to_date
      @fy_to_open.stopped_on = ((@fy_to_open.started_on - 1) >> 12).end_of_month
      @fy_to_open.code = @fy_to_open.default_code

      if FinancialYear.closables_or_lockables.count > 1
        @title = :you_can_close_financial_year_to_open_a_new_one
      elsif FinancialYear.current && FinancialYear.current.stopped_on < (Date.today + 6.months) && FinancialYear.next_year.nil? && FinancialYear.previous_year&.opened?
        @title = :you_can_close_financial_year
      else
        @title = ''
      end
    end

    def lock
      return unless @financial_year = find_and_check
      if request.post?
        @financial_year.update(state: 'locked')
        return redirect_to(action: :index)
      end
      t3e @financial_year.attributes
    end

    def destroy_all_empty
      ids_array =  params[:year_ids]
      FinancialYear.where(id: ids_array).delete_all
      return redirect_to(action: :index)
    end

    def download_archive
      filename = "#{params[:id]}_#{params[:timing]}.zip"
      temp_file = Tempfile.new(filename)
      file_path = Ekylibre::Tenant.private_directory.join('attachments', 'documents', 'financial_year_closures', "#{params[:id]}", "#{params[:timing]}")

      begin
        Zip::OutputStream.open(temp_file) { |zos| }
        Zip::File.open(temp_file.path, Zip::File::CREATE) do |zip|
          Dir[File.join(file_path, '**/**')].each do |file|
            zip.add(file.sub("#{file_path}/", ''), file)
          end
        end
        zip_data = File.read(temp_file.path)
        send_data(zip_data, :type => 'application/zip', :filename => filename)
      ensure
        temp_file.close
        temp_file.unlink
      end
    end
  end
end
