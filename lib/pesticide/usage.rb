module Pesticide
  class Usage
    attr_reader :name, :dose, :pre_harvest_interval, :max_inputs_count, :untreated_zone_margin, :mode, :issue

    def initialize(attributes = {})
      @name = attributes.delete(:name)
      @dose = Measure.new(attributes.delete(:dose)) if attributes[:dose]
      @subject = attributes.delete(:subject) || {}
      @mode = attributes.delete(:mode)
      @issue = attributes.delete(:issue)
      @pre_harvest_interval = attributes[:pre_harvest_interval].in(:day) if attributes[:pre_harvest_interval]
      @max_inputs_count = attributes[:max_inputs_count]
      if attributes[:untreated_zone_distance]
        @untreated_zone_margin = Measure.new(attributes[:untreated_zone_distance])
      end
    end

    def self.human_attribute_name(*args)
      ProductNatureVariant.human_attribute_name(*args)
    end

    def subject_name
      @subject[:name]
    end

    def subject_variety
      @subject[:variety]
    end
  end
end
