namespace :catalog do
  task procedures: :environment do
    I18n.locale = ENV['LOCALE']
    lang = 'i18n.iso2'.t
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.send('procedures-catalog', locale: I18n.locale, lang: lang, 'xml:lang' => lang) do
        xml.send('activity-families') do
          Nomen::ActivityFamily.list.each do |family|
            xml.send('activity-family', name: family.name, title: family.human_name) do
              Procedo::Procedure.of_activity_family(family.name.to_sym).each do |procedure|
                xml.procedure(name: procedure.name)
              end
            end
          end
        end
        xml.procedures do
          Procedo.list.values.each do |procedure|
            xml.procedure('short-name' => procedure.short_name, name: procedure.name, namespace: procedure.namespace, version: procedure.version, title: procedure.human_name, nature: procedure.natures.join(',')) do
              procedure.variables.values.each_with_index do |variable, index|
                xml.variable(name: variable.name, position: index + 1, title: variable.human_name)
              end
            end
          end
        end
      end
    end
    puts builder.to_xml
  end

  task variants: :environment do
    I18n.locale = ENV['LOCALE']
    lang = 'i18n.iso2'.t
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.send('variants-catalog', locale: I18n.locale, lang: lang, 'xml:lang' => lang) do
        Nomen::ProductNatureVariant.list.sort.each do |variant|
          nature = Nomen::ProductNature.find(variant.nature)
          attrs = { name: variant.name, title: variant.human_name }
          attrs[:nature] = nature.name
          attrs['nature-title'] = nature.human_name
          attrs[:variety] = variant.variety || nature.variety
          attrs['variety-title'] = Nomen::Variety.find(attrs[:variety]).human_name
          derivative_of = variant.derivative_of || Nomen::ProductNature.find(variant.nature).derivative_of
          if item = Nomen::Variety.find(derivative_of)
            attrs['derivative-of'] = item.name
            attrs['derivative-of-title'] = item.human_name
          end
          attrs['unit-name'] = variant.unit_name

          xml.send('variant', attrs) do
            variant.frozen_indicators_values.strip.split(/\s*\,\s*/).each do |couple|
              indicator_name, value = couple.split(/\s*\:\s*/)[0..1]
              indicator = Nomen::Indicator.find(indicator_name)
              xml.indicator name: indicator.name, title: indicator.human_name, value: value, type: :frozen
            end unless variant.frozen_indicators_values.blank?
            nature.variable_indicators.each do |indicator_name|
              indicator = Nomen::Indicator.find(indicator_name)
              xml.indicator name: indicator.name, title: indicator.human_name, type: :variable
            end if nature.variable_indicators
          end
        end
      end
    end
    puts builder.to_xml
  end
end
