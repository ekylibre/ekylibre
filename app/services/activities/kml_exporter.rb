# frozen_string_literal: true

module Activities
  class KmlExporter
    # @param [Activity] activity
    # @param [Campaign] campaign
    # @return [String]
    def build_activity_kml(activity, campaign)
      productions = activity.productions.of_campaign(campaign)
      plants = Plant.of_activity_production(productions)
      build_plants_xml(plants) if plants.exists?
    end

    # @param [Campaign] campaign
    # @return [String]
    def build_campaign_zip(campaign)
      Zip::OutputStream.write_buffer do |out|
        Activity.of_campaign(campaign).find_each do |activity|
          filename = "#{activity.name} #{campaign.harvest_year}.kml"
          content = build_activity_kml(activity, campaign)
          next if content.nil?

          out.put_next_entry(filename)
          out.write(content)
        end
      end.string
    end

    private

      # @param [Array<Plant>] plants
      # @return [String]
      def build_plants_xml(plants)
        xmlns = "http://www.opengis.net/kml/2.2"
        xmlns_gx = "http://www.google.com/kml/ext/2.2"
        encoding = "UTF-8"

        Nokogiri::XML::Builder.new(encoding: encoding) do |xml_builder|
          xml_builder.kml xmlns: xmlns, 'xmlns:gx': xmlns_gx do
            xml_builder.Document do
              xml_builder.Folder do
                plants.each do |plant|
                  xml_builder.Placemark do
                    xml_builder.name plant.name
                    xml_builder.description plant.name
                    xml_builder << RGeo::Kml.encode(plant.shape.to_rgeo)
                  end
                end
              end
            end
          end
        end.to_xml
      end
  end
end
