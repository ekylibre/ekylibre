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
      t.action :journal_entries_export, format: :csv, label: :journal_entries_export.ta, class: 'export-action'
      t.action :journal_entries_import, label: :journal_entries_import.ta, if: :opened?, class: 'import-action'
      t.action :notify_accountant, if: :opened?, class: 'email-action'
      t.action :close, if: :opened?
      t.column :started_on, url: true, class: 'center-align'
      t.column :stopped_on, url: true, class: 'center-align'
      t.column :closed_at, class: 'center-align'
    end

    # Displays details of one financial year selected with +params[:id]+
    def show
      return unless @financial_year = find_and_check
      respond_to do |format|
        format.html do
          if FinancialYear.closables_or_lockables.pluck(:id).include?(@financial_year.id) && @financial_year.exchanges.opened.any?
            notify_now(:close_financial_year_exchange_before_preparing_for_closure.tl)
          end
          if @financial_year.closed? && @financial_year.account_balances.empty?
            @financial_year.compute_balances!
          end
          if @financial_year.closure_in_preparation?
            @closer = @financial_year.closer
            @closer == current_user ? notify_now(:financial_year_closure_in_preparation_initiated_by_you.tl(code: @financial_year.code)) : notify_now(:financial_year_closure_in_preparation_initiated_by_someone_else.tl(code: @financial_year.code))
          end
          notify_now(:locked_exercice_info) if @financial_year.locked?
          t3e @financial_year.attributes
          @progress_status = fetch_progress_values(params[:id])
        end

        format.xml do
          FecExportJob.perform_later(@financial_year, params[:fiscal_position], params[:interval], current_user, 'xml')
          notify_success(:document_in_preparation)
          redirect_to :back
        end

        format.text do
          FecExportJob.perform_later(@financial_year, params[:fiscal_position], params[:interval], current_user, 'text')
          notify_success(:document_in_preparation)
          redirect_to :back
        end

        format.pdf do
          return unless template = find_and_check(:document_template, params[:template])
          PrinterJob.perform_later("Printers::#{template.nature.classify}Printer", template: template, financial_year: @financial_year, perform_as: current_user)
          notify_success(:document_in_preparation)
          redirect_to :back
        end

        format.json
      end
    end

    def new
      @financial_year = FinancialYear.new

      f = FinancialYear.order(:stopped_on).last
      if f.present?
        @financial_year.started_on = f.stopped_on + 1
      else
        @financial_year.started_on = Entity.of_company&.born_at
        @financial_year.stopped_on = Entity.of_company&.first_financial_year_ends_on
      end
      @financial_year.started_on ||= Time.zone.today
      @financial_year.stopped_on ||= ((@financial_year.started_on - 1) + 1.year).end_of_month

      @financial_year.code = @financial_year.default_code
      @financial_year.currency = @financial_year.previous.currency if @financial_year.previous
      @financial_year.currency ||= Preference[:currency]
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
      credit_carry_forward = Account.find_or_create_by_number(110)

      @credit_balance = (credit_carry_forward.totals[:balance_credit].to_f - credit_carry_forward.totals[:balance_debit].to_f).abs
      debit_carry_forward = Account.find_or_create_by_number(119)
      @debit_balance = (debit_carry_forward.totals[:balance_debit].to_f - debit_carry_forward.totals[:balance_credit].to_f).abs

      @carry_forward_balance = @credit_balance - @debit_balance
      @result = AccountancyComputation.new(@financial_year).sum_entry_items_by_line(:profit_and_loss_statement, :exercice_result)
      allocations = if Entity.of_company.of_capital? || Entity.of_company.of_person?
                      if (@result + @carry_forward_balance).positive?
                        params[:allocations] || {}
                      else
                        { '119' => (@result + @carry_forward_balance).abs }
                      end
                    elsif Entity.of_company.of_individual?
                      { '101' => (@result + @carry_forward_balance).abs }
                    else
                      if (@result + @carry_forward_balance).positive?
                        { '110' => (@result + @carry_forward_balance).abs }
                      else
                        { '119' => (@result + @carry_forward_balance).abs }
                      end
                    end

      t3e @financial_year.attributes
      if request.get?
        only_closable = FinancialYear.closable_or_lockable
        return redirect_to backend_financial_years_path if @financial_year != only_closable
        return render
      end
      if request.post? && @financial_year.closable?
        total_amount_to_allocate = @result + @carry_forward_balance
        total_amount_allocated = allocations.values.reduce(0) { |sum, val| sum + val.to_f }
        if total_amount_to_allocate.abs.to_f != total_amount_allocated.to_f
          notify_error_now :record_is_not_valid
        else
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
          @financial_year.update!(state: 'closing')
          FinancialYearCloseJob.perform_later(@financial_year, current_user, closed_on.to_s, allocations, **params.symbolize_keys.slice(:result_journal_id, :forward_journal_id, :closure_journal_id))
          notify_success(:closure_process_started)

          return redirect_to backend_financial_year_path(@financial_year)
        end
      end

      journal = Journal.where(currency: @financial_year.currency, nature: :result).first
      params[:result_journal_id] = (journal ? journal.id : 0)
      journal = Journal.where(currency: @financial_year.currency, nature: :forward).first
      params[:forward_journal_id] = (journal ? journal.id : 0)
      journal = Journal.where(currency: @financial_year.currency, nature: :closure).first
      params[:closure_journal_id] = (journal ? journal.id : 0)
    end

    def index
      @opened_financial_years_count = FinancialYear.opened.count
      @fy_to_close = FinancialYear.closable_or_lockable if FinancialYear.closable_or_lockable
      @fys_in_preparation = FinancialYear.in_preparation
      if @fys_in_preparation.any?
        @fy_in_preparation = @fys_in_preparation.first
        @closer = @fy_in_preparation.closer
        @closer == current_user ? notify_now(:financial_year_closure_in_preparation_initiated_by_you.tl(code: @fy_in_preparation.code)) : notify_now(:financial_year_closure_in_preparation_initiated_by_someone_else.tl(code: @fy_in_preparation.code))
      end
      f = FinancialYear.order(stopped_on: :desc).first
      @fy_to_open = FinancialYear.new
      @fy_to_open.started_on = f.present? ? f.stopped_on + 1 : Time.now.to_date
      @fy_to_open.stopped_on = ((@fy_to_open.started_on - 1) >> 12).end_of_month
      @fy_to_open.code = @fy_to_open.default_code

      if FinancialYear.closables_or_lockables.count > 1
        @title = :you_can_close_financial_year_to_open_a_new_one
      elsif FinancialYear.on(Time.zone.today) && FinancialYear.on(Time.zone.today).stopped_on < (Date.today + 6.months) && FinancialYear.next_year.nil? && FinancialYear.previous_year&.opened?
        @title = :you_can_close_financial_year
      else
        @title = ''
      end
    end

    def lock
      return unless @financial_year = find_and_check
      t3e @financial_year.attributes
      if request.get?
        only_lockable = FinancialYear.closable_or_lockable
        return redirect_to backend_financial_years_path if @financial_year != only_lockable
        return render
      end
      if request.post?
        begin
          ActiveRecord::Base.transaction do
            FixedAssetDepreciation.up_to(@financial_year.stopped_on).where(locked: false).update_all(locked: true)
            LoanRepayment.where('due_on <= ?', @financial_year.stopped_on).where(locked: false).update_all(locked: true)
            @financial_year.update!(state: 'locked')
          end
        rescue ActiveRecord::RecordInvalid => error
          notify_error(:please_contact_support_for_further_information, message: error.message)
        end
        return redirect_to(action: :index)
      end
    end

    def destroy_all_empty
      ids_array =  params[:year_ids]
      FinancialYear.where(id: ids_array).delete_all
      return redirect_to(action: :index)
    end

    def run_progress
      financial_year = FinancialYear.find(params[:id])
      progress_status = fetch_progress_values(params[:id])
      render partial: 'progress', locals: { value: progress_status[:value],
                                            resource: financial_year,
                                            refresh: params[:archives].to_i < 1 && financial_year.closed,
                                            current_step: progress_status[:step],
                                            steps_count: progress_status[:total],
                                            step_label: progress_status[:label] }
    end

    private

    def fetch_progress_values(id)
      progress = Progress.fetch('close_main', id: id)
      progress_value = progress ? progress.value : 0

      progress_steps_count = FinancialYearClose::CLOSURE_STEPS.count
      step_value = 100 / progress_steps_count
      current_progress_step = (progress_value / step_value).round

      sub_progress = Progress.fetch(FinancialYearClose::CLOSURE_STEPS[current_progress_step], id: id)
      sub_progress_value = sub_progress ? sub_progress.value : 0

      { value: (progress_value + sub_progress_value * step_value / 100).round,
        step: current_progress_step + 1,
        total: progress_steps_count,
        label: FinancialYearClose::CLOSURE_STEPS[current_progress_step] }
    end
  end
end
