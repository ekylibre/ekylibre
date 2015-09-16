module ActiveSensor
  class Equipment < ActiveSensor::Base
    attr_accessor :vendor
    attr_accessor :model
    attr_accessor :label
    attr_accessor :description
    attr_accessor :indicators
    attr_accessor :image_path
    attr_accessor :controller

    def initialize(options = {})
      assign_attributes(options)
    end

    def assign_attributes(values)
      values.each do |k, v|
        send("#{k}=", v)
      end
    end

    def get(access_parameters = {})
      ActiveSensor::Connection.new(self, access_parameters)
    end

    def label
      if @label.is_a? Hash
        @label[I18n.locale]
      else
        @label
      end
    end

    class << self
      def vendors
        list.collect(&:vendor).uniq
      end

      def equipments_of(vendor)
        list.select do |equipment|
          equipment.vendor == vendor.to_sym
        end
      end

      def erase(vendor, model)
        equipment = find(vendor, model)
        list.delete(equipment)
      end

      def find(vendor, model)
        list.detect do |equipment|
          equipment.vendor == vendor.to_sym && equipment.model == model.to_sym
        end
      end

      def get(vendor, model, access_parameters = {})
        equipment = find(vendor, model)

        if equipment
          ActiveSensor::Connection.new(equipment, access_parameters)
        else
          fail 'No matching equipment'
        end
      end
    end
  end
end
