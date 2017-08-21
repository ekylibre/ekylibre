module Ekylibre
  module Record
    module Acts #:nodoc:
      module Affairable #:nodoc:
        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods
          def acts_as_affairable(*args)
            options = args.extract_options!
            options[:dealt_at] ||= :created_at
            options[:amount] ||= :amount
            options[:debit] = true unless options.key?(:debit)

            options[:third] ||= args.shift || :third
            options[:role] ||= options[:third].to_s
            options[:good] ||= :debit

            class_name = options[:class_name] || name + 'Affair'
            foreign_key = options[:foreign_key] || :affair_id
            reflection_name = options[:reflection] || :affair
            reflection = reflect_on_association(reflection_name)
            currency = options[:currency] || :currency

            code = ''

            if reflection
              reflection_name = reflection.name
              foreign_key = reflection.foreign_key
            else
              unless columns_definition[foreign_key]
                Rails.logger.fatal 'Unable to acts as affairable without affair column'
                # raise StandardError, "Unable to acts as affairable no affair column"
              end
              code << "belongs_to :#{reflection_name}, inverse_of: :#{name.underscore.pluralize}, foreign_key: :#{foreign_key}\n"
            end

            # default scope for affairable
            # code << "scope :affairable, -> { where('affair_id IN (SELECT id FROM affairs WHERE closed = FALSE)') }\n"
            code << "scope :affairable, -> { where(#{reflection_name}: Affair.opened) }\n"

            # Need to log strange things on delegate
            { credit: 0,
              debit: 0,
              closed: false,
              balance: 0,
              status: 'stop' }.each do |meth, default_value|
              code << "def #{reflection_name}_#{meth}\n"
              code << "  unless #{reflection_name}\n"
              code << "    Rails.logger.warn 'No affair on ' + self.class.name + ' ID=' + self.id.to_s\n"
              code << "    return #{default_value.inspect}\n"
              code << "  end\n"
              code << "  #{reflection_name}.#{meth}\n"
              code << "end\n"
            end
            code << "alias #{reflection_name}_closed? #{reflection_name}_closed\n"

            # Refresh after each save
            code << "validate do\n"
            code << "  if self.#{reflection_name}\n"
            code << "    if self.#{reflection_name}.currency? && self.#{currency}? && self.#{reflection_name}.currency != self.#{currency}\n"
            code << "      raise \"Invalid currency in affair. Expecting: \#{self.currency}. Got: \#{self.#{reflection_name}.currency}\"\n"
            code << "      errors.add(:#{reflection_name}, :invalid_currency, got: self.#{currency}, expected: self.#{reflection_name}.currency)\n"
            code << "      errors.add(:#{foreign_key}, :invalid_currency, got: self.#{currency}, expected: self.#{reflection_name}.currency)\n"
            code << "    end\n"
            code << "  end\n"
            # code << "  true\n"
            code << "end\n"

            # Create "empty" affair if missing before every save
            code << "after_save do\n"
            code << "  if self.#{reflection_name}\n"
            code << "    self.#{reflection_name}.refresh!\n"
            code << "  else\n"
            code << "    fetch_affair!\n"
            code << "  end\n"
            code << "end\n"

            # Update affair after destroy
            code << "after_destroy do\n"
            code << "  if self.#{reflection_name}\n"
            code << "    self.#{reflection_name}.refresh!\n"
            code << "  end\n"
            code << "end\n"

            # Refresh after each save
            code << "def deal_with!(affair, dones = [])\n"
            code << "  unless affair.is_a?(#{class_name})\n"
            code << "    raise \"\#{affair.class.name} (ID=\#{affair.id}) cannot be merged in #{class_name}\"\n"
            code << "  end\n"
            code << "  return self if self.#{foreign_key} == affair.id\n"
            code << "  dones << self\n"
            code << "  if affair.currency != self.currency\n"
            code << "    raise ArgumentError, \"The currency (\#{self.currency}) is different of the affair currency(\#{affair.currency})\"\n"
            code << "  end\n"
            code << "  Ekylibre::Record::Base.transaction do\n"
            code << "    if old_#{reflection_name} = self.#{reflection_name}\n"
            code << "      self.other_deals.each do |deal|\n"
            code << "        deal.deal_with!(affair, dones) unless dones.include?(deal)\n"
            code << "      end\n"
            # code << "      old_#{reflection_name}.destroy!\n"
            code << "      #{class_name}.destroy(old_#{reflection_name}.id) if #{class_name}.find_by(id: old_#{reflection_name}.id)\n"
            code << "    end\n"
            code << "    self.update_column(:#{foreign_key}, affair.id)\n"
            code << "    affair.refresh!\n"
            code << "  end\n"
            code << "  return self.reload\n"
            code << "end\n"

            code << "def undeal!(from_affair = nil)\n"
            code << "  if from_affair and from_affair.id != self.#{foreign_key}\n"
            code << "    raise ArgumentError, \"Cannot undeal from this unknown affair #\#{reflection_name.id}\"\n"
            code << "  end\n"
            code << "  Ekylibre::Record::Base.transaction do\n"
            code << "    old_#{reflection_name} = self.#{reflection_name}\n"
            code << "    affair = #{class_name}.create!(currency: self.currency, third: self.deal_third)\n"
            code << "    self.update_column(:#{foreign_key}, affair.id)\n"
            code << "    affair.refresh!\n"
            code << "    old_#{reflection_name}.refresh!\n"
            code << "    if old_#{reflection_name}.deals_count.zero?\n"
            code << "      old_#{reflection_name}.destroy!\n"
            code << "    end\n"
            code << "  end\n"
            code << "end\n"

            # Define if detachable
            code << "def detachable?\n"
            code << "  return self.other_deals.any?\n"
            code << "end\n"

            # Return if deal is a debit for us
            code << "def good_deal?\n"
            code += if options[:good] == :debit
                      "  return self.deal_debit?\n"
                    elsif options[:good] == :credit
                      "  return self.deal_credit?\n"
                    else
                      "  return self.#{options[:good]}\n"
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
              raise ArgumentError, 'Option :debit must be boolean or Symbol'
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

            # # Define debit amount
            # code << "def deal_debit_amount\n"
            # code << "  return (self.deal_debit? ? self.deal_amount : 0)\n"
            # code << "end\n"

            # # Define credit amount
            # code << "def deal_credit_amount\n"
            # code << "  return (self.deal_credit? ? self.deal_amount : 0)\n"
            # code << "end\n"

            code << "def our_deal_balance\n"
            code << "  deal_mode_amount('real_credit - real_debit')\n"
            code << "end\n"

            code << "def third_deal_balance\n"
            code << "  deal_mode_amount('real_debit - real_credit')\n"
            code << "end\n"

            code << "def deal_debit_amount\n"
            code << "  deal_mode_amount(:debit)\n"
            code << "end\n"

            code << "def deal_credit_amount\n"
            code << "  deal_mode_amount(:credit)\n"
            code << "end\n"

            # Define credit amount
            code << "def deal_mode_amount(mode)\n"
            code << "  (self.journal_entry && self.affair) ? self.journal_entry.items.where(account: self.affair.third_account).sum(mode.is_a?(Symbol) ? 'real_' + mode.to_s : mode) : 0\n"
            code << "end\n"

            # Returns other deals
            code << "def other_deals\n"
            code << "  fetch_affair!.deals.delete_if{|x| x == self}\n"
            code << "end\n"

            # Initialize linked affair
            code << "def fetch_affair!\n"
            code << "  return self.#{reflection_name} if self.#{reflection_name}\n"
            code << "  new_affair = #{class_name}.create!(currency: self.#{currency}, third: self.deal_third)\n"
            code << "  self.deal_with!(new_affair)\n"
            code << "  new_affair\n"
            code << "end\n"

            # Returns other deals
            code << "def other_deals_of_same_type\n"
            code << "  return fetch_affair!.deals.delete_if{|x| x == self or !x.is_a?(self.class)}\n"
            code << "end\n"

            code << "def self.deal_third\n"
            code << "  return self.reflect_on_association(:#{options[:third]})\n"
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

            # code.split("\n").each_with_index{|x, i| puts((i+1).to_s.rjust(4).white + ": " + x.blue)}

            class_eval(code)
          end
        end
      end
    end
  end
end
Ekylibre::Record::Base.send(:include, Ekylibre::Record::Acts::Affairable)
