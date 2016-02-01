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

  task list: :environment do
    Nomen.all.each do |n|
      if n.name.to_s.classify.tableize != n.name.to_s
        puts n.name.to_s.red
      else
        puts n.name
      end
    end
  end

  namespace :export do
    desc 'Export nomenclatures as CSV in tmp/nomenclatures'
    task csv: :environment do
      output = Rails.root.join('tmp', 'nomenclatures')
      FileUtils.rm_rf(output)
      FileUtils.mkdir_p(output)
      Nomen.all.each do |n|
        n.to_csv(output.join("#{n.name}.csv"))
      end
    end
  end

  task export: 'export:csv'

  namespace :migrate do
    task generate: :environment do
      unless name = ENV['NAME']
        puts 'Use command with NAME: rake nomen:migrate:generate NAME=add_some_stuff'
        exit 1
      end
      name = name.downcase.gsub(/[\s\-\_]+/, '_')
      full_name = Time.zone.now.l(format: '%Y%m%d%H%M%S') + "_#{name}"
      file = Rails.root.join('db', 'nomenclatures', 'migrate', "#{full_name}.xml")
      found = Dir.glob(Nomen.migrations_path.join('*.xml')).detect do |file|
        File.basename(file).to_s =~ /^\d+\_#{name}\.xml/
      end
      if found
        puts "A migration with same name #{name} already exists: #{Pathname.new(found).relative_path_from(Rails.root)}"
        exit 2
      end
      xml = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
      xml << "<migration name=\"#{name.humanize}\">\n"
      xml << "  <!-- Add your changes here -->\n"
      xml << "</migration>\n"
      File.write(file, xml)
      puts "Create #{file.relative_path_from(Rails.root).to_s.yellow}"
    end

    task model: :environment do
      Nomen.missing_migrations.each do |migration|
        Nomen::Migrator::Model.run(migration)
      end
    end

    task translation: :environment do
      Nomen.missing_migrations.each do |migration|
        Nomen::Migrator::Translation.run(migration)
      end
    end

    task reference: :environment do
      Nomen.missing_migrations.each do |migration|
        Nomen::Migrator::Reference.run(migration)
      end
    end
  end

  desc 'Generate migration file (in db/migrate) for corresponding '
  task migrate: :environment do
    Rails.application.eager_load! if Rails.env.development?
    Nomen.missing_migrations.each do |migration|
      puts migration.name.yellow
      Nomen::Migrator::Reference.run(migration)
      Nomen::Migrator::Model.run(migration)
      Nomen::Migrator::Translation.run(migration)
    end
  end

  task avatar: :environment do
    cache = {}
    avatars_dir = Rails.root.join('app', 'assets', 'images')
    Nomen.each do |nomenclature|
      folder = nomenclature.table_name
      dir = avatars_dir.join(folder)
      next unless dir.exist?
      cache[folder] = {}
      nomenclature.find_each do |i|
        %w(jpg png).each do |format|
          image_path = dir.join(i.name + '.' + format)
          if image_path.exist?
            cache[folder][i.name] = image_path.relative_path_from(avatars_dir).to_s
            break
          end
        end
      end
    end
    File.write(NomenHelper::AVATARS_INDEX, cache.to_yaml)
  end
end
