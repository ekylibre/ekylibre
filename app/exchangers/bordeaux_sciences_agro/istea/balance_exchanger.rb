module BordeauxSciencesAgro
  module Istea
    class BalanceExchanger < ActiveExchanger::Base
      category :accountancy
      vendor :bordeaux_sciences_agro

      def check
        # Imports journal entries into journal to make accountancy in CSV format
        # filename example : 17005534_EXPORT_BAL.TXT
        # with adding a first column with year of the financial_year
        # Columns are:
        #  0 - A: year : "2016"
        #  1 - B: account number : "34150000"
        #  2 - C: account name : "FACONS CULTU EN TRRE"
        #  3 - D: start_debit_amount
        #  4 - E: start_credit_amount
        #  5 - F: variation_debit_amount
        #  6 - G: variation_credit_amount
        #  7 - H: global_balance (start_debit_amount + variation_debit_amount ) - (start_credit_amount + variation_credit_amount)

        source = File.read(file)
        detection = CharlockHolmes::EncodingDetector.detect(source)
        rows = CSV.read(file, headers: false, encoding: detection[:encoding], col_sep: ';')
        w.count = rows.size

        valid = true

          rows.each_with_index do |row, index|
            line_number = index + 2
            prompt = "L#{line_number.to_s.yellow}"
            r = {
              printed_on: Date.parse(row[0].to_s),
              account_number: row[1].to_s,
              account_name: row[2].to_s,
              start_debit_amount: (row[3].blank? ? 0.0 : row[3].to_f),
              start_credit_amount: (row[4].blank? ? 0.0 : row[4].to_f),
              variation_debit_amount: (row[5].blank? ? 0.0 : row[5].to_f),
              variation_credit_amount: (row[6].blank? ? 0.0 : row[6].to_f),
              global_balance: (row[7].blank? ? 0.0 : row[7].to_f)
            }.to_struct
            # w.check_point

            fy = FinancialYear.where("stopped_on = ?", r.printed_on).first
            unless fy
              valid = false
            end

            # if (r.start_debit_amount + r.variation_debit_amount) - (r.start_credit_amount + r.variation_credit_amount)!= r.global_balance
            #  valid = false
            # end
          end
          valid
        end

        def import
          source = File.read(file)
          detection = CharlockHolmes::EncodingDetector.detect(source)
          rows = CSV.read(file, headers: false, encoding: detection[:encoding], col_sep: ';')
          w.count = rows.size

          journal = Journal.find_or_create_by(code: 'ISTE', nature: 'various', name: 'Import ISTEA')

          w.count = rows.size

          entries = {}

          rows.each_with_index do |row, index|
            line_number = index + 2
            prompt = "L#{line_number.to_s.yellow}"
            r = {
              printed_on: Date.parse(row[0].to_s),
              account_number: row[1].to_s,
              account_name: row[2].to_s,
              start_debit_amount: (row[3].blank? ? 0.0 : row[3].to_f),
              start_credit_amount: (row[4].blank? ? 0.0 : row[4].to_f),
              variation_debit_amount: (row[5].blank? ? 0.0 : row[5].to_f),
              variation_credit_amount: (row[6].blank? ? 0.0 : row[6].to_f),
              global_balance: (row[7].blank? ? 0.0 : row[7].to_f)
            }.to_struct

            number = r.printed_on.to_s
            w.info "--------------------index : #{index} | number : #{line_number}--------------------------"

            unless entries[number]
              entries[number] = {
                printed_on: r.printed_on,
                journal: journal,
                number: line_number,
                currency: journal.currency,
                items_attributes: {}
              }
            end

            if r.account_number && r.account_name
              if r.account_number == '41100000' || r.account_number == '40100000'
                r.account_number = r.account_number[0..2] + '01000'
              end
              account = Account.find_or_create_by_number(r.account_number, name: r.account_name)
              w.info "account : #{account.label.inspect.red}"
            end

            if r.start_debit_amount.to_f > 0.0
              id = (entries[number][:items_attributes].keys.max || 0) + 1
              entries[number][:items_attributes][id] = {
                real_debit: r.start_debit_amount.to_f,
                real_credit: 0.0,
                account: account,
                name: r.account_name
              }
            end
            if r.start_credit_amount.to_f > 0.0
              id = (entries[number][:items_attributes].keys.max || 0) + 1
              entries[number][:items_attributes][id] = {
                real_debit: 0.0,
                real_credit: r.start_credit_amount.to_f,
                account: account,
                name: r.account_name
              }
            end
            if r.variation_debit_amount.to_f > 0.0
              id = (entries[number][:items_attributes].keys.max || 0) + 1
              entries[number][:items_attributes][id] = {
                real_debit: r.variation_debit_amount.to_f,
                real_credit: 0.0,
                account: account,
                name: r.account_name
              }
            end
            if r.variation_credit_amount.to_f > 0.0
              id = (entries[number][:items_attributes].keys.max || 0) + 1
              entries[number][:items_attributes][id] = {
                real_debit: 0.0,
                real_credit: r.variation_credit_amount.to_f,
                account: account,
                name: r.account_name
              }
            end

            w.check_point
          end

          w.reset!(entries.keys.size)
          entries.values.each do |entry|
            w.info "JE : #{entry}".inspect.yellow
            j = JournalEntry.create!(entry)
            w.info "JE created: #{j.number} | #{j.printed_on}".inspect.yellow
            w.check_point
          end
        end
      end
    end
  end
