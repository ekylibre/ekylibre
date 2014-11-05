module Ekylibre::Record
  module Acts #:nodoc:
    module Affairable #:nodoc:

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods

        def acts_as_affairable(*args)
          options = args.extract_options!
          reflection = self.reflections[options[:reflection] || :affair]
          currency = options[:currency] || :currency
          options[:dealt_at] ||= :created_at
          options[:amount] ||= :amount
          options[:debit] = true unless options.has_key?(:debit)

          options[:third] ||= args.shift || :third
          options[:role]  ||= options[:third].to_s
          options[:good]  ||= :debit
          code  = ""

          affair, affair_id = :affair, :affair_id
          if reflection
            affair, affair_id = reflection.name, reflection.foreign_key
          else
            unless self.columns_definition[affair_id]
              Rails.logger.fatal "Unable to acts as affairable without affair column"
              # raise StandardError, "Unable to acts as affairable no affair column"
            end
            code << "belongs_to :#{affair}, inverse_of: :#{self.name.underscore.pluralize}\n"
          end
          code << "has_many :affairs, as: :originator, dependent: :destroy\n"

          code << "delegate :credit, :debit, :closed?, to: :affair, prefix: true\n"

          # default scope for affairable
          code << "scope :affairable, -> { where('#{affair_id} IN (SELECT id FROM affairs WHERE NOT closed)') }\n"

          # # Marks model as affairable
          # code << "def self.affairable_options\n"
          # code << "  return {reflection: :#{affair}, currency: :#{currency}, third: :#{options[:third]}, third_role: :#{options[:role]}}\n"
          # code << "end\n"

          # Refresh after each save
          code << "validate do\n"
          code << "  if self.#{affair}\n"
          code << "    unless self.#{affair}.currency == self.#{currency}\n"
          code << "      errors.add(:#{affair}, :invalid_currency, got: self.#{currency}, expected: self.#{affair}.currency)\n"
          code << "      errors.add(:#{affair_id}, :invalid_currency, got: self.#{currency}, expected: self.#{affair}.currency)\n"
          code << "    end\n"
          code << "  end\n"
          # code << "  return true\n"
          code << "end\n"

          # Updates affair if already given
          code << "after_create do\n"
          code << "  if self.#{affair}\n"
          code << "    self.#{affair}.refresh!\n"
          code << "  end\n"
          # code << "  return true\n"
          code << "end\n"

          # Create "empty" affair if missing before every save
          code << "after_save do\n"
          code << "  if self.#{affair}\n"
          code << "    self.affair.refresh!\n"
          code << "  else\n"
          code << "    #{affair} = Affair.create!(currency: self.#{currency}, third: self.deal_third, originator: self)\n"
          code << "    self.deal_with!(#{affair})\n"
          code << "  end\n"
          # code << "  return true\n"
          code << "end\n"


          # Refresh after each save
          code << "def deal_with!(affair, dones = [])\n"
          code << "  return self if self.#{affair_id} == affair.id\n"
          code << "  dones << self\n"
          code << "  if affair.currency != self.currency\n"
          code << "    raise ArgumentError, \"The currency (\#{self.currency}) is different of the affair currency(\#{affair.currency})\"\n"
          code << "  end\n"
          code << "  Ekylibre::Record::Base.transaction do\n"
          code << "    if old_affair = self.#{affair}\n"
          code << "      for deal in self.other_deals\n"
          code << "        deal.deal_with!(affair, dones) unless dones.include?(deal)\n"
          code << "      end\n"
          # code << "      old_affair.destroy!\n"
          code << "      Affair.destroy(old_affair.id) if Affair.find_by(id: old_affair.id)\n"
          code << "    end\n"
          code << "    self.update_column(:#{affair_id}, affair.id)\n"
          code << "    affair.refresh!\n"
          code << "  end\n"
          code << "  return self.reload\n"
          code << "end\n"

          code << "def undeal!(affair = nil)\n"
          code << "  if affair and affair.id != self.#{affair_id}\n"
          # code << "    puts self.inspect.red\n"
          # code << "    puts affair.inspect.blue\n"
          code << "    raise ArgumentError, 'Cannot undeal from this unknown affair'\n"
          code << "  end\n"
          code << "  Ekylibre::Record::Base.transaction do\n"
          code << "    old_affair = self.#{affair}\n"
          code << "    affair = Affair.create!(currency: self.currency, third: self.deal_third, originator: self)\n"
          code << "    self.update_column(:#{affair_id}, affair.id)\n"
          code << "    affair.refresh!\n"
          code << "    old_affair.refresh!\n"
          code << "    if old_affair.deals_count.zero?\n"
          code << "      old_affair.destroy!\n"
          code << "    end\n"
          code << "  end\n"
          code << "end\n"

          # Define if detachable
          code << "def detachable?\n"
          code << "  return self.other_deals.any?\n"
          code << "end\n"


          # # Create "empty" affair if missing before every save
          # code << "before_save do\n"
          # code << "  unless self.#{affair}\n"
          # code << "    self.build_#{affair}(currency: self.#{currency}, third: self.deal_third)\n"
          # code << "  end\n"
          # code << "  return true\n"
          # code << "end\n"

          # # Create "empty" affair if missing before every save
          # code << "before_save do\n"
          # code << "  unless self.#{affair}\n"
          # code << "    #{affair} = Affair.new\n"
          # code << "    #{affair}.currency = self.#{currency}\n"
          # code << "    #{affair}.third    = self.deal_third\n"
          # code << "    #{affair}.save!\n"
          # code << "    self.#{affair_id} = #{affair}.id\n"
          # code << "  end\n"
          # code << "  return true\n"
          # code << "end\n"

          # # Refresh after each save
          # code << "after_save do\n"
          # code << "  Affair.find(self.#{affair_id}).save!\n"
          # code << "  Affair.clean_deads\n"
          # code << "  return true\n"
          # code << "end\n"

          # Return if deal is a debit for us
          code << "def good_deal?\n"
          if options[:good] == :debit
            code << "  return self.deal_debit?\n"
          elsif options[:good] == :credit
            code << "  return self.deal_credit?\n"
          else
            code << "  return self.#{options[:good]}\n"
          end
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
            raise ArgumentError, "Option :debit must be boolean or Symbol"
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
          code << "alias_attribute :deal_amount, :#{options[:amount]}\n"

          # Define which date to take in account
          code << "alias_attribute :dealt_at, :#{options[:dealt_at]}\n"

          # Define the third of the deal
          code << "alias_attribute :deal_third, :#{options[:third]}\n"

          # Define debit amount
          code << "def deal_debit_amount\n"
          code << "  return (self.deal_debit? ? self.deal_amount : 0)\n"
          code << "end\n"

          # Define credit amount
          code << "def deal_credit_amount\n"
          code << "  return (self.deal_credit? ? self.deal_amount : 0)\n"
          code << "end\n"

          # Define credit amount
          code << "def deal_mode_amount(mode = :debit)\n"
          code << "  if mode == :credit\n"
          code << "    return (self.deal_credit? ? self.deal_amount : 0)\n"
          code << "  else\n"
          code << "    return (self.deal_debit?  ? self.deal_amount : 0)\n"
          code << "  end\n"
          code << "end\n"

          # Returns other deals
          code << "def other_deals\n"
          code << "  return self.#{affair}.deals.delete_if{|x| x == self}\n"
          code << "end\n"

          # Returns other deals
          code << "def other_deals_of_same_type\n"
          code << "  return self.#{affair}.deals.delete_if{|x| x == self or !x.is_a?(self.class)}\n"
          code << "end\n"

          code << "def self.deal_third\n"
          code << "  return self.reflections[:#{options[:third]}]\n"
          code << "end\n"

          # Define the third of the deal
          if options[:taxes].is_a?(Symbol)
            code << "alias_attribute :deal_taxes, :#{options[:taxes]}\n"
          elsif ![TrueClass].include?(options[:taxes].class)
            # Computes based on opposite operation taxes
            code << "def deal_taxes(mode = :debit)\n"
            code << "  return [] if self.deal_mode_amount(mode).zero?\n"
            code << "  return [{amount: self.deal_mode_amount(mode)}]\n"
            code << "end\n"
          end


          # Define the third of the deal
          code << "def deal_third_role\n"
          if options[:role].is_a?(Symbol)
            code << "  return self.#{options[:role]}\n"
          else
            code << "  return #{options[:role].to_sym.inspect}\n"
          end
          code << "end\n"

          # code.split("\n").each_with_index{|x, i| puts((i+1).to_s.rjust(4).white + ": " + x.blue)}

          class_eval(code)
        end
      end

    end
  end
end
Ekylibre::Record::Base.send(:include, Ekylibre::Record::Acts::Affairable)
