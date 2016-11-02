module ActiveExchanger
  class Base
    cattr_accessor :exchangers

    @@exchangers = {}

    class << self
      def inherited(subclass)
        name = subclass.exchanger_name
        ActiveExchanger::Base.register_exchanger(subclass)
        super
      end

      def exchanger_name
        name.to_s.underscore.gsub(/_exchanger$/, '').tr('/', '_').to_sym
      end

      def human_name
        "exchangers.#{exchanger_name}".t
      end

      def register_exchanger(klass)
        @@exchangers[klass.exchanger_name] = klass
      end

      def importers
        @@exchangers.select { |_k, v| v.method_defined?(:import) }
      end

      def importers_selection
        importers.collect { |i, e| [e.human_name, i] }.sort_by { |a| a.first.lower_ascii }
      end

      def exporters
        @@exchangers.select { |_k, v| v.method_defined?(:export) }
      end

      # Import file without check
      def import!(nature, file, options = {}, &block)
        build(nature, file, options, &block).import
      end

      # Import file with check if possible
      def import(nature, file, options = {}, &block)
        exchanger = build(nature, file, options, &block)
        if exchanger.respond_to? :check
          if exchanger.check
            exchanger.import
          else
            Rails.logger.warn 'Cannot import file'
            return false
          end
        else
          exchanger.import
        end
      end

      def export(nature, file, options = {}, &block)
        build(nature, file, options, &block).export
      end

      def check(nature, file, _options = {}, &block)
        supervisor = Supervisor.new(:check, &block)
        exchanger = find(nature).new(file, supervisor)
        valid = false
        ActiveRecord::Base.transaction do
          if exchanger.respond_to? :check
            exchanger.check
          else
            exchanger.import
          end
          valid = true
          raise ActiveRecord::Rollback
        end
        GC.start
        valid
      rescue
        false
      end

      def build(nature, file, _options = {}, &block)
        supervisor = Supervisor.new(&block)
        find(nature).new(file, supervisor)
      end

      def find(nature)
        klass = @@exchangers[nature.to_sym]
        unless klass
          raise "Unable to find exchanger #{nature.inspect}. (#{@@exchangers.keys.to_sentence(locale: :eng)})"
        end
        klass
      end

      # This method check file by default by trying a run and
      # and if no exception raise, it's fine so changes are rolled back.
      def check_by_default
        define_method :check do
          import
        end
      end
    end

    attr_reader :file, :supervisor

    def initialize(file, supervisor)
      @file = Pathname.new(file)
      @supervisor = supervisor
    end

    alias w supervisor

    # def import
    #   raise NotImplementedError
    # end

    # def export
    #   raise NotImplementedError
    # end

    # def check
    #   raise NotImplementedError
    # end
  end
end
