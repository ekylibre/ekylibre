class Telepac::V2015::CapStatementsExchanger < ActiveExchanger::Base
  def check
    now = Time.zone.now
    valid = true

    # check if file is a valid XML
    f = File.open(file)
    #f = sanitize(f)
    doc = Nokogiri::XML(f, &:noblanks)

    campaign_name = doc.at_css('producteur').attribute('campagne').value
    unless campaign_name.downcase == "courante"
      w.error "Invalid campaign name"
      valid = false
    end
    valid
  end

  def import
    # import and parse file
    # test file = '/home/djoulin/projects/ekylibre/db/first_runs/demo/telepac/Dossier-PAC-2015_dossier_017005218_20150630095852.xml'
    doc = Nokogiri::XML(File.open(file)) do |config|
      config.strict.nonet.noblanks
    end

    w.count = doc.css("parcelle").count

    puts doc.css("parcelle").count.inspect.red

    #
    country_preference = Preference[:country]
    declaration_year = 2015

    # get pacage number and campaign
    pacage_number = doc.at_css('producteur').attribute('numero-pacage').value

    # get information about campaing
    # TODO remove bullshit when TelePAC will decided to change campagne="Courante" in the XML file
    campaign_name = doc.at_css('producteur').attribute('campagne').value
    if campaign_name.downcase == "courante"
      campaign = Campaign.find_or_create_by!(harvest_year: declaration_year)
    end

    # get the exploitation siret
    # TODO migrate SIREN TO SIRET in Entity
    siret_number = doc.at_css('demandeur siret').text

    # get the exploitation name
    exploitation_name = doc.at_css('identification-societe exploitation').text

    # get the associates and make a link to entities
    # TODO

    # get the exploitation iban
    doc.at_css('demandeur iban').attribute('compte-iban').value
    doc.at_css('demandeur iban').attribute('bic').value
    doc.at_css('demandeur iban').attribute('titulaire').value

    ## find or create Entity
    unless entity = Entity.where('full_name ILIKE ?', exploitation_name).first
      entity = Entity.create!(full_name: exploitation_name, active: true, nature: :organization, country: country_preference)
    end

    cap_statement_attributes = {
        campaign: campaign,
        entity: entity,
        exploitation_name: exploitation_name,
        pacage_number: pacage_number,
        siret_number: siret_number
        }

    ## find or create cap statement
    unless cap_statement = CapStatement.find_by(cap_statement_attributes.slice(:pacage_number, :siret_number, :entity, :campaign))
      cap_statement = CapStatement.create!(cap_statement_attributes)
      puts cap_statement.inspect.red
    end

    # get the islets
    doc.css('ilot').each do |islet|
      # get islet attributes
      # islet number and town_number
      islet_number = islet.attribute('numero-ilot').value
      town_number = islet.css('commune').text

      # islet shape, validate GML and transform into Charta
      geometry = islet.xpath('.//gml:Polygon')
      geometry.first['srsName'] = 'EPSG:2154'
      geom = ::Charta::Geometry.new(geometry.first.to_xml.to_s.squish, nil, 'gml').transform(:WGS84).to_rgeo

      islet_attributes = {
          cap_statement: cap_statement,
          islet_number: islet_number,
          town_number: town_number,
          shape: geom
        }

      # find or create islet according to cap statement
      if cap_statement
        unless cap_islet = CapIslet.find_by(islet_attributes.slice(:islet_number, :cap_statement))
          cap_islet = CapIslet.create!(islet_attributes)
        end
      end


      # get cap_land_parcels
      islet.css('parcelle').each do |land_parcel|
        # get land_parcel attributes
        land_parcel_number = land_parcel.css('descriptif-parcelle').attribute('numero-parcelle').value
        main_crop_seed_production = land_parcel.css('culture-principale').attribute('production-semences').value
        main_crop_commercialisation = land_parcel.css('culture-principale').attribute('commercialisation').value
        main_crop_code = land_parcel.css('code-culture').text
        main_crop_precision = land_parcel.css('precision').text

        # land_parcel shape, validate GML and transform into Charta
        geometry = land_parcel.xpath('.//gml:Polygon')
        geometry.first['srsName'] = 'EPSG:2154'
        geom = ::Charta::Geometry.new(geometry.first.to_xml.to_s.squish, nil, 'gml').transform(:WGS84).to_rgeo

        cap_land_parcel_attributes = {
          cap_islet: cap_islet,
          land_parcel_number: land_parcel_number,
          main_crop_code: main_crop_code,
          main_crop_commercialisation: main_crop_commercialisation,
          main_crop_precision: main_crop_precision,
          main_crop_seed_production: main_crop_seed_production,
          shape: geom
        }

        # find or create land_parcel according to cap statement and islet
        if cap_islet
          unless cap_land_parcel = CapLandParcel.find_by(cap_land_parcel_attributes.slice(:land_parcel_number, :cap_islet))
            cap_land_parcel = CapLandParcel.create!(cap_land_parcel_attributes)
          end
        end
        w.check_point
      end
    end
  end

  def sanitize(xml)
    # TODO: validate telepac xml using xsd,xslt (if any)
    xml.to_s.squish
  end

end
