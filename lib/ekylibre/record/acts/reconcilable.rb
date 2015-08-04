module Ekylibre::Record
  module Acts #:nodoc:
    module Reconcilable #:nodoc:
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # Add methods for reconciliating
        def acts_as_reconcilable(expense_owner, payment_owner, options = {})
          use = options[:use] || 'use'
          uses = use.pluralize
          expense = options[:expense] || 'expense'
          payment = options[:payment] || 'payment'
          attorney = options[:attorney] || 'attorney'
          expenses = expense.pluralize
          payments = payment.pluralize
          expense_owners = expense_owner.to_s.pluralize
          payment_owners = payment_owner.to_s.pluralize
          neighbours = options[:neighbours] || 'neighbours'

          code  = ''
          code += "def #{neighbours}(#{uses}=[])\n"
          code += "  for #{use} in self.#{expense}.#{uses}+self.#{payment}.#{uses}\n"
          code += "    unless #{uses}.include? #{use}\n"
          code += "      #{uses} << #{use}\n"
          code += "      #{use}.#{neighbours}(#{uses})\n"
          code += "    end\n"
          code += "  end\n"
          code += "  return #{uses}\n"
          code += "end\n"
          code += "def reconciliate\n"
          code += "  #{expense_owners}, #{payment_owners}, amount = {}, {}, 0.0\n"
          code += "  for #{use} in self.#{neighbours}\n"
          code += "    unless #{expense_owners}.values.flatten.include? #{use}.#{expense}\n"
          code += "      #{expense_owners}[#{use}.#{expense}.#{expense_owner}.id.to_s] ||= []\n"
          code += "      #{expense_owners}[#{use}.#{expense}.#{expense_owner}.id.to_s] << #{use}.#{expense}\n"
          code += "      amount += #{use}.#{expense}.amount\n"
          code += "    end\n"
          code += "    unless #{payment_owners}.values.flatten.include? #{use}.#{payment}\n"
          code += "      #{payment_owners}[#{use}.#{payment}.#{payment_owner}.id.to_s] ||= []\n"
          code += "      #{payment_owners}[#{use}.#{payment}.#{payment_owner}.id.to_s] << #{use}.#{payment}\n"
          code += "      amount -= #{use}.#{payment}.amount\n"
          code += "    end\n"
          code += "  end\n"
          code += "  return nil unless amount.zero?\n"
          code += "  for #{expense_owner}, #{expenses} in #{expense_owners}\n"
          code += "    account = self.company.entities.find(#{expense_owner}.to_i).account(:#{expense_owner})\n"
          code += "    next unless account.reconcilable?\n"
          code += "    journal_entries = []\n"
          code += "    for #{expense} in #{expenses}\n"
          code += "      journal_entries << #{expense}.journal_entry\n"
          code += "      for #{use} in #{expense}.#{uses}\n"
          code += "        if #{use}.#{payment}.#{payment_owner}_id == #{expense}.#{expense_owner}_id \n"
          code += "          journal_entries << #{use}.#{payment}.journal_entry\n"
          code += "        else #{use}.journal_entry\n"
          code += "          journal_entries << #{use}.journal_entry\n"
          code += "        end\n"
          code += "      end\n"
          code += "    end\n"
          code += "    account.mark_entries(journal_entries)\n"
          code += "  end\n"
          code += "  for #{payment_owner}, #{payments} in #{payment_owners}\n"
          code += "    account = self.company.entities.find(#{payment_owner}.to_i).account(:#{attorney})\n"
          code += "    next unless account.reconcilable?\n"
          code += "    journal_entries = []\n"
          code += "    for #{payment} in #{payments}\n"
          code += "      e = [#{payment}.journal_entry]\n"
          code += "      for #{use} in #{payment}.#{use}s\n"
          code += "        e << #{use}.journal_entry if #{use}.#{payment}.#{payment_owner}.id != #{use}.#{expense}.#{expense_owner}.id\n"
          code += "      end\n"
          code += "      journal_entries += e if e.size > 1\n"
          code += "    end\n"
          code += "    account.mark_entries(journal_entries) if journal_entries.size > 0\n"
          code += "  end\n"
          code += "  return true\n"
          code += "end\n"
          # puts code

          # list = code.split("\n"); list.each_index{|x| puts((x+1).to_s.rjust(4)+": "+list[x])}

          class_eval code
        end
      end
    end
  end
end
Ekylibre::Record::Base.send(:include, Ekylibre::Record::Acts::Reconcilable)
