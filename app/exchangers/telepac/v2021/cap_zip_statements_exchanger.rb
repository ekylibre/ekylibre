# frozen_string_literal: true

module Telepac
  module V2021
    class CapZipStatementsExchanger < ActiveExchanger::Base
      include ExchangerMixin

      campaign 2021

      def check
        true
      end

      def import
        # unzip of bank statement
        dir = w.tmp_dir
        Zip::File.open(file) do |zile|
          w.count = zile.count
          zile.each do |entry|
            file = dir.join(entry.name)
            FileUtils.mkdir_p(file.dirname)
            entry.extract(file)
          end
        end

        Dir.chdir(dir) do
          Dir.glob('*') do |file|

            # import and parse file
            doc = Nokogiri::XML(File.open(file)) do |config|
              config.strict.nonet.noblanks
            end

            w.count = doc.css('parcelle').count

            # get pacage number and campaign
            pacage_number = doc.at_css('producteur').attribute('numero-pacage').value

            campaign = Campaign.find_or_create_by!(harvest_year: self.class.campaign)

            # get the exploitation siret_number
            siret_number = doc.at_css('demandeur siret').text

            # get global SRID
            first_town = doc.at_css('commune').text
            global_srid = find_srid(first_town)

            # get the exploitation name
            farm_name = guess_exploitation_name(doc)

            ## find or create Entity
            declarant = Entity.find_by('last_name ILIKE ?', farm_name)
            if declarant.nil?
              country_preference = Preference[:country]
              declarant = Entity.create!(
                last_name: farm_name,
                active: true,
                nature: :organization,
                country: country_preference,
                siret_number: siret_number
              )
            end

            cap_statement = CapStatement
                              .create_with(
                                farm_name: farm_name,
                              )
                              .find_or_create_by(
                                campaign: campaign,
                                declarant: declarant,
                                pacage_number: pacage_number,
                                siret_number: siret_number,
                              )

            # get the islets
            handle_islet(cap_statement, doc)

            # get SNA
            handle_sna(cap_statement, doc, global_srid)

          end
        end
        true
      end

    end
  end
end
