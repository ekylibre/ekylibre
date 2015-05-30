namespace :procedo do

  task :index => :environment do
    I18n.locale = ENV["LOCALE"]
    lang = "i18n.iso2".t
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.procedures(locale: I18n.locale, lang: lang, "xml:lang" => lang) do
        Procedo.list.values.each do |procedure|
          xml.procedure("short-name" => procedure.short_name, name: procedure.name, namespace: procedure.namespace, version: procedure.version, title: procedure.human_name) do
            procedure.variables.values.each_with_index do |variable, index|
              xml.variable(name: variable.name, position: index + 1, title: variable.human_name)
            end
          end
        end
      end
    end
    puts builder.to_xml
  end

  task :activity_index => :environment do
    I18n.locale = ENV["LOCALE"]
    lang = "i18n.iso2".t
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.send("activity-families", locale: I18n.locale, lang: lang, "xml:lang" => lang) do
        Nomen::ActivityFamilies.list.each do |family|
          xml.send("activity-family", name: family.name, title: family.human_name) do
            Procedo.procedures_of_activity_family(family.name.to_sym).each do |procedure|
              xml.procedure("short-name" => procedure.short_name, name: procedure.name, namespace: procedure.namespace, version: procedure.version, title: procedure.human_name) do
                procedure.variables.values.each_with_index do |variable, index|
                  xml.variable(name: variable.name, position: index + 1, title: variable.human_name)
                end
              end
            end
          end
        end
      end
    end
    puts builder.to_xml
  end

end
