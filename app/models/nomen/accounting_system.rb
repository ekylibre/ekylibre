module Nomen
  class AccountingSystem < Nomen::Record::Base
    class << self
      def with_fiscal_position
        Nomen::FiscalPosition.items.values
            .reduce(Set.new) {|acc, fp| acc << fp.accounting_system}
            .map {|e| Nomen::AccountingSystem[e]}
            .compact
      end
    end
  end
end
