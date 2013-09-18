module Ekylibre::Record
  module Acts #:nodoc:
    module Affairable #:nodoc:

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods

        def acts_as_affairable(*args)
          options = (args[-1].is_a?(Hash) ? args.delete_at(-1) : {})
          reflection = self.reflections[args[0] || options[:reflection] || :affair]
          currency = options[:currency] || :currency
          options[:dealt_on] ||= :created_on
          options[:amount] ||= :amount
          options[:debit] = true unless options.has_key?(:debit)

          code  = ""

          affair, affair_id = :affair, :affair_id
          if reflection
            affair, affair_id = reflection.name, reflection.foreign_key
          else
            raise Exception.new("Unable to acts as affairable no affair column") unless self.columns_definition[affair_id]
            code << "belongs_to :#{affair}, inverse_of: :#{self.name.underscore.pluralize}\n"
          end

          code << "delegate :credit, :debit, :closed?, to: :affair, prefix: true\n"

          # Marks model as affairable
          code << "def self.affairable_options\n"
          code << "  return {:reflection => :#{affair}, :currency => :#{currency}, :third => :#{options[:role] || options[:third]}}\n"
          code << "end\n"

          # Refresh after each save
          code << "validate do\n"
          code << "  if self.#{affair}\n"
          code << "    unless self.#{affair}.currency == self.#{currency}\n"
          code << "      errors.add(:#{affair}, :invalid_currency, got: self.#{currency}, expected: self.#{affair}.currency)\n"
          code << "      errors.add(:#{affair_id}, :invalid_currency, got: self.#{currency}, expected: self.#{affair}.currency)\n"
          code << "    end\n"
          code << "  end\n"
          code << "  return true\n"
          code << "end\n"

          # Create "empty" affair if missing before every save
          code << "before_save do\n"
          code << "  unless self.#{affair}\n"
          code << "    #{affair} = Affair.new\n"
          code << "    #{affair}.currency = self.#{currency}\n"
          code << "    #{affair}.third    = self.deal_third\n"
          code << "    #{affair}.save!\n"
          code << "    self.#{affair_id} = #{affair}.id\n"
          code << "  end\n"
          code << "  return true\n"
          code << "end\n"

          # Refresh after each save
          code << "after_save do\n"
          code << "  Affair.find(self.#{affair_id}).save!\n"
          code << "  Affair.clean_deads\n"
          code << "  return true\n"
          code << "end\n"

          # Return if deal is a debit for us
          code << "def deal_debit?\n"
          if options[:debit].is_a?(TrueClass)
            code << "  return true\n"
          elsif options[:debit].is_a?(FalseClass)
            code << "  return false\n"
          elsif options[:debit].is_a?(Symbol)
            code << "  return self.#{options[:debit]}\n"
          else
            raise ArgumentError.new("Option :debit must be boolean or Symbol")
          end
          code << "end\n"

          # Return if deal is a credit for us
          code << "def deal_credit?\n"
          if options[:debit].is_a?(TrueClass)
            code << "  return false\n"
          elsif options[:debit].is_a?(FalseClass)
            code << "  return true\n"
          elsif options[:debit].is_a?(Symbol)
            code << "  return !self.#{options[:debit]}\n"
          end
          code << "end\n"

          # Define which amount to take in account
          if options[:amount].is_a?(Symbol)
            code << "def deal_amount\n"
            code << "  return self.#{options[:amount]}\n"
            code << "end\n"
          elsif options[:amount].is_a?(Proc)
            define_method(:deal_amount, &options[:amount])
          end

          # Define debit amount
          code << "def deal_debit_amount\n"
          code << "  return (self.deal_debit? ? self.deal_amount : 0)\n"
          code << "end\n"

          # Define credit amount
          code << "def deal_credit_amount\n"
          code << "  return (self.deal_credit? ? self.deal_amount : 0)\n"
          code << "end\n"

          # Define which date to take in account
          if options[:dealt_on].is_a?(Symbol)
            code << "def dealt_on\n"
            code << "  return self.#{options[:dealt_on]}\n"
            code << "end\n"
          elsif options[:dealt_on].is_a?(Proc)
            define_method(:dealt_on, &options[:dealt_on])
          end

          # Define the third of the deal
          if options[:third].is_a?(Symbol)
            code << "def deal_third\n"
            code << "  return self.#{options[:third]}\n"
            code << "end\n"
          elsif options[:third].is_a?(Proc)
            define_method(:deal_third, &options[:third])
          end

          # code.split("\n").each_with_index{|x, i| puts((i+1).to_s.rjust(4)+": "+x)}

          class_eval(code)
        end
      end

    end
  end
end
Ekylibre::Record::Base.send(:include, Ekylibre::Record::Acts::Affairable)
