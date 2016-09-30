namespace :nomen do
  desc 'Flatten data in standalone nomenclature migration'
  task flatten: :environment do
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.migration name: 'Add initial data' do
        Nomen.all.sort_by(&:dependency_index).each do |nomenclature|
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
    desc 'Generate migration file (in db/migrate) for corresponding'
    task generate: :environment do
      puts 'DEPRECATION WARNING: `rake nomen:migrate:generate` is deprecated. Please use `rails g nomenclature_migration` instead.'.yellow
      unless name = ENV['NAME']
        puts 'Use command with NAME: rake nomen:migrate:generate NAME=add_some_stuff'
        exit 1
      end
      name = name.downcase.gsub(/[\s\-\_]+/, '_')
      full_name = Time.zone.now.l(format: '%Y%m%d%H%M%S') + "_#{name}"
      file = Rails.root.join('db', 'nomenclatures', 'migrate', "#{full_name}.xml")
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

  desc 'Migrate Nomen data'
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

  task srs: :environment do
    OGC_CRS_URN = {
      '4326': 'urn:ogc:def:crs:OGC:1.3:CRS84'
    }.with_indifferent_access.freeze

    # migration file generation
    migration_name = ENV['NAME'] = 'update spatial reference systems'
    Rake::Task['nomen:migrate:generate'].invoke

    # filename
    filename = %W(#{Nomen.missing_migrations.last.number} #{Nomen.missing_migrations.last.name.downcase.split(' ').join('_')}).join('_')
    file = Nomen.migrations_path.join("#{filename}.xml")

    # already existing nomenclature ?
    systems = Nomen::SpatialReferenceSystem

    # access to postgis and get reference systems
    table = ActiveRecord::Base.connection.execute('select * from spatial_ref_sys')
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.migration name: migration_name do
        nomenclature_name = 'spatial_reference_systems'

        unless Nomen.find(nomenclature_name).present?
          attrs = { name: nomenclature_name }
          attrs[:translateable] = 'false'
          xml.send('nomenclature-creation', attrs)
        end

        properties = []
        properties << { name: 'authority_reference', type: 'string' }
        properties << { name: 'srid', type: 'integer', required: 'true' }

        # add custom properties
        properties << { name: 'urn', type: 'string' }

        properties.each do |p|
          next if systems.property(p[:name]).present?
          attrs = { property: "#{nomenclature_name}.#{p[:name]}", type: p[:type] }
          attrs[:required] = 'true' if p.key?(:required)
          xml.send('property-creation', attrs)
        end

        table.each do |row|
          auth_ref = %W(#{row['auth_name']} #{row['auth_srid']})
          attrs = { item: "#{nomenclature_name}##{auth_ref.join('_')}" }.with_indifferent_access
          attrs[:authority_reference] = auth_ref.join(':')
          attrs[:srid] = row['srid']

          attrs[:urn] = OGC_CRS_URN[row['srid']] if OGC_CRS_URN.keys.include?(row['srid'])

          # if already exists.
          item = systems.find_by(srid: row['auth_srid'].to_i)
          if systems && item
            # if properties are different
            if item.properties.length != properties.length || !properties.select { |p| attrs[p[:name]] != item.property(p[:name]).to_s }.empty?
              # be sure to keep current item name
              attrs[:item] = "#{nomenclature_name}##{item.name}"
              xml.send('item-change', attrs)
            end
          else
            xml.send('item-creation', attrs)
          end
        end

        # remove unexisting items from nomenclature
        # systems.find_each do |item|
        #   next if table.select{ |r| r['srid'].to_i == item.property(:srid) }.length > 0
        #   attrs = { item: "#{nomenclature_name}##{item.name}" }
        #   xml.send('item-remove', attrs)
        # end
      end
    end

    File.write file, builder.to_xml
  end
end
