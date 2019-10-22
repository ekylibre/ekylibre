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
      # build variables for reporting (document_nature, key, filename and dataset)
      document_nature = Nomen::DocumentNature.find(:trial_balance)
      key = "#{document_nature.name}-#{Time.zone.now.l(format: '%Y-%m-%d-%H:%M:%S')}"
      filename = document_nature.human_name
      if params[:period] == 'all'
        params[:started_on] = FinancialYear.order(:started_on).pluck(:started_on).first.to_s
        params[:stopped_on] = FinancialYear.order(:stopped_on).pluck(:stopped_on).last.to_s
      end
      unless !params[:period] || params[:period] == 'all' || params[:period] == 'interval'
        params[:started_on] = params[:period].split('_').first
        params[:stopped_on] = params[:period].split('_').last
      end
      params[:period] = "#{params[:started_on]}_#{params[:stopped_on]}" if params[:period] == 'interval'
      @balance = Journal.trial_balance(params) if params[:period]
      if @balance && params[:balance] == 'balanced'
        @balance = @balance.select { |item| item[1].to_i < 0 || Account.find(item[1]).journal_entry_items.pluck(:real_balance).reduce(:+) == 0 }
      elsif @balance && params[:balance] == 'unbalanced'
        @balance = @balance.select { |item| item[1].to_i < 0 || Account.find(item[1]).journal_entry_items.pluck(:real_balance).reduce(:+) != 0 }
      end

      @prev_balance = []
      if params[:previous_year] && params[:started_on] && Date.parse(params[:stopped_on]) - Date.parse(params[:started_on]) < 366
        @prev_balance = @balance.map do |item|
          parameters = params.dup
          parameters[:started_on] = (Date.parse(params[:started_on]) - 1.year).to_s
          parameters[:stopped_on] = (Date.parse(params[:stopped_on]) - 1.year).to_s
          parameters[:period] = "#{parameters[:started_on]}_#{parameters[:stopped_on]}"
          if item[1].to_i < 0 && item[0].present?
            parameters[:centralize] = item[0]
          elsif item[1].to_i > 0
            parameters[:accounts] = item[0]
          end
          prev_balance = Journal.trial_balance(parameters)
          prev_items = prev_balance.select { |i| i[0] == item[0] }
          prev_items.any? ? prev_items.first : []
        end
      end

      respond_to do |format|
        format.html
        format.ods do
          send_data(
            to_ods(@balance, @prev_balance).bytes,
            filename: filename << '.ods'
          )
        end
        format.csv do
          csv_string = CSV.generate(headers: true) do |csv|
            to_csv(@balance, @prev_balance, csv)
          end
          send_data(csv_string, filename: filename << '.csv')
        end
        format.xcsv do
          csv_string = CSV.generate(headers: true, col_sep: ';', encoding: 'CP1252') do |csv|
            to_csv(@balance, @prev_balance, csv)
          end
          send_data(csv_string, filename: filename << '.csv')
        end
        format.pdf do
          balance_printer = BalancePrinter.new(balance: @balance,
                                               prev_balance: @prev_balance,
                                               document_nature: document_nature,
                                               key: key,
                                               params: params)
          send_file balance_printer.run, type: 'application/pdf', disposition: 'attachment', filename: key << '.pdf'
        end
      end
    end

    protected

    def to_csv(balance, prev_balance, csv)
      csv << [
        JournalEntryItem.human_attribute_name(:account_number),
        JournalEntryItem.human_attribute_name(:account_name),
        :total.tl,
        '',
        '',
        '',
        :balance.tl
      ]
      csv << [
        '',
        '',
        JournalEntry.human_attribute_name(:debit),
        JournalEntry.human_attribute_name(:credit),
        JournalEntry.human_attribute_name(:debit) + ' N-1',
        JournalEntry.human_attribute_name(:credit) + ' N-1',
        JournalEntry.human_attribute_name(:debit),
        JournalEntry.human_attribute_name(:credit),
        JournalEntry.human_attribute_name(:debit) + ' N-1',
        JournalEntry.human_attribute_name(:credit) + ' N-1'
      ]
      balance.each_with_index do |item, index|
        prev_item = prev_balance[index] || []
        if item[1].to_i > 0
          account = Account.find(item[1])
          account_name = account.name

          if csv.encoding.eql?(Encoding::CP1252)
            account_name = account_name.encode('CP1252', invalid: :replace, undef: :replace, replace: '?')
          end

          csv << [
            account.number,
            account_name,
            item[2].to_f,
            item[3].to_f,
            prev_item[2].present? ? prev_item[2].to_f : '',
            prev_item[3].present? ? prev_item[3].to_f : '',
            item[4].to_f > 0 ? item[4].to_f : 0,
            item[4].to_f < 0 ? -item[4].to_f : 0,
            prev_item[4].present? ? (prev_item[4].to_f > 0 ? prev_item[4].to_f : 0) : '',
            prev_item[4].present? ? (prev_item[4].to_f < 0 ? -prev_item[4].to_f : 0) : ''
          ]
        elsif item[1].to_i == -1
          # Part for the total
          csv << [
            '',
            :total.tl,
            item[2].to_f,
            item[3].to_f,
            prev_item[2].present? ? prev_item[2].to_f : '',
            prev_item[3].present? ? prev_item[3].to_f : '',
            item[4].to_f > 0 ? item[4].to_f : 0,
            item[4].to_f < 0 ? -item[4].to_f : 0,
            prev_item[4].present? ? (prev_item[4].to_f > 0 ? prev_item[4].to_f : 0) : '',
            prev_item[4].present? ? (prev_item[4].to_f < 0 ? -prev_item[4].to_f : 0) : ''
          ]
        elsif item[1].to_i == -2
          csv << [
            '',
            :subtotal.tl(name: item[0]).l,
            item[2].to_f,
            item[3].to_f,
            prev_item[2].present? ? prev_item[2].to_f : '',
            prev_item[3].present? ? prev_item[3].to_f : '',
            item[4].to_f > 0 ? item[4].to_f : 0,
            item[4].to_f < 0 ? -item[4].to_f : 0,
            prev_item[4].present? ? (prev_item[4].to_f > 0 ? prev_item[4].to_f : 0) : '',
            prev_item[4].present? ? (prev_item[4].to_f < 0 ? -prev_item[4].to_f : 0) : ''
          ]
        elsif item[1].to_i == -3
          csv << [
            item[0],
            :centralized_account.tl(name: item[0]).l,
            item[2].to_f,
            item[3].to_f,
            prev_item[2].present? ? prev_item[2].to_f : '',
            prev_item[3].present? ? prev_item[3].to_f : '',
            item[4].to_f > 0 ? item[4].to_f : 0,
            item[4].to_f < 0 ? -item[4].to_f : 0,
            prev_item[4].present? ? (prev_item[4].to_f > 0 ? prev_item[4].to_f : 0) : '',
            prev_item[4].present? ? (prev_item[4].to_f < 0 ? -prev_item[4].to_f : 0) : ''
          ]
        end
      end
    end

    def to_ods(balance, prev_balance)
      require 'rodf'
      output = RODF::Spreadsheet.new
      action_name = human_action_name

      output.instance_eval do
        office_style :head, family: :cell do
          property :text, 'font-weight': :bold
          property :paragraph, 'text-align': :center
        end

        office_style :right, family: :cell do
          property :paragraph, 'text-align': :right
        end

        office_style :bold, family: :cell do
          property :text, 'font-weight': :bold
        end

        office_style :italic, family: :cell do
          property :text, 'font-style': :italic
        end

        table action_name do
          row do
            cell JournalEntryItem.human_attribute_name(:account_number), style: :head
            cell JournalEntryItem.human_attribute_name(:account_name), style: :head
            cell :total.tl, style: :head, span: 4
            cell :balance.tl, style: :head, span: 4
          end

          row do
            cell ''
            cell ''
            cell JournalEntry.human_attribute_name(:debit), style: :head
            cell JournalEntry.human_attribute_name(:credit), style: :head
            cell JournalEntry.human_attribute_name(:debit) + ' N-1', style: :head
            cell JournalEntry.human_attribute_name(:credit) + ' N-1', style: :head
            cell JournalEntry.human_attribute_name(:debit), style: :head
            cell JournalEntry.human_attribute_name(:credit), style: :head
            cell JournalEntry.human_attribute_name(:debit) + ' N-1', style: :head
            cell JournalEntry.human_attribute_name(:credit) + ' N-1', style: :head
          end

          balance.each_with_index do |item, index|
            prev_item = prev_balance[index] || []
            if item[1].to_i > 0
              account = Account.find(item[1])
              row do
                cell account.number
                cell account.name
                cell (item[2]).l, type: :float
                cell (item[3]).l, type: :float
                cell prev_item.any? ? prev_item[2].l : '', type: :float
                cell prev_item.any? ? prev_item[3].l : '', type: :float
                cell (item[4].to_f > 0 ? item[4] : 0).l, type: :float
                cell (item[4].to_f < 0 ? (-item[4].to_f).to_s : 0).l, type: :float
                cell (prev_item.any? ? (prev_item[4].to_f > 0 ? prev_item[4] : 0) : '').l, type: :float
                cell (prev_item.any? ? (prev_item[4].to_f < 0 ? (-prev_item[4].to_f).to_s : 0) : '').l, type: :float
              end

            elsif item[1].to_i == -1
              row do
                cell ''
                cell :total.tl, style: :bold
                cell (item[2]).l, style: :bold, type: :float
                cell (item[3]).l, style: :bold, type: :float
                cell prev_item.any? ? prev_item[2].l : '', style: :bold, type: :float
                cell prev_item.any? ? prev_item[3].l : '', style: :bold, type: :float
                cell (item[4].to_f > 0 ? item[4] : 0).l, style: :bold, type: :float
                cell (item[4].to_f < 0 ? (-item[4].to_f).to_s : 0).l, style: :bold, type: :float
                cell (prev_item.any? ? (prev_item[4].to_f > 0 ? prev_item[4] : 0) : '').l, style: :bold, type: :float
                cell (prev_item.any? ? (prev_item[4].to_f < 0 ? (-prev_item[4].to_f).to_s : 0) : '').l, style: :bold, type: :float
              end
            elsif item[1].to_i == -2
              row do
                cell
                cell :subtotal.tl(name: item[0]).l, style: :right
                cell (item[2]).l, style: :bold, type: :float
                cell (item[3]).l, style: :bold, type: :float
                cell prev_item.any? ? prev_item[2].l : '', style: :bold, type: :float
                cell prev_item.any? ? prev_item[3].l : '', style: :bold, type: :float
                cell (item[4].to_f > 0 ? item[4] : 0).l, style: :bold, type: :float
                cell (item[4].to_f < 0 ? (-item[4].to_f).to_s : 0).l, style: :bold, type: :float
                cell (prev_item.any? ? (prev_item[4].to_f > 0 ? prev_item[4] : 0) : '').l, style: :bold, type: :float
                cell (prev_item.any? ? (prev_item[4].to_f < 0 ? (-prev_item[4].to_f).to_s : 0) : '').l, style: :bold, type: :float
              end
            elsif item[1].to_i == -3
              row do
                cell item[0], style: :italic
                cell :centralized_account.tl(name: item[0]).l, style: :italic
                cell (item[2]).l, style: :italic, type: :float
                cell (item[3]).l, style: :italic, type: :float
                cell prev_item.any? ? prev_item[2].l : '', style: :italic, type: :float
                cell prev_item.any? ? prev_item[3].l : '', style: :italic, type: :float
                cell (item[4].to_f > 0 ? item[4] : 0).l, style: :italic, type: :float
                cell (item[4].to_f < 0 ? (-item[4].to_f).to_s : 0).l, style: :italic, type: :float
                cell (prev_item.any? ? (prev_item[4].to_f > 0 ? prev_item[4] : 0) : '').l, style: :italic, type: :float
                cell (prev_item.any? ? (prev_item[4].to_f < 0 ? (-prev_item[4].to_f).to_s : 0) : '').l, style: :italic, type: :float
              end
            end
          end
        end
      end
      output
    end
  end
end
