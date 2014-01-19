# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple ERP
# Copyright (C) 2014 Brice Texier, David Joulin
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

class Backend::Calculators::NitrogenInputsController < BackendController

  class InputsMethod
    attr_reader :crop_yield, :zone

    def initialize(zone, options = {})
      @zone = zone
      @options = options
      @crop_yield = options[:crop_yield][:value].to_d.in(options[:crop_yield][:unit]) rescue nil
      @crop_yield = @zone.crop_yield if @crop_yield.nil? or @crop_yield.zero?
      @crop_yield ||= 40.in_quintal_per_hectare
    end

    def apply!
      raise NotImplementedError
    end

  end


  class PoitouCharentes < InputsMethod

    def apply!
      # Pf
      b = 3
      if items = Nomen::NmpPoitouCharentesAbacusThree.best_match(:cultivation_variety, zone.cultivation_variety) and items.any?
        b = items.first.coefficient
      end
      nitrogen_need = crop_yield * b

      # Pi
      absorbed_nitrogen_at_beginning = 10.in_kilogram_per_hectare
      if zone.cultivation and count = zone.cultivation.leaf_count(at: Date.civil(zone.campaign.harvest_year, 2, 1)) and zone.activity.nature.to_s == :straw_cereal_crops

        if items = Nomen::NmpPoitouCharentesAbacusFour.list.select do |item|
            (item.minimum_leaf_count || 0) <= count and count <= (item.minimum_leaf_count || count)
          end.first
          absorbed_nitrogen_at_beginning = items.first.absorbed_nitrogen.in_kilogram_per_hectare
        end
      end

      # Ri
      mineral_nitrogen_at_beginning = 20.in_kilogram_per_hectare

      # Mh
      humus_mineralization = 30.in_kilogram_per_hectare
      if false
        # TODO
      end

      # Mhp
      prairie_humus_mineralization = 0.in_kilogram_per_hectare
      if false
      end

      # Mr
      residue_mineralization = 0.in_kilogram_per_hectare

      # Mrci
      intermediate_cultivation_residue_mineralization = 0.in_kilogram_per_hectare

      # Nirr
      irrigation_water_nitrogen = 0.in_kilogram_per_hectare

      # Xa
      organic_fertilizer_mineral_fraction = 0.in_kilogram_per_hectare

      # Rf
      post_harvest_rest = 0.in_kilogram_per_hectare

      # Po
      soil_nitrogen_production = 0.in_kilogram_per_hectare

      # X
      if zone.soil_varieties.include?(:clay_limestone_soil) or zone.soil_varieties.include?(:red_chesnut_soil)
        # CAU = 0.8
        # X = [(Pf - Po - Mr - MrCi - Nirr) / CAU] – Xa
        fertilizer_apparent_use_coeffient = 0.8
        real_nitrogen_need = (((nitrogen_need
                                - soil_nitrogen_production
                                - residue_mineralization
                                - intermediate_cultivation_residue_mineralization
                                - irrigation_water_nitrogen) / fertilizer_apparent_use_coeffient)
                              - organic_fertilizer_mineral_fraction)
      else
        # X = Pf - Pi - Ri - Mh - Mhp - Mr - MrCi - Nirr - Xa + Rf
        real_nitrogen_need = (nitrogen_need
                              - absorbed_nitrogen_at_beginning
                              - mineral_nitrogen_at_beginning
                              - humus_mineralization
                              - prairie_humus_mineralization
                              - residue_mineralization
                              - intermediate_cultivation_residue_mineralization
                              - irrigation_water_nitrogen
                              - organic_fertilizer_mineral_fraction
                              + post_harvest_rest)
      end

      if zone.soil_varieties.include?(:clay_limestone_soil)
        real_nitrogen_need *= 1.15
      else
        real_nitrogen_need *= 1.10
      end

      puts "---" * 80
      puts real_nitrogen_need.inspect
    end

  end


  class NitrogenousZone
    attr_reader :support, :membership
    delegate :activity, :campaign, to: :support
    delegate :net_surface_area, to: :membership

    def initialize(support, membership)
      @support = support
      @membership = membership
    end

    def self.of_campaign(*campaigns)
      zones = []
      for campaign in campaigns
        for support in campaign.production_supports.includes(:storage)
          if support.storage.is_a?(CultivableZone)
            for membership in support.storage.memberships
              zones << new(support, membership)
            end
          end
        end
      end
      return zones
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
        return cultivation_variety.self_and_parents.map(&:name)
      end
      return :undefined
    end

    # Returns the variety of the cultivation
    def soil_variety
      @soil_variety ||= Nomen::Varieties[land_parcel.variety]
    end

    # Returns all matching varieties
    def soil_varieties
      if soil_variety
        return soil_variety.self_and_parents.map(&:name)
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
      if items = Nomen::NmpPoitouCharentesAbacusOne.where(cultivation_variety: cultivation_varieties, administrative_area: self.administrative_area || :undefined) and items.any?
        crop_yield = items.first.crop_yield.in_quintal_per_hectare
      elsif capacity = self.available_water_capacity and items = Nomen::NmpPoitouCharentesAbacusTwo.where(cultivation_variety: cultivation_varieties, soil_variety: soil_varieties) and items = items.select{|i| i.minimum_available_water_capacity.in_liter_per_square_meter <= capacity and capacity < i.maximum_available_water_capacity.in_liter_per_square_meter} and items.any?
        crop_yield = items.first.crop_yield.in_quintal_per_hectare
      end
      return crop_yield || 0.in_quintal_per_hectare.in(options[:unit])
    end

    def nitrogen_inputs
      nitrogen_inputs = nil
      return nitrogen_inputs || 0.in_unity_per_hectare
    end

    def available_water_capacity
      @available_water_capacity ||= land_parcel.available_water_capacity_per_area
    end

    # TODO Find a reliable way to determinate the administrative area of a land parcel
    def administrative_area
      return "FR-16"
    end

    def self.calculate!(*campaigns)
      options = campaigns.extract_options!
      for zone in of_campaign(*campaigns)
        if params = options[zone.id]
          inputs_method = "Backend::Calculators::NitrogenInputsController::#{params.delete(:inputs_method).to_s.camelcase}".constantize.new(zone, params)
          inputs_method.apply!
        end
      end
    end

  end


  def show
    redirect_to :action => :edit
  end

  def edit
    @campaign = Campaign.last
    @nitrogenous_zones = NitrogenousZone.of_campaign(@campaign)
  end

  def update
    @campaign = Campaign.find(params[:campaign_id])
    NitrogenousZone.calculate!(@campaign, params[:nitrogenous_zones])
    notify_now(:new_values_are_computed)
    @nitrogenous_zones = NitrogenousZone.of_campaign(@campaign)
  end

end
