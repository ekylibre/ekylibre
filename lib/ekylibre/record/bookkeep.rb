module Ekylibre::Record  #:nodoc:
  module Bookkeep
    def self.actions
      [:create, :update, :destroy]
    end

    class Base
      attr_reader :resource, :action, :draft

      cattr_reader :id
      @@id = "0"

      def self.next_id
        @@id.succ!
        return @@id
      end

      def initialize(resource, action, draft)
        raise ArgumentError.new("Unvalid action #{action.inspect} (#{Ekylibre::Record::Bookkeep::actions.to_sentence} are accepted)") unless Ekylibre::Record::Bookkeep::actions.include? action
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
        if condition
          raise ArgumentError.new("Unknown journal: (#{journal.inspect})") unless journal.is_a? Journal
          attributes[:journal_id] = journal.id
        end

        Ekylibre::Record::Base.transaction do
          journal_entry = JournalEntry.find_by_id(@resource.send(column)) rescue nil

          # Cancel the existing journal_entry
          if journal_entry and journal_entry.draft? and condition and (attributes[:journal].id == journal_entry.journal_id)
            journal_entry.lines.destroy_all
            journal_entry.reload
            journal_entry.update_attributes!(attributes)
          elsif journal_entry
            journal_entry.cancel
            journal_entry = nil
          end

          # Add journal lines
          if block_given? and condition and @action != :destroy
            journal_entry ||= JournalEntry.create!(attributes)
            yield(journal_entry)
            journal_entry.reload.confirm unless @draft
          end

          # Set accounted columns
          @resource.class.update_all({:accounted_at => Time.now, column => (journal_entry ? journal_entry.id : nil)}, {:id => @resource.id})
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
        configuration = { :on => Ekylibre::Record::Bookkeep::actions, :column => :accounted_at, :method_name => :bookkeep }
        configuration.update(options) if options.is_a?(Hash)
        configuration[:column] = configuration[:column].to_s
        method_name = configuration[:method_name].to_s
        core_method_name ||= "_#{method_name}_#{Ekylibre::Record::Bookkeep::Base.next_id}"

        unless Ekylibre::Record::Base.connection.adapter_name == "SQLServer"
          # raise Exception.new("journal_entry_id is needed for #{self.name}.bookkeep") unless columns_hash["journal_entry_id"]
          raise Exception.new("#{configuration[:column]} is needed for #{self.name}.bookkeep") unless columns_hash[configuration[:column]]
        end

        code = "include Ekylibre::Record::Bookkeep::InstanceMethods\n"

        # code += "before_update  {|record| return false if record.#{}.closed? }"
        # code += "before_destroy {|record| return false unless record.destroyable? }"

        # raise Exception.new("#{method_name} method already defined. Use :method_name option to choose a different name.") if self.instance_methods.include?(method_name.to_sym)
        code += "def #{method_name}(action = :create, draft = nil)\n"
        code += "  draft = ::Preference[:bookkeep_in_draft] if draft.nil?\n"
        code += "  self.#{core_method_name}(Ekylibre::Record::Bookkeep::Base.new(self, action, draft))\n"
        code += "  self.class.update_all({:#{configuration[:column]} => Time.now}, {:id => self.id})\n"
        code += "end\n"

        configuration[:on] = [configuration[:on]] if configuration[:on].is_a? Symbol and configuration[:on] != :nothing
        for action in Ekylibre::Record::Bookkeep::actions
          if configuration[:on].include? action
            code += "after_#{action} do \n"
            code += "  self.#{method_name}(:#{action}, ::Preference[:bookkeep_in_draft]) if ::Preference[:bookkeep_automatically]\n"
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
Ekylibre::Record::Base.send(:include, Ekylibre::Record::Bookkeep)
