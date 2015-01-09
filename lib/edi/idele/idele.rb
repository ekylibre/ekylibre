module Edi
  module Idele

    ###### LOW-LEVEL SOAP API #########

    ## TIPS
    # wsd = directory web service
    # wsb = business web service
    # wsc = customs web service

    # @param [string] wsd_wsdl: Url of directory web service wsdl
    # @param [string] company_code: Company to be contacted
    # @param [string] geo: Geographical space
    # @param [string] app_name: Name of App
    # @param [string] wsb_version: wsBusiness version number
    # @param [string] wsb_site_version: wsBusiness site version
    # @param [string] wsb_service_name: wsBusiness service name (only IpBNotif now)
    # @param [string] wsb_service_code: wsBusiness service code
    # @param [string] user_id: user id
    # @param [string] user_password: user password
    def initialize(wsd_wsdl, company_code, geo,
                   app_name, wsb_version, wsb_site_version,
                   wsb_service_name, wsb_service_code, user_id, user_password)

      @wsd_wsdl = wsd_wsdl
      @company_code = company_code
      @geo = geo
      @app_name = app_name
      @wsb_version = wsb_version
      @wsb_site_version = wsb_site_version
      @wsb_service_name = wsb_service_name
      @wsb_service_code = wsb_service_code
      @user_id = user_id
      @user_password = user_password
      @token = nil
      @wsc_wsdl = nil
      @wsb_wsdl = nil
    end

    ##
    # Authenticate through Idele's webservices and fetch gained access token
    # return true if authentication succeeded and set @token

    private def authenticate

      success = false

      if @token.nil?

        if get_url

          if create_token
            #TODO
            success = false
          end

        end

      else

        #TODO: token could be set from previous operation
        success = true

      end

      return success

    end

    ##
    # Connect to wsAnnuaire and fetch wsGuichet and wsMetier wsdl urls
    # return true if wsdl retrieved and set @wsb_wsdl and @wsc_wsdl

    private def get_url
              #TODO
      success = false

      client = Savon.client do
        wsdl @wsd_wsdl
      end

      res = client.call(:tk_get_url) do
        message profil_demandeur: {entreprise: @company_code, zone: @geo, application: @app_name}, version_pk: {numero_version: @wsb_version, code_site_version: @wsb_site_version, nom_service: @wsb_service_name, code_site_service: @wsb_service_code}
      end

      doc = Nokogiri::XML(res.body[:tk_get_url_response])

      # error
      if doc.xpath('//Resultat') == false && doc.xpath('//Anomalie')
        #TODO

        # could be sweet error or info notice
      elsif doc.xpath('//Resultat') && doc.xpath('//Anomalie')
        #TODO

        # everything is good
      elsif doc.xpath('//Resultat')
        #TODO
        @wsb_wsdl = doc.xpath('//WsdlMetier')
        @wsc_wsdl = doc.xpath('//WsdlGuichet')
        success = true
      end

      return success
    end


    ##
    # Fetch access token and set @token
    # return true if token retrieved

    private def create_token

      success = false

      #TODO
      #@token =
      client = Savon.client do
        wsdl @wsc_wsdl
      end

      res = client.call(:tk_create_identification) do
        message profil: {entreprise: @company_code, zone: @geo, application: @app_name}, identification: {user_id: @user_id, password: @user_password}
      end

      doc = Nokogiri::XML(res.body[:tk_create_identification_response])


      if doc.xpath('//Jeton')
        #TODO
        @token = doc.xpath('//Jeton')
        success = true
      end

      return success

    end

    ##
    # create_entree: Notifier l'entrée d'un bovin sur une exploitation française
    # @param [string] token: token from reswel, length: 50
    # @param [string] farm_country_code: Toujours 'FR'. length: 2
    # @param [string] farm_number: Numéro d'exploitation française. length: 8
    # @param [string] animal_country_code: Code Pays UE. length: 2
    # @param [string] animal_id: Numéro national du bovin. max length: 12
    # @param [date] entry_date: Date entrée du bovin
    # @param [string] entry_reason: Cause d'entrée. (A/P)
    # @param [string] src_country_code: Code pays de l'exploitation de provenance. length: 2
    # @param [string] src_farm_number: Numéro d'exploitation de provenance. length: 12
    # @param [string] src_owner_name: Nom du détenteur. max length: 60
    # @param [string] prod_code: Le code atelier, du type AtelierBovinIPG(cf p18). length: 2
    # @param [string] cattle_categ_code: Le code catégorie du bovin (cf p18). length: 2
    private def create_entree( token, farm_country_code, farm_number, animal_country_code, animal_id, entry_date, entry_reason, src_country_code, src_farm_number, src_owner_name, prod_code, cattle_categ_code  )

      { jeton_authentification: token, exploitation: { code_pays: farm_country_code, numero_exploitation: farm_number}, bovin: { code_pays: animal_country_code, numero_national: animal_id }, date_entree: entry_date, cause_entree: entry_reason, exploitation_provenance: { exploitation: { code_pays: src_country_code, numero_exploitation: src_farm_number }, nom_exploitation: src_owner_name }, code_atelier: prod_code, code_categorie_bovin: cattle_categ_code}

              #TODO
    end



    ##
    # create_sortie: Notifier la sortie d'un bovin d'une exploitation française
    # @param [string] token: token from reswel, length: 50
    # @param [string] farm_country_code: Toujours 'FR'. length: 2
    # @param [string] farm_number: Numéro d'exploitation française. length: 8
    # @param [string] animal_country_code: Code Pays UE. length: 2
    # @param [string] animal_id: Numéro national du bovin. max length: 12
    # @param [date] exit_date: Date de sortie du bovin
    # @param [string] exit_reason: Cause de sortie. (B/C/E/H/M)
    # @param [string] dest_country_code: Code pays de l'exploitation de destination. length: 2
    # @param [string] dest_farm_number: Numéro d'exploitation de destination. length: 12
    # @param [string] dest_owner_name: Nom du détenteur. max length: 60
    private def create_sortie( token, farm_country_code, farm_number, animal_country_code, animal_id, exit_date, exit_reason, dest_country_code, dest_farm_number, dest_owner_name )

      { jeton_authentification: token, exploitation: { code_pays: farm_country_code, numero_exploitation: farm_number}, bovin: { code_pays: animal_country_code, numero_national: animal_id }, date_sortie: exit_date, cause_sortie: exit_reason, exploitation_destination: { exploitation: { code_pays: dest_country_code, numero_exploitation: dest_farm_number }, nom_exploitation: dest_owner_name }}

              #TODO
    end


    ##
    # create_naissance: Notifier la naissance d'un bovin sur une exploitation française
    # @param [string] token: token from reswel, length: 50
    # @param [string] farm_country_code: Toujours 'FR'. length: 2
    # @param [string] farm_number: Numéro d'exploitation française. length: 8
    # @param [string] animal_country_code: Code Pays UE. length: 2
    # @param [string] animal_id: Numéro national du bovin. max length: 12
    # @param [string] sexe: Sexe du bovin: length: 1
    # @param [string] type_racial: Type racial . length: 2
    # @param [date] date_naissance: Date de Naissance
    # @param [number] numero_travail: Numéro de travail de bovin. length: 4
    # @param [string] nom_bovin: Nom du bovin.
    # @param [Boolean] transplant: Si l'animal est issu d'une transplantation embryonnaire
    # @param [Boolean] avortement:
    # @param [Boolean] jumeau: Si l'animal est issu d'une naissance gémélaire
    # @param [string] condition_naissance: Condition de naissance du bovin. (cf p95)
    # @param [int] poids_naissance: Poids de naissance du bovin. (1-99)
    # @param [Boolean] poids_pesee: Si le bovin a été pesé pour déterminer son poids
    # @param [int] tour_poitrine: Tour de poitrine en cm. max length: 3
    # @param [string] mother_animal_country_code: Code Pays de la mère porteuse. length: 2
    # @param [string] mother_animal_id: Numéro national de la mère porteuse. max length: 12
    # @param [string] mother_type_racial: Type racial de la mère porteuse . length: 2
    # @param [string] father_animal_country_code: Code Pays du père IPG. length: 2
    # @param [string] father_animal_id: Numéro national du père IPG. max length: 12
    # @param [string] father_type_racial: Type racial du père IPG . length: 2
    # @param [Boolean] demande_passeport: Indique si une demande d'édition du passeport en urgence
    # @param [Object] code_atelier: Le type d'atelier du type AtelierBovinIPG. length: 2
    private def create_naissance( token, farm_country_code, farm_number, animal_country_code, animal_id, sexe, type_racial, date_naissance, numero_travail, nom_bovin, transplant, avortement, jumeau, condition_naissance, poids_naissance, poids_pesee, tour_poitrine, mother_animal_country_code, mother_animal_id, mother_type_racial, father_animal_country_code, father_animal_id, father_type_racial, demande_passeport, code_atelier )

      { jeton_authentification: token, exploitation_naissance: { code_pays: farm_country_code, numero_exploitation: farm_number}, bovin: { code_pays: animal_country_code, numero_national: animal_id }, sexe: sexe, type_racial: type_racial, date_naissance: date_naissance, numero_travail: numero_travail, nom_bovin: nom_bovin, filiation: { transplantation_embryonnaire: transplant, avortement: avortement, jumeau: jumeau, condition_naissance: condition_naissance, poids: '', attributes!: { poids: { poids_naissance: poids_naissance, poids_pesee: poids_pesee }}, tour_poitrine: tour_poitrine }, mere_porteuse: { bovin: { code_pays: mother_animal_country_code, numero_national: mother_animal_id }, type_racial: mother_type_racial }, pere_ipg: { bovin: { code_pays: father_animal_country_code, numero_national: father_animal_id }, type_racial: father_type_racial }, demande_passeport: demande_passeport, code_atelier: code_atelier }
              #TODO
    end

    ##
    # create_mort_ne: Notifier la naissance d'un bovin mort-né non bouclé sur une exploitation française
    # @param [string] token: token from reswel, length: 50
    # @param [string] farm_country_code: Toujours 'FR'. length: 2
    # @param [string] farm_number: Numéro d'exploitation française. length: 8
    # @param [string] sexe: Sexe du bovin: length: 1
    # @param [string] type_racial: Type racial . length: 2
    # @param [date] date_naissance: Date de Naissance
    # @param [string] nom_bovin: Nom du bovin.
    # @param [Boolean] transplant: Si l'animal est issu d'une transplantation embryonnaire
    # @param [Boolean] avortement:
    # @param [Boolean] jumeau: Si l'animal est issu d'une naissance gémélaire
    # @param [string] condition_naissance: Condition de naissance du bovin. (cf p95)
    # @param [int] poids_naissance: Poids de naissance du bovin. (1-99)
    # @param [Boolean] poids_pesee: Si le bovin a été pesé pour déterminer son poids
    # @param [int] tour_poitrine: Tour de poitrine en cm. max length: 3
    # @param [string] mother_animal_country_code: Code Pays de la mère porteuse. length: 2
    # @param [string] mother_animal_id: Numéro national de la mère porteuse. max length: 12
    # @param [string] mother_type_racial: Type racial de la mère porteuse . length: 2
    # @param [string] father_animal_country_code: Code Pays du père IPG. length: 2
    # @param [string] father_animal_id: Numéro national du père IPG. max length: 12
    # @param [string] father_type_racial: Type racial du père IPG . length: 2
    private def create_mort_ne( token, farm_country_code, farm_number, sexe, type_racial, date_naissance, nom_bovin, transplant, avortement, jumeau, condition_naissance, poids_naissance, poids_pesee, tour_poitrine, mother_animal_country_code, mother_animal_id, mother_type_racial, father_animal_country_code, father_animal_id, father_type_racial)

      { jeton_authentification: token, exploitation_naissance: { code_pays: farm_country_code, numero_exploitation: farm_number}, sexe: sexe, type_racial: type_racial, date_naissance: date_naissance, nom_bovin: nom_bovin, filiation: { transplantation_embryonnaire: transplant, avortement: avortement, jumeau: jumeau, condition_naissance: condition_naissance, poids: '', attributes!: { poids: { poids_naissance: poids_naissance, poids_pesee: poids_pesee }}, tour_poitrine: tour_poitrine }, mere_porteuse: { bovin: { code_pays: mother_animal_country_code, numero_national: mother_animal_id }, type_racial: mother_type_racial }, pere_ipg: { bovin: { code_pays: father_animal_country_code, numero_national: father_animal_id }, type_racial: father_type_racial } }
              #TODO
    end

    ##
    # create_animal_echange: notifier la première entrée en France d’un bovin échangé (né dans l’Union Européenne) sur une exploitation française
    # @param [string] token: token from reswel, length: 50
    # @param [string] farm_number: Numéro d'exploitation française. length: 8
    # @param [string] animal_country_code: Code Pays UE. length: 2
    # @param [string] animal_id: Numéro national du bovin. max length: 12
    # @param [string] sexe: Sexe du bovin: length: 1
    # @param [string] type_racial: Type racial . length: 2
    # @param [date] date_naissance: Date de Naissance
    # @param [string] temoin_completude: Témoin de complétude
    # @param [number] numero_travail: Numéro de travail de bovin. length: 4
    # @param [string] nom_bovin: Nom du bovin.
    # @param [Boolean] statut_filie: Indique si l'animal est filié (CPB)
    # @param [string] mother_animal_country_code: Code Pays de la mère porteuse. length: 2
    # @param [string] mother_animal_id: Numéro national de la mère porteuse. max length: 12
    # @param [string] mother_type_racial: Type racial de la mère porteuse . length: 2
    # @param [string] father_animal_country_code: Code Pays du père IPG. length: 2
    # @param [string] father_animal_id: Numéro national du père IPG. max length: 12
    # @param [string] father_type_racial: Type racial du père IPG . length: 2
    # @param [string] born_farm_country_code: Code pays de l'exploitation de naissance. length: 2
    # @param [string] born_farm_number: Numéro d'exploitation de naissance. length: 12
    # @param [string] entry_date: Date entrée du bovin
    # @param [string] entry_reason: Cause d'entrée. (A/P)
    # @param [string] src_country_code: Code pays de l'exploitation de provenance. length: 2
    # @param [string] src_farm_number: Numéro d'exploitation de provenance. length: 12
    # @param [string] src_owner_name: Nom du détenteur. max length: 60
    # @param [string] code_atelier: Le type d'atelier du type AtelierBovinIPG. length: 2
    # @param [string] cattle_categ_code: Le code catégorie du bovin. length: 2
    private def create_animal_echange( token, farm_number, animal_country_code, animal_id, sexe, type_racial, date_naissance, temoin_completude, numero_travail, nom_bovin, statut_filie, mother_animal_country_code, mother_animal_id, mother_type_racial, father_animal_country_code, father_animal_id, father_type_racial, born_farm_country_code, born_farm_number, entry_date, entry_reason, src_country_code, src_farm_number, src_owner_name, code_atelier, cattle_categ_code )

      { jeton_authentification: token, exploitation_notification: farm_number, bovin: { code_pays: animal_country_code, numero_national: animal_id }, sexe: sexe, type_racial: type_racial, date_naissance: '', attributes!: { date_naissance: {date: date_naissance, temoin_completude: temoin_completude }}, numero_travail: numero_travail, nom_bovin: nom_bovin, statut_filie: statut_filie, mere_porteuse: { bovin: { code_pays: mother_animal_country_code, numero_national: mother_animal_id }, type_racial: mother_type_racial }, pere_ipg: { bovin: { code_pays: father_animal_country_code, numero_national: father_animal_id }, type_racial: father_type_racial }, exploitation_naissance: { code_pays: born_farm_country_code, numero_exploitation: born_farm_number }, date_entree: entry_date, cause_entree: entry_reason, exploitation_provenance: { exploitation: { code_pays: src_country_code, numero_exploitation: src_farm_number }, nom_exploitation: src_owner_name }, code_atelier: code_atelier, code_categorie_bovin: cattle_categ_code  }
              #TODO
    end

    ##
    # create_avis_animal_importe: prévenir le MOIPG qu’un animal importé (né hors Union Européenne) est entré sur l’exploitation et qu’un rebouclage selon la réglementation française est nécessaire.
    # @param [string] token: token from reswel, length: 50
    # @param [string] farm_country_code: Toujours 'FR'. length: 2
    # @param [string] farm_number: Numéro d'exploitation française. length: 8
    # @param [string] src_animal_country_code: Code pays d'origine du bovin. length: 2
    # @param [string] src_animal_id: Numéro national d'origine du bovin. max length: 12
    private def create_avis_animal_importe( token, farm_country_code, farm_number, src_animal_country_code, src_animal_id )

      { jeton_authentification: token, exploitation: { code_pays: farm_country_code, numero_exploitation: farm_number }, bovin: { code_pays_origine_bovin: src_animal_country_code, numero_origine_bovin: src_animal_id } }
              #TODO
    end

    ##
    # create_animal_importe: notifier la première entrée en France d’un bovin importé (né hors Union Européenne) sur une exploitation française.
    # @param [string] token: token from reswel, length: 50
    # @param [string] farm_number: Numéro d'exploitation française. length: 8
    # @param [string] animal_country_code: Code Pays UE. length: 2
    # @param [string] animal_id: Numéro national du bovin. max length: 12
    # @param [string] sexe: Sexe du bovin: length: 1
    # @param [string] type_racial: Type racial . length: 2
    # @param [date] date_naissance: Date de Naissance
    # @param [string] temoin_completude: Témoin de complétude
    # @param [number] numero_travail: Numéro de travail de bovin. length: 4
    # @param [string] nom_bovin: Nom du bovin.
    # @param [Boolean] statut_filie: Indique si l'animal est filié (CPB)
    # @param [string] mother_animal_country_code: Code Pays de la mère porteuse. length: 2
    # @param [string] mother_animal_id: Numéro national de la mère porteuse. max length: 12
    # @param [string] mother_type_racial: Type racial de la mère porteuse . length: 2
    # @param [string] father_animal_country_code: Code Pays du père IPG. length: 2
    # @param [string] father_animal_id: Numéro national du père IPG. max length: 12
    # @param [string] father_type_racial: Type racial du père IPG . length: 2
    # @param [string] born_farm_country_code: Code pays de l'exploitation de naissance. length: 2
    # @param [string] born_farm_number: Numéro d'exploitation de naissance. length: 12
    # @param [string] src_animal_country_code: Code pays d'origine du bovin. length: 2
    # @param [string] src_animal_id: Numéro national d'origine du bovin. max length: 12
    # @param [string] entry_date: Date entrée du bovin
    # @param [string] entry_reason: Cause d'entrée. (A/P)
    # @param [string] src_country_code: Code pays de l'exploitation de provenance. length: 2
    # @param [string] src_farm_number: Numéro d'exploitation de provenance. length: 12
    # @param [string] src_owner_name: Nom du détenteur. max length: 60
    # @param [string] code_atelier: Le type d'atelier du type AtelierBovinIPG. length: 2
    # @param [string] cattle_categ_code: Le code catégorie du bovin. length: 2
    private def create_animal_importe( token, farm_number, animal_country_code, animal_id, sexe, type_racial, date_naissance, temoin_completude, numero_travail, nom_bovin, statut_filie, mother_animal_country_code, mother_animal_id, mother_type_racial, father_animal_country_code, father_animal_id, father_type_racial, born_farm_country_code, born_farm_number, src_animal_country_code, src_animal_id, entry_date, entry_reason, src_country_code, src_farm_number, src_owner_name, code_atelier, cattle_categ_code )

      { jeton_authentification: token, exploitation_notification: farm_number, bovin: { code_pays: animal_country_code, numero_national: animal_id }, sexe: sexe, type_racial: type_racial, date_naissance: '', attributes!: { date_naissance: { date: date_naissance, temoin_completude: temoin_completude } }, numero_travail: numero_travail, nom_bovin: nom_bovin, statut_filie: statut_filie, mere_porteuse: { bovin: { code_pays: mother_animal_country_code, numero_national: mother_animal_id }, type_racial: mother_type_racial }, pere_ipg: { bovin: { code_pays: father_animal_country_code, numero_national: father_animal_id }, type_racial: father_type_racial }, exploitation_naissance: { code_pays: born_farm_country_code, numero_exploitation: born_farm_number }, code_pays_origine_bovin: src_animal_country_code, numero_origine_bovin: src_animal_id, date_entree: entry_date, cause_entree: entry_reason, exploitation_provenance: { exploitation: { code_pays: src_country_code, numero_exploitation: src_farm_number }, nom_exploitation: src_owner_name }, code_atelier: code_atelier, code_categorie_bovin: cattle_categ_code  }
              #TODO
    end

    ##
    # get_inventaire: fournir l’inventaire des bovins d’une exploitation entre deux dates. L’inventaire peut être complété par la liste des boucles disponibles.
    # @param [string] token: token from reswel, length: 50
    # @param [string] farm_country_code: Toujours 'FR'. length: 2
    # @param [string] farm_number: Numéro d'exploitation française. length: 8
    # @param [date] start_date: Date début de période de présence des bovins
    # @param [date] end_date: Date fin de période de présence des bovins
    # @param [Object] stock: Indique si le stock de boucles doit être retourné
    private def get_inventaire( token, farm_country_code, farm_number, start_date, end_date, stock)

      { jeton_authentification: token, exploitation: { code_pays: farm_country_code, numero_exploitation: farm_number }, date_debut: start_date, date_fin: end_date, stock_boucles: stock}
              #TODO
    end

    ##
    #  get_retour_dossiers: permet de fournir, pour une exploitation, les animaux ayant eu une modification d’identité ou de mouvement depuis la dernière demande effectuée
    # @param [string] farm_country_code: Toujours 'FR'. length: 2
    # @param [string] farm_number: Numéro d'exploitation française concernée par la demande de dossiers. length: 8
    # @param [date] start_date: Date début de fourniture des dossiers
    def get_retour_dossiers( farm_country_code, farm_number, start_date )

      { jeton_authentification: token, exploitation: { code_pays: farm_country_code, numero_exploitation: farm_number }, date_debut: start_date }
      #TODO
    end

    ##
    # get_dossier_animal: permet de fournir le dossier d’un bovin (identité et mouvements) concernant une exploitation.
    # @param [string] token: token from reswel, length: 50
    # @param [string] farm_country_code: Toujours 'FR'. length: 2
    # @param [string] farm_number: Numéro d'exploitation française. length: 8
    # @param [string] animal_country_code: Code Pays UE. length: 2
    # @param [string] animal_id: Numéro national du bovin. max length: 12
    private def get_dossier_animal( token, farm_country_code, farm_number, animal_country_code, animal_id )

      { jeton_authentification: token, exploitation: { code_pays: farm_country_code, numero_exploitation: farm_number }, bovin: { code_pays: animal_country_code, numero_national: animal_id } }
              #TODO
    end

    ##
    # create_commande_boucles: commander des boucles de naissance, des pinces et des pointeaux.
    # @param [string] token: token from reswel, length: 50
    # @param [string] farm_country_code: Toujours 'FR'. length: 2
    # @param [string] farm_number: Numéro d'exploitation française. length: 8
    # @param [integer] nb_paires_boucle: Nombre de paires de boucles à commander. max: 9999
    # @param [string] reference_boucles: Code produit des boucles commandées.
    # @param [integer] nb_pinces: Nombre de paires de pinces à commander. max: 9
    # @param [string] reference_pinces: Code produit des pinces commandées.
    # @param [integer] nb_pointeaux: Nombre de pointeaux à commander. max: 9
    # @param [string] reference_pointeaux: Code produit des pointeaux commandés.
    private def create_commande_boucles( token, farm_country_code, farm_number, nb_paires_boucle, reference_boucles, nb_pinces, reference_pinces, nb_pointeaux, reference_pointeaux)

      { jeton_authentification: token, exploitation_notification: { code_pays: farm_country_code, numero_exploitation: farm_number }, boucle: '', pince: '', pointeau: '', attributes!: { boucle: { nb_paires_boucles: nb_paires_boucle, reference_boucles: reference_boucles }, pince: { nb_pinces: nb_pinces, reference_pinces: reference_pinces }, pointeau: { nb_pointeaux: nb_pointeaux, reference_pointeaux: reference_pointeaux } } }
              #TODO
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
    private def create_rebouclage( token, farm_country_code, farm_number, animal_country_code, animal_id, boucle_conventionnelle, boucle_travail, boucle_electronique )

      { jeton_authentification: token, exploitation: { code_pays: farm_country_code, numero_exploitation: farm_number }, bovin: { code_pays: animal_country_code, numero_national: animal_id }, rebouclage: { boucle_conventionelle: boucle_conventionnelle, attributes!: { boucle_conventionelle: { boucle_travail: boucle_travail } }, boucle_electronique: boucle_electronique } }
              #TODO
    end

    ##
    # create_insemination: permet de notifier une insémination réalisée par l’éleveur (IPE).
    # @param [string] token: token from reswel, length: 50
    # @param [string] farm_country_code: Toujours 'FR'. length: 2
    # @param [string] farm_number: Numéro d'exploitation française. length: 8
    # @param [string] female_animal_country_code: Code Pays UE. length: 2
    # @param [string] female_animal_id: Numéro national du bovin. max length: 12
    # @param [date] date_insemination: Date d'insémination
    # @param [string] taureau_animal_country_code: Code Pays. length: 2
    # @param [string] taureau_animal_id: Numéro national du bovin. max length: 12
    # @param [boolean] monte_publique
    # @param [boolean] pour_collecte_embryon: Insémination réalisée pour collecte embryon
    # @param [string] mode_insemination: Mode d'insémination. length: 1 (F/C)
    # @param [Boolean] traitement_hormonal: Traitement hormonal prescrit à la femelle
    # @param [string] paillette_fractionnee: Nature de la paillette utilisée. length: 1
    # @param [Object] reference_paillette: Référence de la paillette. length: 2
    # @param [Object] semence_sexee: Nature du sexage de la paillette. length: 2
    private def create_insemination( token, farm_country_code, farm_number, female_animal_country_code, female_animal_id, date_insemination, taureau_animal_country_code, taureau_animal_id, monte_publique, pour_collecte_embryon, mode_insemination, traitement_hormonal, paillette_fractionnee, reference_paillette, semence_sexee )

      { jeton_authentification: token, exploitation: { code_pays: farm_country_code, numero_exploitation: farm_number }, femelle: { code_pays: female_animal_country_code, numero_national: female_animal_id }, date_insemination: date_insemination, taureau: { code_pays: taureau_animal_country_code, numero_national: taureau_animal_id }, monte_publique: monte_publique, pour_collecte_embryon: pour_collecte_embryon, mode_insemination: mode_insemination, traitement_hormonal: traitement_hormonal, paillette_fractionnee: paillette_fractionnee, reference_paillette: reference_paillette, semence_sexee: semence_sexee }
              #TODO
    end

        end
end