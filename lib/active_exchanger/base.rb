module ActiveExchanger

  class Base

    cattr_accessor :exchangers

    @@exchangers = {}

    class << self

      def inherited(subclass)
        name = subclass.exchanger_name
        unless Nomen::ExchangeNatures[name]
          raise "Unknown exchange: #{name}"
        end
        ActiveExchanger::Base.register_exchanger(subclass)
      end

      def exchanger_name
        return self.name.to_s.underscore.gsub(/_exchanger$/, '').gsub('/', '_').to_sym
      end

      def register_exchanger(klass)
        @@exchangers[klass.exchanger_name] = klass
      end

      def importers
        @@exchangers.select{|k,v| v.method_defined?(:import) }.keys
      end

      def exporters
        @@exchangers.select{|k,v| v.method_defined?(:export) }.keys
      end

      def import(nature, file, options = {}, &block)
        build(nature, file, options, &block).import
      end

      def export(nature, file, options = {}, &block)
        build(nature, file, options, &block).export
      end

      def build(nature, file, options = {}, &block)
        supervisor = Supervisor.new(&block)
        unless @@exchangers[nature]
          raise "Unable to find exchanger #{nature.inspect}. (#{@@exchangers.inspect})"
        end
        return @@exchangers[nature].new(file, supervisor)
      end

      # This method check file by default by trying a run and
      # and if no exception raise, it's fine so changes are rolled back.
      def check_file!(file, &block)
        valid = false
        supervisor = Supervisor.new(&block)
        ActiveRecord::Base.transaction do
          new(file, supervisor).import
          valid = true
          raise ActiveRecord::Rollback
        end
        GC.start
        return valid
      end

    end

    attr_reader :file, :supervisor

    def initialize(file, supervisor)
      @file = file
      @supervisor = supervisor
    end

    alias :w :supervisor

    # def import
    #   raise NotImplementedError
    # end

    # def export
    #   raise NotImplementedError
    # end

  end

end
