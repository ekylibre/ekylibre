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
          configuration = { :column => "accounted_at", :reference=>"journal_record",  :callbacks=>ActiveRecord::Acts::Accountable::actions }
          configuration.update(options) if options.is_a?(Hash)

          raise Exception.new("journal_record_id is needed for acts_as_accountable") unless columns_hash["journal_record_id"]
          raise Exception.new("accounted_at is needed for acts_as_accountable") unless columns_hash["accounted_at"]

          code = "include ActiveRecord::Acts::Accountable::InstanceMethods\n"
          for action in ActiveRecord::Acts::Accountable::actions
            code += "after_#{action} :accountize_on_#{action}\n" if configuration[:callbacks].include? action
          end if configuration[:callbacks].is_a? Array
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
            # Cancel the existing journal_record
            if self.journal_record
              if not self.journal_record.closed? and (attributes[:journal] == self.journal_record.journal)
                self.journal_record.entries.destroy_all
                self.journal_record.reload
                self.journal_record.update_attributes!(attributes)
              else
                self.journal_record.cancel
                self.journal_record = nil
              end
            end

            # Add journal entries
            if block_given? and not options[:unless] and action != :destroy
              self.journal_record ||= self.company.journal_records.create!(attributes)
              yield(self.journal_record)
            end
            
            # Set accounted columns
            self.class.update_all({:accounted_at=>Time.now, :journal_record_id=>self.journal_record_id}, {:id=>self.id})
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
