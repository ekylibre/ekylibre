namespace :nomen do
  desc 'Flatten data in standalone nomenclature migration'
  task flatten: :environment do
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.migration name: 'Add initial data' do
        Nomen.all.sort { |a, b| a.dependency_index <=> b.dependency_index }.each do |nomenclature|
          name = nomenclature.name.to_s # .gsub(/(nmp|france|poitou_charentes)_/, '\1/')
          # xml.comment "Dependency index: #{nomenclature.dependency_index}"
          attrs = { name: name }
          attrs[:translateable] = 'false' if nomenclature['translateable'] == 'false'
          attrs[:notions] = nomenclature['notions'].to_s if nomenclature['notions'].present?
          xml.send('nomenclature-creation', attrs)
          properties = nomenclature.property_natures.values
          properties.each do |p|
            attrs = { property: "#{nomenclature.name}.#{p.name}", type: p.type }
            attrs[:required] = 'true' if p.required?
            attrs[:default] = p.default unless p.default.blank?
            attrs[:fallbacks] = p.fallbacks.join(', ') if p.fallbacks
            if p.source
              if p.inline_choices? && p.choices.any?
                attrs[:choices] = p.choices.join(', ')
              elsif p.item_reference?
                attrs[:choices] = p.source
              end
            end
            xml.send('property-creation', attrs)
          end
          nomenclature.items.values.each do |item|
            attrs = { item: "#{name}##{item.name}" }
            attrs[:parent] = item.parent.name if item.parent
            item.properties.each do |pname, pvalue|
              next unless pvalue.present?
              if p = nomenclature.property_natures[pname.to_s]
                if p.type == :decimal
                  pvalue = pvalue.to_s.to_f
                elsif p.list?
                  pvalue = pvalue.join(', ')
                end
              end
              attrs[pname] = pvalue.to_s
            end
            xml.send('item-creation', attrs)
          end
        end
        # xml.tag(version: "1.0")
      end
    end
    File.open(Rails.root.join('db', 'nomenclatures', 'flatten.xml'), 'wb') do |f|
      f.write builder.to_xml
    end
  end

  namespace :migrate do
    task model: :environment do
      Nomen.missing_migrations.each do |migration|
        Nomen::Migrator::Model.run(migration)
      end
    end

    task translation: :environment do
    end

    task reference: :environment do
    end
  end

  desc 'Generate migration file (in db/migrate) for corresponding '
  task migrate: :environment do
    Rails.application.eager_load! if Rails.env.development?
    Nomen.missing_migrations.each do |migration|
      Nomen::Migrator::Reference.run(migration)
      Nomen::Migrator::Model.run(migration)
      Nomen::Migrator::Translation.run(migration)
    end
  end
end
