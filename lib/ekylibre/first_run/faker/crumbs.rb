module Ekylibre
  module FirstRun
    module Faker
      class Crumbs < Base
        def run
          # populate crumbs
          path = files.join('trip_simulation.shp')
          count :trip_simulation do |_w|
            #############################################################################
            read_at = Time.new(2014, 5, 5, 10, 0, 0, '+00:00')
            user = User.where(person_id: Worker.pluck(:person_id).compact).first
            RGeo::Shapefile::Reader.open(path.to_s, srid: 4326) do |file|
              file.each do |record|
                metadata = record.attributes['metadata'].blank? ? {} : record.attributes['metadata'].to_s.strip.split(/[[:space:]]*\;[[:space:]]*/).collect { |i| i.split(/[[:space:]]*\:[[:space:]]*/) }.each_with_object({}) do |i, h|
                  h[i.first.strip.downcase.to_s] = i.second.to_s
                  h
                end
                Crumb.create!(accuracy: 1,
                              geolocation: record.geometry,
                              metadata: metadata,
                              nature: record.attributes['nature'].to_sym,
                              read_at: read_at + record.attributes['id'].to_i * 15,
                              user_id: user.id,
                              device_uid: record.attributes['device_uid'] || 'demo:123854')
                # w.check_point
              end
            end
          end

          ##################################################################
          ##               DEMO SPRAYING                                  ##
          ##################################################################

          # Set parameters
          issue_observed_at = Time.new(2014, 5, 15, 10, 0, 0, '+00:00')
          campaign_year = '2014'
          cultivable_zone_work_number = 'ZC10'
          issue_nature = :chenopodium_album
          worker_work_number = 'CD'
          product_name = 'Callisto'
          intrant_population = 1
          sprayer_work_number = 'PULVE_01'

          # Get products
          campaign = Campaign.where(harvest_year: campaign_year).first
          cultivable_zone = CultivableZone.where(work_number: cultivable_zone_work_number).first

          plant = nil
          members = cultivable_zone.current_cultivations(issue_observed_at) if cultivable_zone
          plant = members if members.any?
          if plant.nil?
            cultivable_zone_shape = Charta.new_geometry(cultivable_zone.shape) if cultivable_zone.shape
            if cultivable_zone_shape && product_around = Plant.shape_within(cultivable_zone_shape).first
              plant = product_around
            end
          end

          support = ActivityProduction.where(cultivable_zone_id: cultivable_zone.id).of_campaign(campaign).first if cultivable_zone && campaign
          intrant = Product.where(name: product_name).first
          sprayer = Equipment.where(work_number: sprayer_work_number).first
          worker = Worker.where(work_number: worker_work_number).first

          # 0 - LINK DOCUMENT ON EQUIPMENT, PRODUCT

          path = self.path('demo_spraying', 'callisto_fds.pdf')
          if path.exist?
            # import prescription in PDF
            document = Document.create!(key: '17181-54371-25023-013645', name: 'fds-callisto-20140601001', nature: 'security_data_sheet', file: File.open(path, 'rb'))
          end
          # TODO: FDS ON CALLISTO
          intrant.variant.attachments.create!(document: document) if intrant

          # phytosanitary_certification
          # certiphyto.jpeg
          path = self.path('demo_spraying', 'certiphyto.jpeg')
          if path.exist?
            # import prescription in PDF
            document = Document.create!(key: 'certiphyto-2014-JOULIN-D', name: '2014-certiphyto-JOULIN-D', nature: 'phytosanitary_certification', file: File.open(path, 'rb'))
          end
          # LINK ON CD
          worker.attachments.create!(document: document) if document

          # equipment_certification
          # controle_pulverisateur.pdf
          path = self.path('demo_spraying', 'controle_pulverisateur.pdf')
          if path.exist?
            # import prescription in PDF
            document = Document.create!(key: '2014-pulve-control', name: '2014-pulve-control', nature: 'equipment_certification', file: File.open(path, 'rb'))
          end
          # LINK ON SPRAYING EQUIPMENT
          sprayer.attachments.create!(document: document) if document

          # 1 - CREATE AN ISSUE ON A PLANT WITH GEOLOCATION
          if plant
            issue = Issue.create!(target_type: plant.class.name,
                                  target_id: plant.id,
                                  priority: 3,
                                  observed_at: issue_observed_at,
                                  nature: issue_nature,
                                  state: 'opened')
            # link picture if exist
            picture_path = self.path('demo_spraying', 'chenopodium_album.jpg')
            f = (picture_path.exist? ? File.open(picture_path) : nil)
            if f
              issue.update!(picture: f)
              f.close
            end
            path = self.path('demo_spraying', 'issue_localization.shp')
            if path.exist?
              RGeo::Shapefile::Reader.open(path.to_s, srid: 4326) do |file|
                file.each do |record|
                  issue.update!(geolocation: record.geometry)
                end
              end
            end
          end

          # 2 - CREATE A PRESCRIPTION
          path = self.path('demo_spraying', 'preco_phyto.pdf')
          if path.exist?
            # import prescription in PDF
            document = Document.create!(key: '20140601001_prescription_001', name: 'prescription-20140601001', nature: 'prescription', file: File.open(path, 'rb'))
            # get the prescriptor
            prescriptor = Entity.where(last_name: 'JOUTANT').first
            # create the prescription with PDF and prescriptor
            prescription = Prescription.create!(prescriptor: prescriptor, reference_number: '20140601001') if prescriptor
            prescription.attachments.create!(document: document) if prescription && document
          end

          # 3 - CREATE A PROVISIONNAL SPRAYING INTERVENTION

          intervention = nil

          procedure = Procedo.find(:spraying)
          started_at = '2014-06-01 09:00'
          stopped_at = '2014-06-01 09:45'

          # build base procedure
          attributes = {
            procedure_name: procedure.name,
            actions: procedure.mandatory_actions.map(&:name)
          }

          ## working_periods
          attributes[:working_periods_attributes] = {
            '0' => {
              started_at: started_at.to_time.strftime('%Y-%m-%d %H:%M'),
              stopped_at: stopped_at.to_time.strftime('%Y-%m-%d %H:%M')
            }
          }

          ## targets
          attributes[:targets_attributes] ||= {}
          attributes[:targets_attributes][0] = {
            reference_name: 'cultivation',
            product_id: plant.id,
            working_zone: plant.shape.to_geojson
          }

          ## inputs
          updaters = []

          attributes[:inputs_attributes] ||= {}
          attributes[:inputs_attributes][0] = {
            reference_name: 'plant_medicine',
            product_id: intrant.id,
            quantity_handler: 'population',
            quantity_value: intrant_population
          }

          updaters << 'inputs[0]quantity_value'

          ## tools
          eqs = []
          eqs << sprayer
          eqs.each_with_index do |equipment, index|
            procedure.parameters_of_type(:tool).each do |tool|
              next unless equipment.of_expression(tool.filter)
              attributes[:tools_attributes] ||= {}
              attributes[:tools_attributes][index.to_s] = {
                reference_name: tool.name,
                product_id: equipment.id
              }
              break
            end
          end

          ## doers
          doers = []
          doers << worker
          doers.each_with_index do |work, index|
            procedure.parameters_of_type(:doer).each do |doer|
              next unless work.of_expression(doer.filter)
              attributes[:doers_attributes] ||= {}
              attributes[:doers_attributes][index.to_s] = {
                reference_name: doer.name,
                product_id: work.id
              }
              break
            end
          end

          intervention = Procedo::Engine.new_intervention(attributes)
          updaters.each do |updater|
            intervention.impact_with!(updater)
          end

          ## save
          intervention = ::Intervention.create!(intervention.to_hash)

          if intervention
            intervention.issue = issue if issue
            intervention.prescription = prescription if prescription
            intervention.save!
          end

          # 4 - COLLECT REAL INTERVENTION TRIP
          # populate crumbs for ticsad simulation
          # shape file with attributes for spraying
          ## Technical attributes
          # wind_speed numeric (m/s)
          # wind_direc string [N,W,E,S,NE,NW,SE,SW]
          # tank_level numeric (liter)
          # moisture_p numeric (percentage)
          # left_flow (liter/ha)
          # right_flow (liter/ha)
          ##
          path = self.path('demo_spraying', 'ticsad_simulation.shp')
          if path.exist? && intervention && sprayer = intervention.product_parameters.find_by(reference_name: 'sprayer')
            # puts "ticsad import OK".inspect.green
            count :ticsad_simulation do |_w|
              #############################################################################
              read_at = Time.new(2014, 6, 5, 10, 0, 0, '+00:00')
              user = if worker
                       User.where(person_id: worker.person_id).first
                     else
                       User.where(person_id: Worker.pluck(:person_id).compact).first
                     end
              RGeo::Shapefile::Reader.open(path.to_s, srid: 4326) do |file|
                file.each do |record|
                  metadata = record.attributes['metadata'].blank? ? {} : record.attributes['metadata'].to_s.strip.split(/[[:space:]]*\;[[:space:]]*/).collect { |i| i.split(/[[:space:]]*\:[[:space:]]*/) }.each_with_object({}) do |i, h|
                    h[i.first.strip.downcase.to_s] = i.second.to_s
                    h
                  end
                  # add technical attributes into metadata with correct unity measurement
                  metadata.store('wind_speed', record.attributes['wind_speed'].to_s + 'meter_per_second') if record.attributes['wind_speed']
                  metadata.store('wind_direction', record.attributes['wind_direc']) if record.attributes['wind_direc']
                  metadata.store('tank_level', record.attributes['tank_level'].to_s + 'liter') if record.attributes['tank_level']
                  metadata.store('moisture_level', record.attributes['moisture_p'].to_s + 'percentage') if record.attributes['moisture_p']
                  metadata.store('left_flow', record.attributes['left_flow'].to_s + 'liter_per_hectare') if record.attributes['left_flow']
                  metadata.store('right_flow', record.attributes['right_flow'].to_s + 'liter_per_hectare') if record.attributes['right_flow']

                  Crumb.create!(accuracy: 1,
                                geolocation: record.geometry,
                                metadata: metadata,
                                nature: record.attributes['nature'].to_sym,
                                read_at: read_at + record.attributes['id'].to_i,
                                user_id: user.id,
                                device_uid: record.attributes['device_uid'] || 'demo:123854',
                                intervention_parameter: sprayer)
                  # w.check_point
                end
              end
            end
          else
            puts 'Cannot import ticsad simulation'.red
          end
        end
      end
    end
  end
end
