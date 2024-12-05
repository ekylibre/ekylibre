# frozen_string_literal: true

module Activities
  class XmlExport
    def initialize(plants)
      @plants = plants
    end

    def build_xml
      xmlns = "http://www.opengis.net/kml/2.2"
      xmlns_gx = "http://www.google.com/kml/ext/2.2"
      encoding = "UTF-8"

      Nokogiri::XML::Builder.new(encoding: encoding) { |xml_builder|
        xml_builder.kml xmlns: xmlns, 'xmlns:gx': xmlns_gx do
          xml_builder.Document do
            xml_builder.Folder do
              @plants.each do |plant|
                xml_builder.Placemark do
                  xml_builder.name plant.name
                  xml_builder.description plant.name
                  xml_builder << RGeo::Kml.encode(plant.shape.to_rgeo)
                end
              end
            end
          end
        end
      }.to_xml
    end
  end
end
