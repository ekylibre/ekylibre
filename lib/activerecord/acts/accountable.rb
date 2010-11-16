module ActiveRecord
  module Acts #:nodoc:
    module Accountable #:nodoc:
      def self.actions
        [:create, :update, :destroy]
      end

      class Bookkeep

        cattr_reader :id
        @@id = "0"

        def self.next_id
          @@id.succ!
          return @@id
        end

        def initialize(resource, action, state)
          raise ArgumentError.new("Unvalid action #{action.inspect} (#{ActiveRecord::Acts::Accountable::actions.to_sentence} are accepted)") unless ActiveRecord::Acts::Accountable::actions.include? action
          @resource = resource
          @action = action
          @state = state
        end

        

        def journal_entry(journal, options={}, &block)
          column = options.delete(:column)||:journal_entry_id
          condition = (options.has_key?(:if) ? options.delete(:if) : !options.delete(:unless))

          attributes = options
          attributes[:resource]   ||= @resource
          attributes[:state]      ||= @state
          attributes[:printed_on] ||= @resource.created_on if @resource.respond_to? :created_on
          attributes[:journal] = journal
          raise ArgumentError.new("Unknown journal: (#{attributes[:journal].inspect})") unless attributes[:journal].is_a? Journal

          ActiveRecord::Base.transaction do
            journal_entry = @resource.company.journal_entries.find_by_id(@resource.send(column)) rescue nil

            # Cancel the existing journal_entry
            if journal_entry and not journal_entry.closed? and (attributes[:journal].id == journal_entry.journal_id)
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
          configuration = { :on=>ActiveRecord::Acts::Accountable::actions, :column=>:accounted_at }
          configuration.update(options) if options.is_a?(Hash)
          configuration[:column] = configuration[:column].to_s
          core_method_name ||= "_bookkeep_#{ActiveRecord::Acts::Accountable::Bookkeep.next_id}"
          
          unless ActiveRecord::Base.connection.adapter_name.lower == "sqlserver"
            # raise Exception.new("journal_entry_id is needed for #{self.name}.acts_as_accountable") unless columns_hash["journal_entry_id"]
            raise Exception.new("#{configuration[:column]} is needed for #{self.name}.acts_as_accountable") unless columns_hash[configuration[:column]]
          end


          code = "include ActiveRecord::Acts::Accountable::InstanceMethods\n"

          code += "def bookkeep(action, draft)\n"
          code += "  self.#{core_method_name}(ActiveRecord::Acts::Accountable::Bookkeep.new(self, action, draft))\n"
          code += "  self.class.update_all({:#{configuration[:column]}=>Time.now}, {:id=>self.id})\n"
          code += "end\n"

          configuration[:on] = [configuration[:on]] if configuration[:on].is_a? Symbol and configuration[:on] != :nothing
          for action in ActiveRecord::Acts::Accountable::actions
            if configuration[:on].include? action
              code += "after_#{action} do \n" 
              code += "  self.bookkeep(:#{action}, (self.company.prefer_bookkeep_in_draft? ? :draft : :confirmed)) if self.company.prefer_bookkeep_automatically?\n"
              code += "end\n"
            end
          end if configuration[:on].is_a? Array

          class_eval code
          
          define_method(core_method_name) do |bk|
            block.call(bk)
          end
        end

      end

      module InstanceMethods

#         def def_journal_entry(journal, action, options={}, &block)
#           raise ArgumentError.new("Unvalid action #{action.inspect} (#{ActiveRecord::Acts::Accountable::actions.to_sentence} are accepted)") unless ActiveRecord::Acts::Accountable::actions.include? action
#           attributes ||= {}
#           attributes[:resource]   ||= self
#           attributes[:draft_mode] ||= self.company.prefer_accountize_in_draft?
#           attributes[:printed_on] ||= self.created_on if self.respond_to? :created_on
#           attributes[:journal] = self.company.journals.find_by_id(attributes.delete(:journal_id)) if attributes[:journal_id]
#           raise ArgumentError.new("Missing attribute :journal (#{attributes[:journal].inspect})") unless attributes[:journal].is_a? Journal

#           column = options[:column]||:journal_entry_id
#           ActiveRecord::Base.transaction do
#             journal_entry = self.company.journal_entries.find_by_id(self.send(column)) rescue nil

#             # Cancel the existing journal_entry
#             if journal_entry and not journal_entry.closed? and (attributes[:journal] == journal_entry.journal)
#               journal_entry.lines.destroy_all
#               journal_entry.reload
#               journal_entry.update_attributes!(attributes)
#             elsif journal_entry
#               journal_entry.cancel
#               journal_entry = nil
#             end

#             # Add journal lines
#             if block_given? and (options.keys.include?(:if) ? options[:if] : !options[:unless]) and action != :destroy
#               journal_entry ||= self.company.journal_entries.create!(attributes)
#               yield(journal_entry)
#             end
            
#             # Set accounted columns
#             self.class.update_all({:accounted_at=>Time.now, column=>(journal_entry ? journal_entry.id : nil)}, {:id=>self.id})
#           end
#         end

#         def to_accountancy(action=:create, draft=true)
#           raise NotImplementedError.new("Need to implement the method #{self.class.name}::to_accountancy")
#         end

        def accounted?
          not self.accounted_at.nil?
        end

      end 


    end
  end
end
ActiveRecord::Base.send(:include, ActiveRecord::Acts::Accountable)
