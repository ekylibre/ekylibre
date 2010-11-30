module Ekylibre::Record
  module Acts #:nodoc:
    module Accountable #:nodoc:
      def self.actions
        [:create, :update, :destroy]
      end

      class Bookkeep
        attr_reader :resource, :action, :draft

        cattr_reader :id
        @@id = "0"

        def self.next_id
          @@id.succ!
          return @@id
        end

        def initialize(resource, action, draft)
          raise ArgumentError.new("Unvalid action #{action.inspect} (#{Ekylibre::Record::Acts::Accountable::actions.to_sentence} are accepted)") unless Ekylibre::Record::Acts::Accountable::actions.include? action
          @resource = resource
          @action = action
          @draft = draft
        end

        

        def journal_entry(journal, options={}, &block)
          column = options.delete(:column)||:journal_entry_id
          condition = (options.has_key?(:if) ? options.delete(:if) : !options.delete(:unless))

          attributes = options
          attributes[:resource]   ||= @resource
          # attributes[:state]      ||= @state
          attributes[:printed_on] ||= @resource.created_on if @resource.respond_to? :created_on
          attributes[:journal] = journal
          raise ArgumentError.new("Unknown journal: (#{attributes[:journal].inspect})") unless attributes[:journal].is_a? Journal

          Ekylibre::Record::Base.transaction do
            journal_entry = @resource.company.journal_entries.find_by_id(@resource.send(column)) rescue nil

            # Cancel the existing journal_entry
            if journal_entry and journal_entry.draft? and (attributes[:journal].id == journal_entry.journal_id)
              journal_entry.lines.destroy_all
              journal_entry.reload
              journal_entry.update_attributes!(attributes)
            elsif journal_entry
              journal_entry.cancel
              journal_entry = nil
            end

            # Add journal lines
            if block_given? and condition and @action != :destroy
              journal_entry ||= @resource.company.journal_entries.create!(attributes)
              yield(journal_entry)
              journal_entry.confirm unless @draft
            end
            
            # Set accounted columns
            @resource.class.update_all({:accounted_at=>Time.now, column=>(journal_entry ? journal_entry.id : nil)}, {:id=>@resource.id})
          end
        end
        

      end
      
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods

        def bookkeep(options = {}, &block)
          raise ArgumentError.new("No given block") unless block_given?
          raise ArgumentError.new("Wrong number of arguments (#{block.arity} for 1)") unless block.arity == 1
          configuration = { :on=>Ekylibre::Record::Acts::Accountable::actions, :column=>:accounted_at, :method_name=>:bookkeep }
          configuration.update(options) if options.is_a?(Hash)
          configuration[:column] = configuration[:column].to_s
          method_name = configuration[:method_name].to_s
          core_method_name ||= "_#{method_name}_#{Ekylibre::Record::Acts::Accountable::Bookkeep.next_id}"
          
          unless Ekylibre::Record::Base.connection.adapter_name.lower == "sqlserver"
            # raise Exception.new("journal_entry_id is needed for #{self.name}.acts_as_accountable") unless columns_hash["journal_entry_id"]
            raise Exception.new("#{configuration[:column]} is needed for #{self.name}.acts_as_accountable") unless columns_hash[configuration[:column]]
          end

          code = "include Ekylibre::Record::Acts::Accountable::InstanceMethods\n"

          # raise Exception.new("#{method_name} method already defined. Use :method_name option to choose a different name.") if self.instance_methods.include?(method_name.to_sym)
          code += "def #{method_name}(action=:create, draft=nil)\n"
          code += "  draft = self.company.prefer_bookkeep_in_draft? if draft.nil?\n"
          code += "  self.#{core_method_name}(Ekylibre::Record::Acts::Accountable::Bookkeep.new(self, action, draft))\n"
          code += "  self.class.update_all({:#{configuration[:column]}=>Time.now}, {:id=>self.id})\n"
          code += "end\n"

          configuration[:on] = [configuration[:on]] if configuration[:on].is_a? Symbol and configuration[:on] != :nothing
          for action in Ekylibre::Record::Acts::Accountable::actions
            if configuration[:on].include? action
              code += "after_#{action} do \n" 
              code += "  self.#{method_name}(:#{action}, self.company.prefer_bookkeep_in_draft?) if self.company.prefer_bookkeep_automatically?\n"
              code += "end\n"
            end
          end if configuration[:on].is_a? Array

          class_eval code
          
          self.send(:define_method, core_method_name, block)
        end

      end

      module InstanceMethods

        def accounted?
          not self.accounted_at.nil?
        end

      end 


    end
  end
end
Ekylibre::Record::Base.send(:include, Ekylibre::Record::Acts::Accountable)
