# frozen_string_literal: true

module Ekylibre
  # Rides exchanger permit to import rides in Shapefile
  # in WGS84 spatial reference system.
  class RidesExchanger < ActiveExchanger::Base
    category :plant_farming
    vendor :ekylibre

    DEFAULT_TOOL_WIDTH = 3.0

    def import
      # Unzip file
      dir = w.tmp_dir
      Zip::File.open(file) do |zile|
        zile.each do |entry|
          entry.extract(dir.join(entry.name))
        end
      end

      # Parse file and create rides and ride_sets
      RGeo::Shapefile::Reader.open(dir.join('rides.shp').to_s, srid: 4326) do |file|
        # Set number of shapes
        w.count = file.size

        file.each do |record|
          # id - integer- (1)
          # group - integer - (1)
          # nature - string - (work / road)
          # start - date - (AAAA-MM-DD)
          # hour_start - string - (HH:MM)
          # duration - integer - (s)
          # geometry - Multiline
          if record.geometry
            # because Multiline has to be converted in Line
            w.info "Original geometry : #{record.geometry.inspect}"
            extracted_line_geom = Charta.new_geometry(record.geometry).to_rgeo.first
            clean_shape = Charta.new_geometry(extracted_line_geom)
            w.info "Clean geometry : #{clean_shape.inspect}"

            h_start = record.attributes['hour_start'].split(':')
            start = record.attributes['start'].to_time + h_start[0].to_i.hours + h_start[1].to_i.minutes
            stop = start + record.attributes['duration']

            attributes = {
              nature: record.attributes['nature'],
              number: record.attributes['id'].to_s,
              group: record.attributes['group'].to_s,
              tractor_work_number: record.attributes['tractor'].to_s,
              tool_work_number: record.attributes['tool'].to_s,
              started_at: start,
              stopped_at: stop,
              duration: record.attributes['duration'],
              shape: clean_shape
            }

            ride_set = find_or_create_ride_set(attributes)

            create_ride_equipment(ride_set, attributes)

            create_ride(ride_set, attributes)
          end
          w.check_point
        end
      end

      # update ride_set shape with rides shapes
      update_shape_on_ride_set
      true
    end

    def cultivable_zone(shape)
      return unless shape

      CultivableZone.shape_matching(shape).first
    end

    def find_or_create_ride_set(attributes)
      ride_set = RideSet.of_provider_name(self.class.vendor, provider_name)
                        .of_provider_data(:id, attributes[:group]).first
      ride_set ||= RideSet.create!(
        started_at: attributes[:started_at],
        stopped_at: attributes[:stopped_at],
        nature: attributes[:nature],
        duration: attributes[:duration].seconds,
        provider: provider_value(id: attributes[:group])
      )
      if ride_set.present?
        w.info "RideSet : #{ride_set.inspect}".green
      else
        w.error "No RideSet present or created".red
      end
      ride_set
    end

    def create_ride(ride_set, attributes)
      ride = Ride.of_provider_name(self.class.vendor, provider_name)
                        .of_provider_data(:id, attributes[:number]).first
      cz = cultivable_zone(attributes[:shape])
      ride ||= Ride.create!(
        started_at: attributes[:started_at],
        stopped_at: attributes[:stopped_at],
        nature: attributes[:nature],
        duration: attributes[:duration].seconds,
        shape: attributes[:shape],
        product_id: Equipment.find_by(work_number: attributes[:tractor_work_number])&.id,
        ride_set_id: ride_set.id,
        cultivable_zone: (cz.present? ? cz : nil),
        provider: provider_value(id: attributes[:number], machine_equipment_tool_width: 2.0)
      )
      if ride.present?
        w.info "Ride : #{ride.inspect}".green
      else
        w.error "No Ride present or created".red
      end
    end

    def create_ride_equipment(ride_set, attributes)
      tractor = Equipment.find_by(work_number: attributes[:tractor_work_number])
      if tractor
        ride_set_equipment = RideSetEquipment.of_provider_name(self.class.vendor, provider_name).where(product_id: tractor.id, ride_set_id: ride_set.id).first
        ride_set_equipment ||= RideSetEquipment.create!(
          ride_set_id: ride_set.id,
          product_id: tractor.id,
          nature: 'main',
          provider: provider_value(id: attributes[:tractor_work_number])
        )
      end
      tool = Equipment.find_by(work_number: attributes[:tool_work_number])
      if tool
        ride_set_equipment_tool = RideSetEquipment.of_provider_name(self.class.vendor, provider_name).where(product_id: tool.id, ride_set_id: ride_set.id).first
        ride_set_equipment_tool ||= RideSetEquipment.create!(
          ride_set_id: ride_set.id,
          product_id: tool.id,
          nature: 'additional',
          provider: provider_value(id: attributes[:tool_work_number])
        )
      end
    end

    def update_shape_on_ride_set
      RideSet.of_provider_name(self.class.vendor, provider_name).each do |ride_set|
        points = []
        w.info "RideSet to update : #{ride_set.inspect}".green
        ride_set.rides.order(:started_at).each do |ride|
          w.info "Ride shape to extract : #{ride.shape.inspect}".yellow
          w.info "Ride points : #{ride.shape.points.inspect}".yellow
          points << ride.shape.points
        end
        w.info "Points : #{points.inspect}".yellow
        ride_set_compiled_shape = Charta.make_line(points.flatten!).to_rgeo.buffer(tool_width(ride_set))
        w.info "New line : #{ride_set_compiled_shape.inspect}".yellow
        ride_set.update!(shape: ride_set_compiled_shape)
      end
    end

    protected

      def tool_width(ride_set)
        ride_set.products.map{ |product| product.get(:application_width).to_f }.compact.max || DEFAULT_TOOL_WIDTH
      end

      # @return [Import]
      def import_resource
        @import_resource ||= Import.find(options[:import_id])
      end

      def provider_value(**data)
        { vendor: self.class.vendor, name: provider_name, id: import_resource.id, data: data }
      end

      def provider_name
        :rides
      end

  end
end
