# coding: utf-8
class CharentesAlliance::OutgoingDeliveriesExchanger < ActiveExchanger::Base
  def import
    # Unzip files
    dir = w.tmp_dir
    Zip::File.open(file) do |zile|
      zile.each do |entry|
        entry.extract(dir.join(entry.name))
      end
    end

    outgoing_deliveries_file = dir.join('apports.csv')
    silo_transcode_file = dir.join('silo_transcode.csv')

    here = Pathname.new(__FILE__).dirname

    variants_transcode = {}.with_indifferent_access
    CSV.foreach(here.join('variants.csv'), headers: true) do |row|
      variants_transcode[row[0]] = row[1].to_sym
    end

    silos_transcode = {}.with_indifferent_access
    CSV.foreach(silo_transcode_file, headers: true) do |row|
      silos_transcode[row[0]] = row[1].to_s
    end

    cooperative = Entity.find_by_last_name('CHARENTES ALLIANCE') || Entity.find_by_last_name('Charentes Alliance')

    rows = CSV.read(outgoing_deliveries_file, encoding: 'UTF-8', col_sep: ';', headers: true)
    w.count = rows.size

    rows.each do |row|
      r = OpenStruct.new(delivery_number: row[0],
                         delivery_on: Date.parse(row[1].to_s),
                         building_division_work_number: (silos_transcode[row[2].to_s]),
                         product_variant: (variants_transcode[row[3].to_s]),
                         net_weight: row[4].tr(',', '.').to_d,
                         normalized_weight: row[5].tr(',', '.').to_d,
                         moisture: row[6].tr(',', '.').to_d,
                         impurity_rate: row[7].tr(',', '.').to_d,
                         specific_weight: (row[8].blank? ? nil : row[8].tr(',', '.').to_d),
                         protein_rate: (row[9].blank? ? nil : row[9].tr(',', '.').to_d),
                         calibration: (row[10].blank? ? nil : row[10].tr(',', '.').to_d),
                         wild_oat_rate: (row[11].blank? ? nil : row[11].tr(',', '.').to_d),
                         grade: (row[12].blank? ? nil : row[12].tr(',', '.').to_d),
                         expansion_rate: (row[13].blank? ? nil : row[13].tr(',', '.').to_d),
                         # end of coop data
                         cultivable_zone_work_number: (row[14].blank? ? nil : row[14].to_s)
                        )

      # puts r.inspect.red

      # find a product_nature_variant by mapping current name of matter in coop file in coop reference_name
      unless product_nature_variant = ProductNatureVariant.find_by_reference_name(r.product_variant)
        if Nomen::ProductNatureVariant.find(r.product_variant)
          product_nature_variant ||= ProductNatureVariant.import_from_nomenclature(r.product_variant)
        end
      end

      # create variables
      campaign = Campaign.find_by_harvest_year(r.delivery_on.year)
      silo = Equipment.find_by_work_number(r.building_division_work_number)
      cultivable_zone = CultivableZone.find_by_work_number(r.cultivable_zone_work_number) if r.cultivable_zone_work_number
      ps = ProductionSupport.where(storage: cultivable_zone).of_campaign(campaign) if cultivable_zone

      # verify variables
      # puts campaign.name.inspect.yellow if campaign
      # puts cultivable_zone.name.inspect.yellow if cultivable_zone
      # puts silo.name.yellow if silo

      # create a grain_analysis if not exist

      # TODO: waiting for workflow engine v2
      # create a grain_harvest intervention if not exist

      # create a transport intervention if not exist

      # create an outgoing delivery if not exist

      w.check_point
    end
  end
end
