module Aggeratio
  # Main base class for aggregators
  class Aggregator
    @@parameters = {}
    @@aggregator_name = 'Aggregator'
    @@category = 'none'

    # cattr_reader :category, :parameters, :parameters_hash, :aggregator_name

    class << self
      def parameters
        fail NotImplementedError.new
      end

      def aggregator_name
        fail NotImplementedError.new
      end

      def category
        fail NotImplementedError.new
      end

      def human_name
        name = aggregator_name
        ::I18n.t("aggregators.#{name}.name", default: [:"nomenclatures.document_natures.items.#{name}", :"labels.#{name}", name.to_s.humanize])
      end
    end

    def to_xml(*_args)
      fail NotImplementedError.new
    end

    def to_document_fragment(*_args)
      fail NotImplementedError.new
    end

    def to_json(*_args)
      fail NotImplementedError.new
    end

    def key
      # raise NotImplementedError.new
      Rails.logger.warn("Aggregator #{self.class.aggregator_name} should have its own :key method")
      rand(1_000_000).to_s(36)
    end
  end
end
