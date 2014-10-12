# Main base class for aggregators
class Aggregator
  @@parameters = {}
  @@aggregator_name = 'Aggregator'
  @@category = 'none'

  # cattr_reader :category, :parameters, :parameters_hash, :aggregator_name

  class << self

    def parameters
      raise NotImplementedError.new
    end

    def aggregator_name
      raise NotImplementedError.new
    end

    def category
      raise NotImplementedError.new
    end

    def human_name
      name = self.aggregator_name
      return ::I18n.t("aggregators.#{name}.name", :default => [:"nomenclatures.document_natures.items.#{name}", :"labels.#{name}", name.to_s.humanize])
    end

  end

  def to_xml(*args)
    raise NotImplementedError.new
  end

  def to_document_fragment(*args)
    raise NotImplementedError.new
  end

  def to_json(*args)
    raise NotImplementedError.new
  end

  def key
    # raise NotImplementedError.new
    Rails.logger.warn("Aggregator #{self.class.aggregator_name} should have its own :key method")
    return rand(1_000_000).to_s(36)
  end

end
