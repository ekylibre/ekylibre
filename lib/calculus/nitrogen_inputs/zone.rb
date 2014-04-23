# -*- coding: utf-8 -*-
module Calculus
  module NitrogenInputs

    # A Zone which will receive nitrogen
    class Zone
      attr_reader :support, :membership
      delegate :activity, :campaign, :markers, to: :support
      delegate :net_surface_area, to: :membership

      def initialize(support, membership)
        @support = support
        @membership = membership
      end

      def self.of_campaign(*campaigns)
        zones = []
        for campaign in campaigns
          for support in campaign.production_supports.includes(:storage).order(:production_id, "products.name")
            # support.active return all activities except fallow_land
            if support.storage.is_a?(CultivableZone) and support.active?
              for membership in support.storage.memberships
                zones << new(support, membership)
              end
            end
          end
        end
        return zones
      end

      # Computes markers with given options
      def self.calculate!(*campaigns)
        options = campaigns.extract_options!
        for zone in of_campaign(*campaigns)
          if params = options[zone.id]
            inputs_method = "Calculus::NitrogenInputs::Methods::#{params.delete(:inputs_method).to_s.camelcase}".constantize.new(zone, params)
            inputs_method.apply!
          end
        end
      end


      def id
        "#{@support.id}-#{@membership.id}"
      end


      # Returns the land parcel
      def land_parcel
        @membership.member
      end

      def cultivation
        # TODO How to know the cultivation and in many cultivations case, how to do ?
        return nil
      end

      # Returns the variety of the cultivation
      def cultivation_variety
        @cultivation_variety ||= Nomen::Varieties[@support.production.variant.variety]
      end

      # Returns all matching varieties
      def cultivation_varieties
        if cultivation_variety
          return cultivation_variety.self_and_parents.map(&:name).map(&:to_sym)
        end
        return :undefined
      end

      # Returns the variety of the cultivation
      def soil_nature
        @soil_nature ||= Nomen::SoilNatures[land_parcel.soil_nature]
      end

      # Returns all matching varieties
      def soil_natures
        if soil_nature
          return soil_nature.self_and_parents.map(&:name).map(&:to_sym)
        end
        return :undefined
      end

      # Returns the inputs_method for the zone
      def inputs_method(options = {})
        method = nil
        return method || :poitou_charentes
      end

      # Returns the crop yield for the zone
      def crop_yield(options = {})
        options = {unit: :quintal_per_hectare}.merge(options)
        crop_yield = nil
        if marker = aim(:mass_area_yield)
          crop_yield = marker.value
        end
        return crop_yield || 0.in_quintal_per_hectare.in(options[:unit])
      end

      def nitrogen_input_area_density
        marker = aim(:nitrogen_area_density, subject: :support)
        return (marker ? marker.value : 0.in_kilogram_per_hectare)
      end

      def mark(name, value, options = {})
        options[:derivative] = :grain unless options.has_key?(:derivative)
        options[:aim] ||= :perfect
        options[:subject] ||= (options[:derivative] ? :derivative : :support)
        unless marker = aim(name, options)
          marker ||= @support.markers.build(indicator_name: name,
                                            derivative: options[:derivative],
                                            subject: options[:subject],
                                            aim: options[:aim])
        end
        marker.value = value
        marker.save!
        return marker
      end

      def aim(name, options = {})
        options[:derivative] = :grain unless options.has_key?(:derivative)
        options[:aim] ||= :perfect
        options[:subject] ||= (options[:derivative] ? :derivative : :support)
        @support.markers.order(:id).find_by(indicator_name: name,
                                            derivative: options[:derivative],
                                            subject: options[:subject],
                                            aim: options[:aim])
      end

      def available_water_capacity
        @available_water_capacity ||= land_parcel.available_water_capacity_per_area
      end

      # TODO Find a reliable way to determinate the administrative area of a land parcel
      def administrative_area
        return "FR-17"
      end

    end


  end
end
