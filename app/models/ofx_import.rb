class OfxImport
  class InvalidOfxFile < RuntimeError; end
  class OfxFileHasMultipleAccounts < RuntimeError; end

  attr_reader :error, :internal_error, :cash, :bank_statement

  def initialize(file, cash = nil)
    @file = file
    @cash = cash
  end

  def run
    read_and_parse_file or return false
    ensure_file_has_a_single_account or return false
    @cash = find_or_build_cash_from_ofx_bank_account unless cash
    @bank_statement = build_bank_statement_with_items
    save_bank_statement
  end

  def recoverable?
    bank_statement.present?
  end

  private
  attr_reader :file, :parsed

  def read_and_parse_file
    begin
      @parsed = OfxParser::OfxParser.parse(file.read)
      true
    rescue => error
      message = I18n.translate("activerecord.errors.models.bank_statement.ofx_file_invalid")
      @error = InvalidOfxFile.new(message)
      @internal_error = error
      false
    end
  end

  def ensure_file_has_a_single_account
    return true if parsed.bank_accounts.length == 1
    message = I18n.translate("activerecord.errors.models.bank_statement.ofx_file_has_multiple_bank_accounts")
    @error = OfxFileHasMultipleAccounts.new(message)
    false
  end

  def ofx_statement
    ofx_bank_account.statement
  end

  def ofx_bank_account
    parsed.bank_accounts.first
  end

  def find_or_build_cash_from_ofx_bank_account
    find_cash_from_ofx_bank_account || build_cash_from_ofx_bank_account
  end

  def find_cash_from_ofx_bank_account
    number = ofx_bank_account.number
    Cash.pointables.where("iban LIKE ?", "%#{number}%").take
  end

  def build_cash_from_ofx_bank_account
    Cash.new.tap do |c|
      c.currency = ofx_statement.currency
      c.mode = :bban
      c.bank_code = ofx_bank_account.routing_number
      c.bank_agency_code = ofx_bank_account.branch_number
      c.bank_account_number = ofx_bank_account.number
    end
  end

  def build_bank_statement_with_items
    bank_statement = build_bank_statement(cash)
    ofx_statement.transactions.each do |transaction|
      build_bank_statement_item bank_statement, transaction
    end
    bank_statement
  end

  def build_bank_statement(cash)
    BankStatement.new.tap do |s|
      s.cash = cash
      s.number = generate_bank_statement_number
      s.started_at = ofx_statement.start_date
      s.stopped_at = ofx_statement.end_date
    end
  end

  def build_bank_statement_item(bank_statement, transaction)
    bank_statement.items.build.tap do |i|
      i.name = transaction.payee
      i.transaction_number = transaction.fit_id
      i.transfered_on = transaction.date
      i.initiated_on = transaction.date_initiated
      i.balance = transaction.amount.to_f
    end
  end

  def generate_bank_statement_number
    statement_duration_days = (ofx_statement.end_date - ofx_statement.start_date).to_i
    if statement_duration_days <= 99
      formatted_duration = "%02i" % statement_duration_days
      ofx_statement.start_date.strftime("%Y%m%d") + formatted_duration
    end
  end

  def save_bank_statement
    begin
      @bank_statement.save!
      true
    rescue => error
      @error = error
      false
    end
  end
end
