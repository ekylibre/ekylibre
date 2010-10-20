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

          
          unless ActiveRecord::Base.connection.adapter_name.lower == "sqlserver"
            # raise Exception.new("journal_entry_id is needed for #{self.name}.acts_as_accountable") unless columns_hash["journal_entry_id"]
            raise Exception.new("accounted_at is needed for #{self.name}.acts_as_accountable") unless columns_hash["accounted_at"]
          end

          code = "include ActiveRecord::Acts::Accountable::InstanceMethods\n"
          for action in ActiveRecord::Acts::Accountable::actions
            code += "after_#{action} :accountize_on_#{action}\n" if configuration[:callbacks].include? action
          end if configuration[:callbacks].is_a? Array
          class_eval code
        end

        def autosave(*reflections_list)
          code, options = '', {:callbacks=>[:after_save, :after_destroy]}
          options.merge(reflections_list.delete_at(-1)) if reflections_list.last.is_a? Hash

          method_name = options[:method] || "autosave_"+reflections_list.join("_and_")
          for callback in options[:callbacks]
            code  += "#{callback} :#{method_name}\n"
          end
          code  += "def #{method_name}\n"
          for reflection in reflections_list
            ref = self.reflections[reflection]
            raise ArgumentError.new("reflection unknown (#{self.reflections.keys.to_sentence} available)") unless ref
            
            if ref.macro == :belongs_to or ref.macro == :has_one
              code += "  if self.#{reflection}\n"
              code += "    unless self.#{reflection}.reload.save\n"
              code += "      errors.add_from_record(self.#{reflection})\n"
              code += "    end\n"
              code += "  end\n"
            else
              code += "  for item in self.#{reflection}\n"
              code += "    unless item.reload.save\n"
              code += "      errors.add_from_record(item)\n"
              code += "    end\n"
              code += "  end\n"
            end
          end
          code += "end\n"
          # list = code.split("\n"); list.each_index{|x| puts((x+1).to_s.rjust(4)+": "+list[x])}
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

          column = options[:column]||:journal_entry_id
          ActiveRecord::Base.transaction do
            journal_entry = self.company.journal_entries.find_by_id(self.send(column)) rescue nil

            # Cancel the existing journal_entry
            if journal_entry and not journal_entry.closed? and (attributes[:journal] == journal_entry.journal)
              journal_entry.lines.destroy_all
              journal_entry.reload
              journal_entry.update_attributes!(attributes)
            elsif journal_entry
              journal_entry.cancel
              journal_entry = nil
            end

            # Add journal lines
            condition = true
            condition = condition and options[:if] if options.keys.include?(:if)
            condition = condition and not options[:unless] if options.keys.include?(:unless)
            if block_given? and condition and action != :destroy
              journal_entry ||= self.company.journal_entries.create!(attributes)
              yield(journal_entry)
            end
            
            # Set accounted columns
            self.class.update_all({:accounted_at=>Time.now, column=>(journal_entry ? journal_entry.id : nil)}, {:id=>self.id})
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
