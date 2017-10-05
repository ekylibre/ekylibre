module Pesticide
  class Usage
    attr_reader :name, :dose, :pre_harvest_interval, :max_inputs_count, :untreated_zone_margin, :mode, :issue

    def initialize(attributes = {})
      @name = attributes.delete(:name)
      @dose = attributes[:dose] && attributes[:dose] =~ /\A-?([\,\.]\d+|\d+([\,\.]\d+)?)\s*[^\s]+\z/ ? Measure.new(attributes.delete(:dose)) : attributes.delete(:dose)
      @subject = attributes.delete(:subject) || {}
      @mode = attributes.delete(:mode)
      @issue = attributes.delete(:issue)
      @pre_harvest_interval = attributes[:pre_harvest_interval].in(:day) if attributes[:pre_harvest_interval]
      @max_inputs_count = attributes[:max_inputs_count]
      if untreated_zone = attributes[:untreated_zone_distance]
        @untreated_zone_margin = untreated_zone =~ /\A-?([\,\.]\d+|\d+([\,\.]\d+)?)\z/ ? Measure.new(untreated_zone.to_f, :meter) : Measure.new(untreated_zone)
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
