# coding: utf-8
require 'savon'
require 'curl'

module Tele
  module Idele
    autoload :Errors, 'tele/idele/ednotif/errors'
    autoload :Hash,   'tele/idele/ednotif/hash'

    class Ednotif
      attr_accessor :directory_wsdl, :company_code, :geo, :app_name, :ednotif_service_name, :ednotif_site_service_code, :ednotif_site_version_code, :ednotif_site_version, :user_id, :user_password

      ###### LOW-LEVEL SOAP API #########

      # @param [string] directory_wsdl: Url of directory web service wsdl
      # @param [string] company_code: Company to be contacted
      # @param [string] geo: Geographical space
      # @param [string] app_name: Name of App
      # @param [string] ednotif_service_name
      # @param [string] ednotif_site_service_code
      # @param [string] ednotif_site_version_code
      # @param [string] ednotif_site_version
      # @param [string] user_id: user id
      # @param [string] user_password: user password
      def initialize(options = {})
        @directory_wsdl = options[:directory_wsdl]
        @company_code = options[:company_code]
        @geo = options[:geo]
        @app_name = options[:app_name]
        @ednotif_service_name = options[:ednotif_service_name]
        @ednotif_site_service_code = options[:ednotif_site_service_code]
        @ednotif_site_version_code = options[:ednotif_site_version_code]
        @ednotif_site_version = options[:ednotif_site_version]
        @user_id = options[:user_id]
        @user_password = options[:user_password]
        @token = nil
        @customs_wsdl = nil
        @business_wsdl = nil
      end

      ##
      # Authenticate through Idele's webservices and fetch gained access token
      # return true if authentication succeeded and set @token
      def authenticate
        success = false
        if @token.nil?
          success = true if get_urls && get_token
        else
          success = true
        end
        success
      end

      ##
      # Connect to wsAnnuaire and fetch wsGuichet and wsMetier wsdl urls
      # return true if wsdl retrieved and set @business_wsdl and @customs_wsdl
      def get_urls
        connect(wsdl: @directory_wsdl, namespace_identifier: 'tk', namespaces: { 'xmlns:tk' => 'http://www.fiea.org/tk/', 'xmlns:typ' => 'http://www.fiea.org/types/' }) do |client|
          # tips: savonrb xml builder (aka wasabi) doesn't support automagic nested namespace. Need to give it by hand https://github.com/savonrb/savon/issues/532
          res = client.call(:tk_get_url,
                            message_tag: 'tkGetUrlRequest',
                            response_parser: :nokogiri,
                            message: {
                              'tk:ProfilDemandeur' => {
                                'typ:Entreprise' => @company_code,
                                'typ:Application' => @app_name
                              },
                              'tk:VersionPK' => {
                                'typ:NumeroVersion' => @ednotif_site_version,
                                'typ:CodeSiteVersion' => @ednotif_site_version_code,
                                'typ:NomService' => @ednotif_service_name,
                                'typ:CodeSiteService' => @ednotif_site_service_code
                              }
                            })

          doc = Nokogiri::XML(res.body[:tk_get_url_response].to_xml)

          result = doc.at_xpath('//resultat/child::text()').to_s
          err = doc.at_xpath('//anomalie')

          # error level 1 : hard error
          if result == 'false' && err
            code = err.at_xpath('//code/child::text()').to_s
            message = err.at_xpath('//message/child::text()').to_s
            fail ::Tele::Idele::Ednotif::Errors::ParsingError.new(code: code, message: message)

          # error level 2: could be sweet error or info notice
          elsif result == 'true' && err
            code = err.at_xpath('//code/child::text()').to_s
            message = err.at_xpath('//message/child::text()').to_s
            fail ::Tele::Idele::Ednotif::Errors::ParsingError.new(code: code, message: message)

          # everything is good
          elsif result == 'true'

            business = doc.at_xpath('//wsdl-metier/child::text()')
            customs = doc.at_xpath('//wsdl-guichet/child::text()')

            if business.nil? || customs.nil?
              fail ::Tele::Idele::Ednotif::Errors::ParsingError.new(code: 'WSRW0', message: 'Missing WSDL urls in xml from Reswel get url')
            end

            @business_wsdl = business.to_s
            @customs_wsdl = customs.to_s

          end

          return true
        end
      end

      ##
      # Fetch access token and set @token
      # return true if token retrieved

      def get_token
        connect(wsdl: @customs_wsdl, namespace_identifier: 'tk', namespaces: { 'xmlns:tk' => 'http://www.fiea.org/tk/', 'xmlns:typ' => 'http://www.fiea.org/types/' }) do |client|
          res = client.call(:tk_create_identification,
                            message_tag: 'tkCreateIdentificationRequest',
                            response_parser: :nokogiri,
                            message: {
                              'tk:Identification' => {
                                'typ:UserId' => @user_id,
                                'typ:Password' => @user_password,
                                'typ:Profil' => {
                                  'typ:Entreprise' => @company_code,
                                  'typ:Zone' => @geo,
                                  'typ:Application' => @app_name
                                }.reject { |_, v| v.nil? }
                              }
                            })

          doc = Nokogiri::XML(res.body[:tk_create_identification_response].to_xml)

          result = doc.at_xpath('//resultat/child::text()').to_s
          err = doc.at_xpath('//anomalie')

          # error level 1 : hard error
          if result == 'false' && err

            code = err.at_xpath('//code/child::text()').to_s
            message = err.at_xpath('//message/child::text()').to_s
            fail ::Tele::Idele::Ednotif::Errors::ParsingError.new(code: code, message: message)

          # error level 2: could be sweet error or info notice
          elsif result == 'true' && err

            code = err.at_xpath('//code/child::text()').to_s
            message = err.at_xpath('//message/child::text()').to_s
            fail ::Tele::Idele::Ednotif::Errors::ParsingError.new(code: code, message: message)

          # everything is good
          elsif result == 'true'

            token = doc.at_xpath('//jeton/child::text()')

            if token.nil?

              fail ::Tele::Idele::Ednotif::Errors::ParsingError.new(code: 'WSRW1', message: 'Missing token in xml from Reswel get token')

            end

            @token = token.to_s

          end

          return true
        end
      end

      ##
      # create_cattle_entrance: Notifier l'entrée d'un bovin sur une exploitation française
      # @param [string] token: token from reswel, length: 50
      # @param [string] farm_country_code: Toujours 'FR'. length: 2
      # @param [string] farm_number: Numéro d'exploitation française. length: 8
      # @param [string] animal_country_code: Code Pays UE. length: 2
      # @param [string] animal_id: Numéro national du bovin. max length: 12
      # @param [date] entry_date: Date entrée du bovin
      # @param [string] entry_reason: Cause d'entrée. (A/P) A=Achat, P=Prêt, pension
      # @param [string] src_country_code:A Code pays de l'exploitation de provenance. length: 2
      # @param [string] src_farm_number: Numéro d'exploitation de provenance. length: 12
      # @param [string] src_owner_name: Nom du détenteur. max length: 60
      # @param [string] prod_code: Le code atelier, du type AtelierBovinIPG(cf p18). length: 2
      # @param [string] cattle_categ_code: Le code catégorie du bovin (cf p18). length: 2
      def create_cattle_entrance(options = {})
        connect_business do |client, _status|
          res = client.call(:ip_b_create_entree,
                            message_tag: 'IpBCreateEntreeRequest',
                            response_parser: :nokogiri,
                            message: {
                              'sch:JetonAuthentification' => @token,
                              'sch:Exploitation' => {
                                'sch:CodePays' => options[:farm_country_code],
                                'sch:NumeroExploitation' => options[:farm_number]
                              },
                              'sch:Bovin' => {
                                'sch:CodePays' => options[:animal_country_code],
                                'sch:NumeroNational' => options[:animal_id]
                              },
                              'sch:DateEntree' => options[:entry_date],
                              'sch:CauseEntree' => options[:entry_reason],
                              'sch:ExploitationProvenance' => {
                                'sch:Exploitation' => {
                                  'sch:CodePays' => options[:src_farm_country_code],
                                  'sch:NumeroExploitation' => options[:src_farm_number]
                                },
                                'sch:NomExploitation' => options[:src_farm_owner_name]
                              },
                              'sch:CodeAtelier' => options[:prod_code],
                              'sch:CodeCategorieBovin' => options[:cattle_categ_code]
                            }.reject { |_, v| v.nil? })

          doc = Nokogiri::XML(res.body[:ip_b_create_entree_response].to_xml)

          result = doc.at_xpath('//resultat/child::text()').to_s
          err = doc.at_xpath('//anomalie')

          # error level 1 : hard error
          if result == 'false' && err

            code = err.at_xpath('//code/child::text()').to_s
            message = err.at_xpath('//message/child::text()').to_s
            fail ::Tele::Idele::Ednotif::Errors::ParsingError.new(code: code, message: message)

          # error level 2: could be sweet error or info notice
          elsif result == 'true' && err
            code = err.at_xpath('//code/child::text()').to_s
            message = err.at_xpath('//message/child::text()').to_s
            fail ::Tele::Idele::Ednotif::Errors::ParsingError.new(code: code, message: message)

          # everything is good
          elsif result == 'true'
            status = false

            if doc.at_xpath('//attente-validation-bd-ni/child::text()').to_s == 'true'
              status = 'waiting validation'
            end

            status = 'validated' unless doc.at_xpath('//sortie-validee').nil?

          end
        end
      end

      ##
      # create_cattle_exit: Notifier la sortie d'un bovin d'une exploitation française
      # @param [string] token: token from reswel, length: 50
      # @param [string] farm_country_code: Toujours 'FR'. length: 2
      # @param [string] farm_number: Numéro d'exploitation française. length: 8
      # @param [string] animal_country_code: Code Pays UE. length: 2
      # @param [string] animal_id: Numéro national du bovin. max length: 12
      # @param [date] exit_date: Date de sortie du bovin
      # @param [string] exit_reason: Cause de sortie. (B/C/E/H/M) B=boucherie, C=auto-consommation, E=vente en élevage, H=Prêt/Pension, M=Mort
      # @param [string] dest_country_code: Code pays de l'exploitation de destination. length: 2
      # @param [string] dest_farm_number: Numéro d'exploitation de destination. length: 12
      # @param [string] dest_owner_name: Nom du détenteur. max length: 60
      def create_cattle_exit(options = {})
        connect_business do |client, _status|
          res = client.call(:ip_b_create_sortie,
                            message_tag: 'IpBCreateSortieRequest',
                            response_parser: :nokogiri,
                            message: {
                              'sch:JetonAuthentification' => @token,
                              'sch:Exploitation' => {
                                'sch:CodePays' => options[:farm_country_code],
                                'sch:NumeroExploitation' => options[:farm_number]
                              },
                              'sch:Bovin' => {
                                'sch:CodePays' => options[:animal_country_code],
                                'sch:NumeroNational' => options[:animal_id]
                              },
                              'sch:DateSortie' => options[:exit_date],
                              'sch:CauseSortie' => options[:exit_reason],
                              'sch:ExploitationDestination' => {
                                'sch:Exploitation' => {
                                  'sch:CodePays' => options[:dest_country_code],
                                  'sch:NumeroExploitation' => options[:dest_farm_number]
                                },
                                'sch:NomExploitation' => options[:dest_owner_name]
                              }
                            }.reject { |_, v| v.nil? })

          doc = Nokogiri::XML(res.body[:ip_b_create_sortie_response].to_xml)

          result = doc.at_xpath('//resultat/child::text()').to_s
          err = doc.at_xpath('//anomalie')

          # error level 1 : hard error
          if result == 'false' && err

            code = err.at_xpath('//code/child::text()').to_s
            message = err.at_xpath('//message/child::text()').to_s
            fail ::Tele::Idele::Ednotif::Errors::ParsingError.new(code: code, message: message)

          # error level 2: could be sweet error or info notice
          elsif result == 'true' && err
            code = err.at_xpath('//code/child::text()').to_s
            message = err.at_xpath('//message/child::text()').to_s
            fail ::Tele::Idele::Ednotif::Errors::ParsingError.new(code: code, message: message)

          # everything is good
          elsif result == 'true'
            status = false

            if doc.at_xpath('//attente-validation-bd-ni/child::text()').to_s == 'true'
              status = 'waiting validation'
            end

            status = 'validated' unless doc.at_xpath('//sortie-validee').nil?
          end
        end
      end

      ##
      # create_cattle_new_birth: Notifier la naissance d'un bovin sur une exploitation française
      # @param [string] token: token from reswel, length: 50
      # @param [string] farm_country_code: Toujours 'FR'. length: 2
      # @param [string] farm_number: Numéro d'exploitation française. length: 8
      # @param [string] animal_country_code: Code Pays UE. length: 2
      # @param [string] animal_id: Numéro national du bovin. max length: 12
      # @param [string] sex: Sexe du bovin: length: 1
      # @param [string] race_code: Type racial . length: 2
      # @param [date] birth_date: Date de Naissance
      # @param [number] work_number: Numéro de travail de bovin. length: 4
      # @param [string] cattle_name: Nom du bovin.
      # @param [Boolean] transplant: Si l'animal est issu d'une transplantation embryonnaire
      # @param [Boolean] abortion: Avortement
      # @param [Boolean] twin: Si l'animal est issu d'une naissance gémélaire
      # @param [string] birth_condition: Condition de naissance du bovin. (cf p95)
      # @param [int] birth_weight: Poids de naissance du bovin. (1-99)
      # @param [Boolean] weighed: Si le bovin a été pesé pour déterminer son poids
      # @param [int] bust_size: Tour de poitrine en cm. max length: 3
      # @param [string] mother_animal_country_code: Code Pays de la mère porteuse. length: 2
      # @param [string] mother_animal_id: Numéro national de la mère porteuse. max length: 12
      # @param [string] mother_race_code: Type racial de la mère porteuse . length: 2
      # @param [string] father_animal_country_code: Code Pays du père IPG. length: 2
      # @param [string] father_animal_id: Numéro national du père IPG. max length: 12
      # @param [string] father_race_code: Type racial du père IPG . length: 2
      # @param [Boolean] passport_ask: Indique si une demande d'édition du passeport en urgence
      # @param [Object] prod_code: Le type d'atelier du type AtelierBovinIPG. length: 2
      def create_cattle_new_birth(options = {})
        connect_business do |client, _status|
          res = client.call(:ip_b_create_naissance,
                            message_tag: 'IpBCreateNaissanceRequest',
                            response_parser: :nokogiri,
                            message: {
                              'sch:JetonAuthentification' => @token,
                              'sch:ExploitationNaissance' => {
                                'sch:CodePays' => options[:farm_country_code],
                                'sch:NumeroExploitation' => options[:farm_number]
                              },
                              'sch:Bovin' => {
                                'sch:CodePays' => options[:animal_country_code],
                                'sch:NumeroNational' => options[:animal_id]
                              },
                              'sch:Sexe' => options[:sex],
                              'sch:TypeRacial' => options[:race_code],
                              'sch:DateNaissance' => options[:birth_date],
                              'sch:NumeroTravail' => options[:work_number],
                              'sch:NomBovin' => options[:cattle_name],
                              'sch:Filiation' => {
                                'sch:TransplantationEmbryonnaire' => options[:transplant],
                                'sch:Avortement' => options[:abortion],
                                'sch:Jumeau' => options[:twin],
                                'sch:ConditionNaissance' => options[:birth_condition],
                                'sch:Poids' => {
                                  'sch:PoidsNaissance' => options[:birth_weight],
                                  'sch:PoidsPese' => options[:weighed]
                                }.reject { |_, v| v.nil? },
                                'sch:TourPoitrine' => options[:buts_size]
                              }.reject { |_, v| v.nil? },
                              'sch:MerePorteuse' => {
                                'sch:Bovin' => {
                                  'sch:CodePays' => options[:mother_animal_country_code],
                                  'sch:NumeroNational' => options[:mother_animal_id]
                                },
                                'sch:TypeRacial' => options[:mother_race_code]
                              },
                              'sch:PereIPG' => {
                                'sch:Bovin' => {
                                  'sch:CodePays' => options[:father_animal_country_code],
                                  'sch:NumeroNational' => options[:father_animal_id]
                                },
                                'sch:TypeRacial' => options[:father_race_code]
                              }.reject { |_, v| v.nil? },
                              'sch:DemandePasseport' => options[:passport_ask],
                              'sch:CodeAtelier' => options[:prod_code]
                            }.reject { |_, v| v.nil? })

          doc = Nokogiri::XML(res.body[:ip_b_create_naissance_response].to_xml)

          result = doc.at_xpath('//resultat/child::text()').to_s
          err = doc.at_xpath('//anomalie')

          # error level 1 : hard error
          if result == 'false' && err

            code = err.at_xpath('//code/child::text()').to_s
            message = err.at_xpath('//message/child::text()').to_s
            fail ::Tele::Idele::Ednotif::Errors::ParsingError.new(code: code, message: message)

          # error level 2: could be sweet error or info notice
          elsif result == 'true' && err
            code = err.at_xpath('//code/child::text()').to_s
            message = err.at_xpath('//message/child::text()').to_s
            fail ::Tele::Idele::Ednotif::Errors::ParsingError.new(code: code, message: message)

          # everything is good
          elsif result == 'true'
            status = false
            status = 'validated' unless doc.at_xpath('//identite-bovin').nil?
          end
        end
      end

      ##
      # create_cattle_new_stillbirth: Notifier la naissance d'un bovin mort-né non bouclé sur une exploitation française
      # @param [string] token: token from reswel, length: 50
      # @param [string] farm_country_code: Toujours 'FR'. length: 2
      # @param [string] farm_number: Numéro d'exploitation française. length: 8
      # @param [string] sex: Sexe du bovin: length: 1
      # @param [string] race_code: Type racial . length: 2
      # @param [date] birth_date: Date de Naissance
      # @param [string] cattle_name: Nom du bovin.
      # @param [Boolean] transplant: Si l'animal est issu d'une transplantation embryonnaire
      # @param [Boolean] abortion: Avortement
      # @param [Boolean] twin: Si l'animal est issu d'une naissance gémélaire
      # @param [string] birth_condition: Condition de naissance du bovin. (cf p95)
      # @param [int] birth_weight: Poids de naissance du bovin. (1-99)
      # @param [Boolean] weighed: Si le bovin a été pesé pour déterminer son poids
      # @param [int] bust_size: Tour de poitrine en cm. max length: 3
      # @param [string] mother_animal_country_code: Code Pays de la mère porteuse. length: 2
      # @param [string] mother_animal_id: Numéro national de la mère porteuse. max length: 12
      # @param [string] mother_race_code: Type racial de la mère porteuse . length: 2
      # @param [string] father_animal_country_code: Code Pays du père IPG. length: 2
      # @param [string] father_animal_id: Numéro national du père IPG. max length: 12
      # @param [string] father_race_code: Type racial du père IPG . length: 2
      def create_cattle_new_stillbirth(options = {})
        connect_business do |client, _status|
          res = client.call(:ip_b_create_mort_ne,
                            message_tag: 'IpBCreateMortNeRequest',
                            response_parser: :nokogiri,
                            message: {
                              'sch:JetonAuthentification' => @token,
                              'sch:ExploitationNaissance' => {
                                'sch:CodePays' => options[:farm_country_code],
                                'sch:NumeroExploitation' => options[:farm_number]
                              },
                              'sch:Sexe' => options[:sex],
                              'sch:TypeRacial' => options[:race_code],
                              'sch:DateNaissance' => options[:birth_date],
                              'sch:NomBovin' => options[:cattle_name],
                              'sch:Filiation' => {
                                'sch:TransplantationEmbryonnaire' => options[:transplant],
                                'sch:Avortement' => options[:abortion],
                                'sch:Jumeau' => options[:twin],
                                'sch:ConditionNaissance' => options[:birth_condition],
                                'sch:Poids' => {
                                  'sch:PoidsNaissance' => options[:birth_weight],
                                  'sch:PoidsPese' => options[:weighed]
                                }.reject { |_, v| v.nil? },
                                'sch:TourPoitrine' => options[:buts_size]
                              }.reject { |_, v| v.nil? },
                              'sch:MerePorteuse' => {
                                'sch:Bovin' => {
                                  'sch:CodePays' => options[:mother_animal_country_code],
                                  'sch:NumeroNational' => options[:mother_animal_id]
                                },
                                'sch:TypeRacial' => options[:mother_race_code]
                              },
                              'sch:PereIPG' => {
                                'sch:Bovin' => {
                                  'sch:CodePays' => options[:father_animal_country_code],
                                  'sch:NumeroNational' => options[:father_animal_id]
                                },
                                'sch:TypeRacial' => options[:father_race_code]
                              }.reject { |_, v| v.nil? }
                            }.reject { |_, v| v.nil? })

          doc = Nokogiri::XML(res.body[:ip_b_create_mort_ne_response].to_xml)

          result = doc.at_xpath('//resultat/child::text()').to_s
          err = doc.at_xpath('//anomalie')

          # error level 1 : hard error
          if result == 'false' && err

            code = err.at_xpath('//code/child::text()').to_s
            message = err.at_xpath('//message/child::text()').to_s
            fail ::Tele::Idele::Ednotif::Errors::ParsingError.new(code: code, message: message)

          # error level 2: could be sweet error or info notice
          elsif result == 'true' && err
            code = err.at_xpath('//code/child::text()').to_s
            message = err.at_xpath('//message/child::text()').to_s
            fail ::Tele::Idele::Ednotif::Errors::ParsingError.new(code: code, message: message)

          # everything is good
          elsif result == 'true'
            status = false
            status = 'validated' unless doc.at_xpath('//identite-bovin').nil?
          end
        end
      end

      ##
      # create_switched_animal: notifier la première entrée en France d’un bovin échangé (né dans l’Union Européenne) sur une exploitation française
      # @param [string] token: token from reswel, length: 50
      # @param [string] farm_number: Numéro d'exploitation française. length: 8
      # @param [string] animal_country_code: Code Pays UE. length: 2
      # @param [string] animal_id: Numéro national du bovin. max length: 12
      # @param [string] sex: Sexe du bovin: length: 1
      # @param [string] race_code: Type racial . length: 2
      # @param [date] birth_date: Date de Naissance
      # @param [string] witness: Témoin de complétude (0/1/2) 0=date complète, 1=date incomplète sur jour, 2=date incomplète sur jour et mois
      # @param [number] work_number: Numéro de travail de bovin. length: 4
      # @param [string] cattle_name: Nom du bovin.
      # @param [Boolean] status: Indique si l'animal est filié (CPB)
      # @param [string] mother_animal_country_code: Code Pays de la mère porteuse. length: 2
      # @param [string] mother_animal_id: Numéro national de la mère porteuse. max length: 12
      # @param [string] mother_race_code: Type racial de la mère porteuse . length: 2
      # @param [string] father_animal_country_code: Code Pays du père IPG. length: 2
      # @param [string] father_animal_id: Numéro national du père IPG. max length: 12
      # @param [string] father_race_code: Type racial du père IPG . length: 2
      # @param [string] birth_farm_country_code: Code pays de l'exploitation de naissance. length: 2
      # @param [string] birth_farm_number: Numéro d'exploitation de naissance. length: 12
      # @param [string] entry_date: Date entrée du bovin
      # @param [string] entry_reason: Cause d'entrée. (A/P)
      # @param [string] src_country_code: Code pays de l'exploitation de provenance. length: 2
      # @param [string] src_farm_number: Numéro d'exploitation de provenance. length: 12
      # @param [string] src_owner_name: Nom du détenteur. max length: 60
      # @param [string] prod_code: Le type d'atelier du type AtelierBovinIPG. length: 2
      # @param [string] cattle_categ_code: Le code catégorie du bovin. length: 2
      def create_switched_animal(options = {})
        connect_business do |client, _status|
          res = client.call(:ip_b_create_animal_echange,
                            message_tag: 'IpBCreateAnimalEchangeRequest',
                            response_parser: :nokogiri,
                            message: {
                              'sch:JetonAuthentification' => @token,
                              'sch:ExploitationNotification' => {
                                'sch:CodePays' => options[:farm_country_code],
                                'sch:NumeroExploitation' => options[:farm_number]
                              },
                              'sch:Bovin' => {
                                'sch:CodePays' => options[:animal_country_code],
                                'sch:NumeroNational' => options[:animal_id]
                              },
                              'sch:Sexe' => options[:sex],
                              'sch:TypeRacial' => options[:race_code],
                              'sch:DateNaissance' => {
                                'sch:Date' => options[:birth_date],
                                'sch:TemoinCompletude' => options[:witness]
                              },
                              'sch:NumeroTravail' => options[:work_number],
                              'sch:NomBovin' => options[:cattle_name],
                              'sch:MerePorteuse' => {
                                'sch:Bovin' => {
                                  'sch:CodePays' => options[:mother_animal_country_code],
                                  'sch:NumeroNational' => options[:mother_animal_id]
                                },
                                'sch:TypeRacial' => options[:mother_race_code]
                              },
                              'sch:PereIPG' => {
                                'sch:Bovin' => {
                                  'sch:CodePays' => options[:father_animal_country_code],
                                  'sch:NumeroNational' => options[:father_animal_id]
                                },
                                'sch:TypeRacial' => options[:father_race_code]
                              }.reject { |_, v| v.nil? },
                              'sch:ExploitationNaissance' => {
                                'sch:CodePays' => options[:birth_farm_country_code],
                                'sch:NumeroExploitation' => options[:birth_farm_number]
                              },
                              'sch:DateEntree' => options[:entry_date],
                              'sch:CauseEntree' => options[:entry_reason],
                              'sch:ExploitationProvenance' => {
                                'sch:Exploitation' => {
                                  'sch:CodePays' => options[:src_farm_country_code],
                                  'sch:NumeroExploitation' => options[:src_farm_number]
                                },
                                'sch:NomExploitation' => options[:src_farm_owner_name]
                              },
                              'sch:CodeAtelier' => options[:prod_code],
                              'sch:CodeCategorieBovin' => options[:cattle_categ_code]
                            }.reject { |_, v| v.nil? })

          doc = Nokogiri::XML(res.body[:ip_b_create_animal_echange_response].to_xml)

          result = doc.at_xpath('//resultat/child::text()').to_s
          err = doc.at_xpath('//anomalie')

          # error level 1 : hard error
          if result == 'false' && err

            code = err.at_xpath('//code/child::text()').to_s
            message = err.at_xpath('//message/child::text()').to_s
            fail ::Tele::Idele::Ednotif::Errors::ParsingError.new(code: code, message: message)

          # error level 2: could be sweet error or info notice
          elsif result == 'true' && err
            code = err.at_xpath('//code/child::text()').to_s
            message = err.at_xpath('//message/child::text()').to_s
            fail ::Tele::Idele::Ednotif::Errors::ParsingError.new(code: code, message: message)

          # everything is good
          elsif result == 'true'
            status = false

            status = 'validated' unless doc.at_xpath('//identite-bovin').nil?
          end
        end
      end

      ##
      # create_imported_animal_notice: prévenir le MOIPG qu’un animal importé (né hors Union Européenne) est entré sur l’exploitation et qu’un rebouclage selon la réglementation française est nécessaire.
      # @param [string] token: token from reswel, length: 50
      # @param [string] farm_country_code: Toujours 'FR'. length: 2
      # @param [string] farm_number: Numéro d'exploitation française. length: 8
      # @param [string] src_animal_country_code: Code pays d'origine du bovin. length: 2
      # @param [string] src_animal_id: Numéro national d'origine du bovin. max length: 12
      def create_imported_animal_notice(options = {})
        connect_business do |client, _status|
          res = client.call(:ip_b_create_avis_animal_importe,
                            message_tag: 'IpBCreateAvisAnimalImporteRequest',
                            response_parser: :nokogiri,
                            message: {
                              'sch:JetonAuthentification' => @token,
                              'sch:Exploitation' => {
                                'sch:CodePays' => options[:farm_country_code],
                                'sch:NumeroExploitation' => options[:farm_number]
                              },
                              'sch:Bovin' => {
                                'sch:CodePaysOrigineBovin' => options[:src_animal_country_code],
                                'sch:NumeroOrigineBovin' => options[:src_animal_id]
                              }
                            })

          doc = Nokogiri::XML(res.body[:ip_b_create_avis_animal_importe_response].to_xml)

          result = doc.at_xpath('//resultat/child::text()').to_s
          err = doc.at_xpath('//anomalie')

          # error level 1 : hard error
          if result == 'false' && err

            code = err.at_xpath('//code/child::text()').to_s
            message = err.at_xpath('//message/child::text()').to_s
            fail ::Tele::Idele::Ednotif::Errors::ParsingError.new(code: code, message: message)

          # error level 2: could be sweet error or info notice
          elsif result == 'true' && err
            code = err.at_xpath('//code/child::text()').to_s
            message = err.at_xpath('//message/child::text()').to_s
            fail ::Tele::Idele::Ednotif::Errors::ParsingError.new(code: code, message: message)

          # everything is good
          elsif result == 'true'
            status = 'validated'
          end
        end
      end

      ##
      # create_imported_animal: notifier la première entrée en France d’un bovin importé (né hors Union Européenne) sur une exploitation française.
      # @param [string] token: token from reswel, length: 50
      # @param [string] farm_number: Numéro d'exploitation française. length: 8
      # @param [string] animal_country_code: Code Pays UE. length: 2
      # @param [string] animal_id: Numéro national du bovin. max length: 12
      # @param [string] sex: Sexe du bovin: length: 1
      # @param [string] race_code: Type racial . length: 2
      # @param [date] birth_date: Date de Naissance
      # @param [string] witness: Témoin de complétude
      # @param [number] work_number: Numéro de travail de bovin. length: 4
      # @param [string] cattle_name: Nom du bovin.
      # @param [Boolean] status: Indique si l'animal est filié (CPB)
      # @param [string] mother_animal_country_code: Code Pays de la mère porteuse. length: 2
      # @param [string] mother_animal_id: Numéro national de la mère porteuse. max length: 12
      # @param [string] mother_race_code: Type racial de la mère porteuse . length: 2
      # @param [string] father_animal_country_code: Code Pays du père IPG. length: 2
      # @param [string] father_animal_id: Numéro national du père IPG. max length: 12
      # @param [string] father_race_code: Type racial du père IPG . length: 2
      # @param [string] birth_farm_country_code: Code pays de l'exploitation de naissance. length: 2
      # @param [string] birth_farm_number: Numéro d'exploitation de naissance. length: 12
      # @param [string] src_animal_country_code: Code pays d'origine du bovin. length: 2
      # @param [string] src_animal_id: Numéro national d'origine du bovin. max length: 12
      # @param [string] entry_date: Date entrée du bovin
      # @param [string] entry_reason: Cause d'entrée. (A/P)
      # @param [string] src_farm_country_code: Code pays de l'exploitation de provenance. length: 2
      # @param [string] src_farm_number: Numéro d'exploitation de provenance. length: 12
      # @param [string] src_farm_owner_name: Nom du détenteur. max length: 60
      # @param [string] prod_code: Le type d'atelier du type AtelierBovinIPG. length: 2
      # @param [string] cattle_categ_code: Le code catégorie du bovin. length: 2
      def create_imported_animal(options = {})
        connect_business do |client, _status|
          res = client.call(:ip_b_create_animal_importe,
                            message_tag: 'IpBCreateAnimalImporteRequest',
                            response_parser: :nokogiri,
                            message: {
                              'sch:JetonAuthentification' => @token,
                              'sch:ExploitationNotification' => {
                                'sch:CodePays' => options[:farm_country_code],
                                'sch:NumeroExploitation' => options[:farm_number]
                              },
                              'sch:Bovin' => {
                                'sch:CodePays' => options[:animal_country_code],
                                'sch:NumeroNational' => options[:animal_id]
                              },
                              'sch:Sexe' => options[:sex],
                              'sch:TypeRacial' => options[:race_code],
                              'sch:DateNaissance' => {
                                'sch:Date' => options[:birth_date],
                                'sch:TemoinCompletude' => options[:witness]
                              },
                              'sch:NumeroTravail' => options[:work_number],
                              'sch:NomBovin' => options[:cattle_name],
                              'sch:MerePorteuse' => {
                                'sch:Bovin' => {
                                  'sch:CodePays' => options[:mother_animal_country_code],
                                  'sch:NumeroNational' => options[:mother_animal_id]
                                },
                                'sch:TypeRacial' => options[:mother_race_code]
                              },
                              'sch:PereIPG' => {
                                'sch:Bovin' => {
                                  'sch:CodePays' => options[:father_animal_country_code],
                                  'sch:NumeroNational' => options[:father_animal_id]
                                },
                                'sch:TypeRacial' => options[:father_race_code]
                              }.reject { |_, v| v.nil? },
                              'sch:ExploitationNaissance' => {
                                'sch:CodePays' => options[:birth_farm_country_code],
                                'sch:NumeroExploitation' => options[:birth_farm_number]
                              },
                              'sch:CodePaysOrigineBovin' => options[:src_animal_country_code],
                              'sch:NumeroOrigineBovin' => options[:src_animal_id],
                              'sch:DateEntree' => options[:entry_date],
                              'sch:CauseEntree' => options[:entry_reason],
                              'sch:ExploitationProvenance' => {
                                'sch:Exploitation' => {
                                  'sch:CodePays' => options[:src_farm_country_code],
                                  'sch:NumeroExploitation' => options[:src_farm_number]
                                },
                                'sch:NomExploitation' => options[:src_farm_owner_name]
                              },
                              'sch:CodeAtelier' => options[:prod_code],
                              'sch:CodeCategorieBovin' => options[:cattle_categ_code]
                            }.reject { |_, v| v.nil? })

          doc = Nokogiri::XML(res.body[:ip_b_create_animal_importe_response].to_xml)

          result = doc.at_xpath('//resultat/child::text()').to_s
          err = doc.at_xpath('//anomalie')

          # error level 1 : hard error
          if result == 'false' && err

            code = err.at_xpath('//code/child::text()').to_s
            message = err.at_xpath('//message/child::text()').to_s
            fail ::Tele::Idele::Ednotif::Errors::ParsingError.new(code: code, message: message)

          # error level 2: could be sweet error or info notice
          elsif result == 'true' && err
            code = err.at_xpath('//code/child::text()').to_s
            message = err.at_xpath('//message/child::text()').to_s
            fail ::Tele::Idele::Ednotif::Errors::ParsingError.new(code: code, message: message)

          # everything is good
          elsif result == 'true'
            status = false
            status = 'validated' unless doc.at_xpath('//identite-bovin').nil?
          end
        end
      end

      ##
      # get_cattle_list: fournir l’inventaire des bovins d’une exploitation entre deux dates. L’inventaire peut être complété par la liste des boucles disponibles.
      # @param [string] token: token from reswel, length: 50
      # @param [string] farm_country_code: Toujours 'FR'. length: 2
      # @param [string] farm_number: Numéro d'exploitation française. length: 8
      # @param [date] start_date: Date début de période de présence des bovins
      # @param [date] end_date: Date fin de période de présence des bovins
      # @param [Object] stock: Indique si le stock de boucles doit être retourné
      def get_cattle_list(options = {})
        connect_business do |client, _status|
          res = client.call(:ip_b_get_inventaire,
                            message_tag: 'IpBGetInventaireRequest',
                            response_parser: :nokogiri,
                            message: {
                              'sch:JetonAuthentification' => @token,
                              'sch:Exploitation' => {
                                'sch:CodePays' => options[:farm_country_code],
                                'sch:NumeroExploitation' => options[:farm_number]
                              },
                              'sch:DateDebut' => options[:start_date],
                              'sch:DateFin' => options[:end_date],
                              'sch:StockBoucles' => options[:stock]
                            }.reject { |_, v| v.nil? })

          doc = Nokogiri::XML(res.body[:ip_b_get_inventaire_response].to_xml)

          result = doc.at_xpath('//resultat/child::text()').to_s
          err = doc.at_xpath('//anomalie')

          # error level 1 : hard error
          if result == 'false' && err

            code = err.at_xpath('//code/child::text()').to_s
            message = err.at_xpath('//message/child::text()').to_s
            fail ::Tele::Idele::Ednotif::Errors::ParsingError.new(code: code, message: message)

          # error level 2: could be sweet error or info notice
          elsif result == 'true' && err
            code = err.at_xpath('//code/child::text()').to_s
            message = err.at_xpath('//message/child::text()').to_s
            fail ::Tele::Idele::Ednotif::Errors::ParsingError.new(code: code, message: message)

          # everything is good
          elsif result == 'true'
            status = false
            unless doc.at_xpath('//nb-bovins').nil?
              status = 'validated'
              message_zip = doc.at_xpath('//message-zip/child::text()').to_s
              { output_hash: self.class.decode_zip(message_zip) }
            end
          end
        end
      end

      ##
      # get_case_feedback: permet de fournir, pour une exploitation, les animaux ayant eu une modification d’identité ou de mouvement depuis la dernière demande effectuée
      # @param [string] farm_country_code: Toujours 'FR'. length: 2
      # @param [string] farm_number: Numéro d'exploitation française concernée par la demande de dossiers. length: 8
      # @param [date] start_date: Date début de fourniture des dossiers
      def get_case_feedback(options = {})
        connect_business do |client, _status|
          res = client.call(:ip_b_get_retour_dossiers,
                            message_tag: 'IpBGetRetourDossiersRequest',
                            response_parser: :nokogiri,
                            message: {
                              'sch:JetonAuthentification' => @token,
                              'sch:Exploitation' => {
                                'sch:CodePays' => options[:farm_country_code],
                                'sch:NumeroExploitation' => options[:farm_number]
                              },
                              'sch:DateDebut' => options[:start_date]
                            }.reject { |_, v| v.nil? })

          doc = Nokogiri::XML(res.body[:ip_b_get_retour_dossiers_response].to_xml)

          result = doc.at_xpath('//resultat/child::text()').to_s
          err = doc.at_xpath('//anomalie')

          # error level 1 : hard error
          if result == 'false' && err

            code = err.at_xpath('//code/child::text()').to_s
            message = err.at_xpath('//message/child::text()').to_s
            fail ::Tele::Idele::Ednotif::Errors::ParsingError.new(code: code, message: message)

          # error level 2: could be sweet error or info notice
          elsif result == 'true' && err
            code = err.at_xpath('//code/child::text()').to_s
            message = err.at_xpath('//message/child::text()').to_s
            fail ::Tele::Idele::Ednotif::Errors::ParsingError.new(code: code, message: message)

          # everything is good
          elsif result == 'true'

            status = false

            unless doc.at_xpath('//nb-bovins').nil?
              status = 'validated'
              message_zip = doc.at_xpath('//message-zip/child::text()').to_s
              { output_hash: self.class.decode_zip(message_zip) }
            end
          end
        end
      end

      ##
      # get_animal_case: permet de fournir le dossier d’un bovin (identité et mouvements) concernant une exploitation.
      # @param [string] token: token from reswel, length: 50
      # @param [string] farm_country_code: Toujours 'FR'. length: 2
      # @param [string] farm_number: Numéro d'exploitation française. length: 8
      # @param [string] animal_country_code: Code Pays UE. length: 2
      # @param [string] animal_id: Numéro national du bovin. max length: 12
      def get_animal_case(options = {})
        connect_business do |client, _status|
          res = client.call(:ip_b_get_dossier_animal,
                            message_tag: 'IpBGetDossierAnimalRequest',
                            response_parser: :nokogiri,
                            message: {
                              'sch:JetonAuthentification' => @token,
                              'sch:Exploitation' => {
                                'sch:CodePays' => options[:farm_country_code],
                                'sch:NumeroExploitation' => options[:farm_number]
                              },
                              'sch:Bovin' => {
                                'sch:CodePays' => options[:animal_country_code],
                                'sch:NumeroNational' => options[:animal_id]
                              }
                            }.reject { |_, v| v.nil? })

          doc = Nokogiri::XML(res.body[:ip_b_get_dossier_animal_response].to_xml)

          result = doc.at_xpath('//resultat/child::text()').to_s
          err = doc.at_xpath('//anomalie')

          # error level 1 : hard error
          if result == 'false' && err

            code = err.at_xpath('//code/child::text()').to_s
            message = err.at_xpath('//message/child::text()').to_s
            fail ::Tele::Idele::Ednotif::Errors::ParsingError.new(code: code, message: message)

          # error level 2: could be sweet error or info notice
          elsif result == 'true' && err
            code = err.at_xpath('//code/child::text()').to_s
            message = err.at_xpath('//message/child::text()').to_s
            fail ::Tele::Idele::Ednotif::Errors::ParsingError.new(code: code, message: message)

          # everything is good
          elsif result == 'true'

            status = false
            unless doc.at_xpath('//bovin').nil?
              status = 'validated'
              { output_hash: Hash.from_xml(doc.at_xpath('//bovin').to_s) }
            end
          end
        end
      end

      ##
      # create_commande_boucles: commander des boucles de naissance, des pinces et des pointeaux.
      # @param [string] token: token from reswel, length: 50
      # @param [string] farm_country_code: Toujours 'FR'. length: 2
      # @param [string] farm_number: Numéro d'exploitation française. length: 8
      # @param [integer] nb_paires_boucles: Nombre de paires de boucles à commander. max: 9999
      # @param [string] reference_boucles: Code produit des boucles commandées.
      # @param [integer] nb_pinces: Nombre de paires de pinces à commander. max: 9
      # @param [string] reference_pinces: Code produit des pinces commandées.
      # @param [integer] nb_pointeaux: Nombre de pointeaux à commander. max: 9
      # @param [string] reference_pointeaux: Code produit des pointeaux commandés.
      def create_commande_boucles(options = {})
        connect_business do |client, _status|
          res = client.call(:ip_b_create_commande_boucles,
                            message_tag: 'IpBCreateCommandeBouclesRequest',
                            response_parser: :nokogiri,
                            message: {
                              'sch:JetonAuthentification' => @token,
                              'sch:ExploitationNotification' => {
                                'sch:CodePays' => options[:farm_country_code],
                                'sch:NumeroExploitation' => options[:farm_number]
                              },
                              'sch:Boucle' => {
                                'sch:NbPairesBoucles' => options[:nb_paires_boucles],
                                'sch:ReferenceBoucles' => options[:reference_boucles]
                              }.reject { |_, v| v.nil? },
                              'sch:Pince' => {
                                'sch:NbPinces' => options[:nb_pinces],
                                'sch:ReferencePinces' => options[:reference_pinces]
                              }.reject { |_, v| v.nil? },
                              'sch:Pointeau' => {
                                'sch:NbPointeaux' => options[:nb_pointeaux],
                                'sch:ReferencePointeaux' => options[:reference_pointeaux]
                              }.reject { |_, v| v.nil? }
                            }.reject { |_, v| v.nil? })

          doc = Nokogiri::XML(res.body[:ip_b_create_commande_boucles_response].to_xml)

          result = doc.at_xpath('//resultat/child::text()').to_s
          err = doc.at_xpath('//anomalie')

          # error level 1 : hard error
          if result == 'false' && err

            code = err.at_xpath('//code/child::text()').to_s
            message = err.at_xpath('//message/child::text()').to_s
            fail ::Tele::Idele::Ednotif::Errors::ParsingError.new(code: code, message: message)

          # error level 2: could be sweet error or info notice
          elsif result == 'true' && err
            code = err.at_xpath('//code/child::text()').to_s
            message = err.at_xpath('//message/child::text()').to_s
            fail ::Tele::Idele::Ednotif::Errors::ParsingError.new(code: code, message: message)

          # everything is good
          elsif result == 'true'
            status = 'validated'
          end
        end
      end

      ##
      # create_rebouclage: commander une boucle de rebouclage (R2) pour un bovin.
      # @param [string] token: token from reswel, length: 50
      # @param [string] farm_country_code: Toujours 'FR'. length: 2
      # @param [string] farm_number: Numéro d'exploitation française. length: 8
      # @param [string] animal_country_code: Code Pays UE. length: 2
      # @param [string] animal_id: Numéro national du bovin. max length: 12
      # @param [boolean] boucle_conventionnelle: Indique si la boucle demandée est conventionnelle
      # @param [boolean] boucle_travail: Si la boucle conventionnelle avec numéro de travail uniquement
      # @param [boolean] boucle_electronique: Indique si la boucle est electronique
      # @param [string] cause_remplacement: Motif de la commande de la boucle de rebouclage. length: 1 (C/E/I/L/P/X/Y/Z) Cassé/Electronisation/Illisible/électronique perdu/perdu/anomalie de commande/anomalie de pose/anomalie de fabrication
      def create_rebouclage(options = {})
        connect_business do |client, _status|
          res = client.call(:ip_b_create_rebouclage,
                            message_tag: 'IpBCreateRebouclageRequest',
                            response_parser: :nokogiri,
                            message: {
                              'sch:JetonAuthentification' => @token,
                              'sch:Exploitation' => {
                                'sch:CodePays' => options[:farm_country_code],
                                'sch:NumeroExploitation' => options[:farm_number]
                              },
                              'sch:Bovin' => {
                                'sch:CodePays' => options[:animal_country_code],
                                'sch:NumeroNational' => options[:animal_id]
                              },
                              'sch:Rebouclage' => {
                                'sch:BoucleConventionnelle' => {
                                  'sch:BoucleTravail' => options[:boucle_travail]
                                },
                                'sch:BoucleElectronique' => options[:reference_pinces]
                              }.reject { |_, v| v.nil? },
                              'sch:CauseRemplacement' => options[:cause_remplacement]
                            }.reject { |_, v| v.nil? })

          doc = Nokogiri::XML(res.body[:ip_b_create_rebouclage_response].to_xml)

          result = doc.at_xpath('//resultat/child::text()').to_s
          err = doc.at_xpath('//anomalie')

          # error level 1 : hard error
          if result == 'false' && err

            code = err.at_xpath('//code/child::text()').to_s
            message = err.at_xpath('//message/child::text()').to_s
            fail ::Tele::Idele::Ednotif::Errors::ParsingError.new(code: code, message: message)

          # error level 2: could be sweet error or info notice
          elsif result == 'true' && err
            code = err.at_xpath('//code/child::text()').to_s
            message = err.at_xpath('//message/child::text()').to_s
            fail ::Tele::Idele::Ednotif::Errors::ParsingError.new(code: code, message: message)

          # everything is good
          elsif result == 'true'
            status = 'validated'
          end
        end
      end

      ##
      # create_insemination: permet de notifier une insémination réalisée par l’éleveur (IPE).
      # @param [string] token: token from reswel, length: 50
      # @param [string] farm_country_code: Toujours 'FR'. length: 2
      # @param [string] farm_number: Numéro d'exploitation française. length: 8
      # @param [string] female_animal_country_code: Code Pays UE. length: 2
      # @param [string] female_animal_id: Numéro national du bovin. max length: 12
      # @param [date] insemination_date: Date d'insémination
      # @param [string] bull_animal_country_code: Code Pays. length: 2
      # @param [string] bull_animal_id: Numéro national du bovin. max length: 12
      # @param [boolean] public: Monte publique
      # @param [boolean] collect: Insémination réalisée pour collecte embryon
      # @param [string] insemination: Mode d'insémination. length: 1 (F/C) F=Fraiche, C=Congelé
      # @param [Boolean] traitement_hormonal: Traitement hormonal prescrit à la femelle
      # @param [string] paillette_fractionnee: Nature de la paillette utilisée. length: 1 (1/2/B/D/M/P/Q/T)1: non fractionnée, 2: fractionnée, B: double dose, D: demi, M: morceau, P: entière, Q: Quart, T: tiers
      # @param [string] reference_paillette: Référence de la paillette. length: 2
      # @param [string] semence_sexee: Nature du sexage de la paillette. length: 2 (0/1/2) 0: non sexée, 1: sexée mâle, 2: sexée femelle
      private def create_insemination(token, farm_country_code, farm_number, female_animal_country_code, female_animal_id, insemination_date, bull_animal_country_code, bull_animal_id, public, collect, insemination, traitement_hormonal, paillette_fractionnee, reference_paillette, semence_sexee)
        { jeton_authentification: token, exploitation: { code_pays: farm_country_code, numero_exploitation: farm_number }, femelle: { code_pays: female_animal_country_code, numero_national: female_animal_id }, date_insemination: insemination_date, taureau: { code_pays: bull_animal_country_code, numero_national: bull_animal_id }, monte_publique: public, pour_collecte_embryon: collect, mode_insemination: insemination, traitement_hormonal: traitement_hormonal, paillette_fractionnee: paillette_fractionnee, reference_paillette: reference_paillette, semence_sexee: semence_sexee }
        # TODO
      end

      ##
      # get_presumed_exit: permet de fournir les sorties présumées d'un bovin d'une exploitation.
      # @param [string] token: token from reswel, length: 50
      # @param [string] farm_country_code: Toujours 'FR'. length: 2
      # @param [string] farm_number: Numéro d'exploitation française. length: 8
      def get_presumed_exit(options = {})
        connect_business do |client, _status|
          res = client.call(:ip_b_get_sorties_presumees,
                            message_tag: 'IpBGetSortiesPresumeesRequest',
                            response_parser: :nokogiri,
                            message: {
                              'sch:JetonAuthentification' => @token,
                              'sch:Exploitation' => {
                                'sch:CodePays' => options[:farm_country_code],
                                'sch:NumeroExploitation' => options[:farm_number]
                              }
                            }.reject { |_, v| v.nil? })

          doc = Nokogiri::XML(res.body[:ip_b_get_sorties_presumees_response].to_xml)

          result = doc.at_xpath('//resultat/child::text()').to_s
          err = doc.at_xpath('//anomalie')

          # error level 1 : hard error
          if result == 'false' && err

            code = err.at_xpath('//code/child::text()').to_s
            message = err.at_xpath('//message/child::text()').to_s
            fail ::Tele::Idele::Ednotif::Errors::ParsingError.new(code: code, message: message)

          # error level 2: could be sweet error or info notice
          elsif result == 'true' && err
            code = err.at_xpath('//code/child::text()').to_s
            message = err.at_xpath('//message/child::text()').to_s
            fail ::Tele::Idele::Ednotif::Errors::ParsingError.new(code: code, message: message)

          # everything is good
          elsif result == 'true'

            status = false

            unless doc.at_xpath('//nb-bovins').nil?
              status = 'validated'
              message_zip = doc.at_xpath('//message-zip/child::text()').to_s
              { output_hash: self.class.decode_zip(message_zip) }
            end

          end
        end
      end

      class << self
        def decode_zip(_base64_zip)
          stream = ::Base64.decode64(message_zip)
          data = nil
          Zip::File.open_buffer(stream) do |f|
            f.each do |entry|
              xml = Nokogiri::XML(entry.get_input_stream.read)
              data = Hash.from_xml(xml.to_s)
            end
          end
          data
        end
      end

      protected

      def call(call_options = {}, options = {}, &_block)
        connect(options) do |client|
          result = client.call(call_options)
          status = :undefined
          yield result, status
        end
        status
      end

      def connect_business(options = {}, &_block)
        status = true
        connect({ wdsl: @business_wsdl, namespaces: { 'xmlns:sch' => 'http://www.idele.fr/XML/Schema/' }, namespace_identifier: 'sch' }.merge(options)) do |client|
          results = yield(client, status) || {}
        end
        results.merge(status: status)
      end

      # Connect to given SOAP service and provides client to call it
      def connect(options = {}, &_block)
        fail 'No WSDL given' unless options[:wsdl]
        options[:convert_request_keys_to] ||= :camelcase
        options[:log] ||= true
        options[:env_namespace] ||= :soapenv
        # options[:namespace_identifier] ||= 'sch'
        # options[:namespaces] ||=  {'xmlns:sch' => 'http://www.idele.fr/XML/Schema/'}
        options[:ssl_verify_mode] ||= :none
        options[:open_timeout] ||= 15
        options[:read_timeout] ||= 15

        results = nil

        begin
          client = Savon.client(options)

          results = yield client

        rescue Savon::Error => error
          raise ::Tele::Idele::Ednotif::Errors::SOAPError.new(code: error.to_hash[:fault][:faultcode].to_s, message: error.to_hash[:fault][:faultstring].to_s)
        rescue Curl::Err::CurlError => error
          raise ::Tele::Idele::Ednotif::Errors::CurlError.new(message: error.to_s)
        rescue Nokogiri::XML::SyntaxError => error
          raise ::Tele::Idele::Ednotif::Errors::NokogiriError.new(message: error.to_s)
        end
        results
      end
    end
  end
end
