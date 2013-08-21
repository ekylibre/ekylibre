
class Aggregator

  class << self

    def human_name
      name = self.aggregator_name
      return ::I18n.t("aggregators.#{name}", :default => [:"labels.#{name}", name.to_s.humanize])
    end

  end

  def to_xml(options = {})
    raise NotImplementedError.new
  end

  def to_json(options = {})
    raise NotImplementedError.new
  end

  def key
    # raise NotImplementedError.new
    Rails.logger.warn("Aggregator #{self.class.aggregator_name} should have its own :key method")
    return rand(1_000_000).to_s(36)
  end

end
