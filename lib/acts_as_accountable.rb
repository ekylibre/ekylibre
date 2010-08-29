module ActiveRecord
  module Acts #:nodoc:
    module Accountable #:nodoc:
      def self.actions
        [:create, :update, :destroy]
      end
      
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_accountable(options = {})
          configuration = { :column => "accounted_at", :reference=>"journal_entry",  :callbacks=>ActiveRecord::Acts::Accountable::actions }
          configuration.update(options) if options.is_a?(Hash)

          raise Exception.new("journal_entry_id is needed for acts_as_accountable") unless columns_hash["journal_entry_id"]
          raise Exception.new("accounted_at is needed for acts_as_accountable") unless columns_hash["accounted_at"]

          code = "include ActiveRecord::Acts::Accountable::InstanceMethods\n"
          for action in ActiveRecord::Acts::Accountable::actions
            code += "after_#{action} :accountize_on_#{action}\n" if configuration[:callbacks].include? action
          end if configuration[:callbacks].is_a? Array
          class_eval code
        end

        def autosave(*reflections_list)
          code  = "after_save do\n"
          for reflection in reflections_list
            ref = self.reflections[reflection]
            raise ArgumentError.new("reflection unknown (#{self.reflections.keys.to_sentence} available)") unless ref
            
            if ref.macro == :belongs_to or ref.macro == :has_one
              code += "  self.#{reflection}.reload.save if self.#{reflection}\n"
            else
              code += "  for item in #{reflection}\n"
              code += "    item.reload.save\n"
              code += "  end\n"
            end
          end
          code += "end\n"
          class_eval code
        end

      end

      module InstanceMethods

        def accountize(action, attributes={}, options={}, &block)
          raise ArgumentError.new("Unvalid action #{action.inspect} (#{ActiveRecord::Acts::Accountable::actions.to_sentence} are accepted)") unless ActiveRecord::Acts::Accountable::actions.include? action
          attributes ||= {}
          attributes[:resource]   ||= self
          attributes[:draft_mode] ||= self.company.draft_mode?
          attributes[:printed_on] ||= self.created_on if self.respond_to? :created_on
          attributes[:journal] = self.company.journals.find_by_id(attributes.delete(:journal_id)) if attributes[:journal_id]
          raise ArgumentError.new("Missing attribute :journal (#{attributes[:journal].inspect})") unless attributes[:journal].is_a? Journal
          ActiveRecord::Base.transaction do
            # Cancel the existing journal_entry
            if self.journal_entry and not self.journal_entry.closed? and (attributes[:journal] == self.journal_entry.journal)
              self.journal_entry.entries.destroy_all
              self.journal_entry.reload
              self.journal_entry.update_attributes!(attributes)
            elsif self.journal_entry
              self.journal_entry.cancel
              self.journal_entry = nil
            end

            # Add journal entries
            if block_given? and not options[:unless] and action != :destroy
              self.journal_entry ||= self.company.journal_entries.create!(attributes)
              yield(self.journal_entry)
            end
            
            # Set accounted columns
            self.class.update_all({:accounted_at=>Time.now, :journal_entry_id=>self.journal_entry_id}, {:id=>self.id})
          end
        end

        def to_accountancy(action=:create, options={})
          raise NotImplementedError.new("Need to implement the method #{self.class.name}::to_accountancy")
        end

        def accounted?
          self.accounted_at
        end

        def accountize_on_create
          self.to_accountancy(:create) if self.company.accountizing?
        end

        def accountize_on_update
          self.to_accountancy(:update) if self.company.accountizing?            
        end

        def accountize_on_destroy
          self.to_accountancy(:destroy) if self.company.accountizing?
        end

      end 


    end
  end
end
ActiveRecord::Base.class_eval { include ActiveRecord::Acts::Accountable }
