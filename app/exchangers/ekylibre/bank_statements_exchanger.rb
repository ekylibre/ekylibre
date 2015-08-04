# coding: utf-8
class Ekylibre::BankStatementsExchanger < ActiveExchanger::Base
  def import
    s = Roo::OpenOffice.new(file)
    w.count = s.sheets.count

    s.sheets.each do |sheet_name|
      s.sheet(sheet_name)

      # get information for bank statement context in file header
      cash_name = s.cell('A', 2).to_s.strip
      bank_statement_number = s.cell('B', 2).to_s.strip
      bank_statement_started_on = (s.cell('C', 2).blank? ? nil : Date.parse(s.cell('C', 2).to_s))
      bank_statement_stopped_on = (s.cell('D', 2).blank? ? nil : Date.parse(s.cell('D', 2).to_s))

      # get cashe if exist in DB
      if cash = Cash.find_by(name: cash_name)
        w.info "Bank statement will be created in #{cash.name}"
      else
        w.error 'Missing informations to get existing cash, you must update your file or create a cash before importing'
      end

      # get bank_statement if exist in DB or create it
      bank_statement = BankStatement.where(cash: cash, number: bank_statement_number).first if cash && bank_statement_number
      if bank_statement
        # try to know if any items exist
        if bank_statement.items.any?
          w.error "Bank statement #{bank_statement.number} already exist with items.No way to use it"
        else
          w.info "Bank statement #{bank_statement.number} already exist but is blank, we will use it"
        end

      elsif cash && bank_statement_number && bank_statement_started_on && bank_statement_stopped_on
        bank_statement = BankStatement.create!(cash: cash,
                                               number: bank_statement_number,
                                               started_at: bank_statement_started_on.to_time,
                                               stopped_at: bank_statement_stopped_on.to_time
                                              )
      else
        w.error 'Missing informations to create a bank statement'
      end

      w.debug "Bank statement #{bank_statement.number} in Cash #{cash.name}"

      # file format (CSV from common bank)
      # A operation_date
      # B value_date
      # C debit
      # D credit
      # E description
      # F global_balance

      # 3 first line are not bank statement items
      4.upto(s.last_row) do |row_number|
        next if s.cell('A', row_number).blank?
        r = {
          operation_date: Date.parse(s.cell('A', row_number)),
          value_date: Date.parse(s.cell('B', row_number)),
          debit: (s.cell('C', row_number).blank? ? nil : s.cell('C', row_number).to_d),
          credit: (s.cell('D', row_number).blank? ? nil : s.cell('D', row_number).to_d),
          description: (s.cell('E', row_number).blank? ? nil : s.cell('E', row_number).to_s.strip),
          global_balance: (s.cell('F', row_number).blank? ? nil : s.cell('F', row_number).to_d)
        }.to_struct

        w.info "#{r.operation_date.l} -  #{r.description}"
      end
      w.check_point
    end
  end
end
