# frozen_string_literal: true

class BankStatementClassifierService
  def self.call(*args)
    new(*args).call
  end

  def initialize(bank_statement_id: )
    @bank_statement = BankStatement.find(bank_statement_id)
    @bank_statement_items = @bank_statement.items
  end

  def call
    nil
    # classifier = ClassifierReborn::Bayes.new categories, auto_categorize: true
  end
end
