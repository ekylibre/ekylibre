desc "Generates the nomenclature of nomenclatures"
task :nomenclature => :environment do
  print " - Nomenclature: "
  count = 0
  builder = Nokogiri::XML::Builder.new do |xml|
    xml.nomenclatures xmlns: "http://www.ekylibre.org/XML/2013/nomenclatures" do
      xml.nomenclature name: "nomenclatures", translateable: false do
        xml.send("property-natures") do
          xml.send "property-nature", name: "property_natures", type: "list"
          xml.send "property-nature", name: "translateable", type: "boolean", default: true
        end
        xml.items do
          for name in Nomen.names.sort
            nomenclature = Nomen[name]
            attrs = {name: name}
            attrs[:translateable] = false unless nomenclature.translateable?
            unless nomenclature.property_natures.empty?
              attrs[:property_natures] = nomenclature.property_natures.keys.join(", ")
            end
            xml.item attrs
            count += 1
          end
        end
      end
    end
  end

  File.open(Rails.root.join("config", "nomenclatures", "nomenclatures.xml"), "wb") do |f|
    f.write builder.to_xml
  end
  puts "#{count.to_s.rjust(3)} nomenclatures"
end
