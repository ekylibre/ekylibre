module Tele
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
    # create_cattle_entrance: Notifier l'entrée d'un bovin sur une exploitation française
    # @param [string] token: token from reswel, length: 50
    # @param [string] farm_country_code: Toujours 'FR'. length: 2
    # @param [string] farm_number: Numéro d'exploitation française. length: 8
    # @param [string] animal_country_code: Code Pays UE. length: 2
    # @param [string] animal_id: Numéro national du bovin. max length: 12
    # @param [date] entry_date: Date entrée du bovin
    # @param [string] entry_reason: Cause d'entrée. (A/P) A=Achat, P=Prêt, pension
    # @param [string] src_country_code: Code pays de l'exploitation de provenance. length: 2
    # @param [string] src_farm_number: Numéro d'exploitation de provenance. length: 12
    # @param [string] src_owner_name: Nom du détenteur. max length: 60
    # @param [string] prod_code: Le code atelier, du type AtelierBovinIPG(cf p18). length: 2
    # @param [string] cattle_categ_code: Le code catégorie du bovin (cf p18). length: 2
    private def create_cattle_entrance( token, farm_country_code, farm_number, animal_country_code, animal_id, entry_date, entry_reason, src_country_code, src_farm_number, src_owner_name, prod_code, cattle_categ_code  )

      { jeton_authentification: token, exploitation: { code_pays: farm_country_code, numero_exploitation: farm_number}, bovin: { code_pays: animal_country_code, numero_national: animal_id }, date_entree: entry_date, cause_entree: entry_reason, exploitation_provenance: { exploitation: { code_pays: src_country_code, numero_exploitation: src_farm_number }, nom_exploitation: src_owner_name }, code_atelier: prod_code, code_categorie_bovin: cattle_categ_code}

              #TODO
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
    private def create_cattle_exit( token, farm_country_code, farm_number, animal_country_code, animal_id, exit_date, exit_reason, dest_country_code, dest_farm_number, dest_owner_name )

      { jeton_authentification: token, exploitation: { code_pays: farm_country_code, numero_exploitation: farm_number}, bovin: { code_pays: animal_country_code, numero_national: animal_id }, date_sortie: exit_date, cause_sortie: exit_reason, exploitation_destination: { exploitation: { code_pays: dest_country_code, numero_exploitation: dest_farm_number }, nom_exploitation: dest_owner_name }}

              #TODO
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
    private def create_cattle_new_birth( token, farm_country_code, farm_number, animal_country_code, animal_id, sex, race_code, birth_date, work_number, cattle_name, transplant, abortion, twin, birth_condition, birth_weight, weighed, bust_size, mother_animal_country_code, mother_animal_id, mother_race_code, father_animal_country_code, father_animal_id, father_race_code, passport_ask, prod_code )

      { jeton_authentification: token, exploitation_naissance: { code_pays: farm_country_code, numero_exploitation: farm_number}, bovin: { code_pays: animal_country_code, numero_national: animal_id }, sexe: sex, type_racial: race_code, date_naissance: birth_date, numero_travail: work_number, nom_bovin: cattle_name, filiation: { transplantation_embryonnaire: transplant, avortement: abortion, jumeau: twin, condition_naissance: birth_condition, poids: '', attributes!: { poids: { poids_naissance: birth_weight, poids_pesee: weighed }}, tour_poitrine: bust_size }, mere_porteuse: { bovin: { code_pays: mother_animal_country_code, numero_national: mother_animal_id }, type_racial: mother_race_code }, pere_ipg: { bovin: { code_pays: father_animal_country_code, numero_national: father_animal_id }, type_racial: father_race_code }, demande_passeport: passport_ask, code_atelier: prod_code }
              #TODO
    end

    ##
    # create_stillbirth: Notifier la naissance d'un bovin mort-né non bouclé sur une exploitation française
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
    private def create_stillbirth( token, farm_country_code, farm_number, sex, race_code, birth_date, cattle_name, transplant, abortion, twin, birth_condition, birth_weight, weighed, bust_size, mother_animal_country_code, mother_animal_id, mother_race_code, father_animal_country_code, father_animal_id, father_race_code)

      { jeton_authentification: token, exploitation_naissance: { code_pays: farm_country_code, numero_exploitation: farm_number}, sexe: sex, type_racial: race_code, date_naissance: birth_date, nom_bovin: cattle_name, filiation: { transplantation_embryonnaire: transplant, avortement: abortion, jumeau: twin, condition_naissance: birth_condition, poids: '', attributes!: { poids: { poids_naissance: birth_weight, poids_pesee: weighed }}, tour_poitrine: bust_size }, mere_porteuse: { bovin: { code_pays: mother_animal_country_code, numero_national: mother_animal_id }, type_racial: mother_race_code }, pere_ipg: { bovin: { code_pays: father_animal_country_code, numero_national: father_animal_id }, type_racial: father_race_code } }
              #TODO
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
    private def create_switched_animal( token, farm_number, animal_country_code, animal_id, sex, race_code, birth_date, witness, work_number, cattle_name, status, mother_animal_country_code, mother_animal_id, mother_race_code, father_animal_country_code, father_animal_id, father_race_code, birth_farm_country_code, birth_farm_number, entry_date, entry_reason, src_country_code, src_farm_number, src_owner_name, prod_code, cattle_categ_code )

      { jeton_authentification: token, exploitation_notification: farm_number, bovin: { code_pays: animal_country_code, numero_national: animal_id }, sexe: sex, type_racial: race_code, date_naissance: '', attributes!: { date_naissance: {date: birth_date, temoin_completude: witness }}, numero_travail: work_number, nom_bovin: cattle_name, statut_filie: status, mere_porteuse: { bovin: { code_pays: mother_animal_country_code, numero_national: mother_animal_id }, type_racial: mother_race_code }, pere_ipg: { bovin: { code_pays: father_animal_country_code, numero_national: father_animal_id }, type_racial: father_race_code }, exploitation_naissance: { code_pays: birth_farm_country_code, numero_exploitation: birth_farm_number }, date_entree: entry_date, cause_entree: entry_reason, exploitation_provenance: { exploitation: { code_pays: src_country_code, numero_exploitation: src_farm_number }, nom_exploitation: src_owner_name }, code_atelier: prod_code, code_categorie_bovin: cattle_categ_code  }
              #TODO
    end

    ##
    # create_imported_animal_notice: prévenir le MOIPG qu’un animal importé (né hors Union Européenne) est entré sur l’exploitation et qu’un rebouclage selon la réglementation française est nécessaire.
    # @param [string] token: token from reswel, length: 50
    # @param [string] farm_country_code: Toujours 'FR'. length: 2
    # @param [string] farm_number: Numéro d'exploitation française. length: 8
    # @param [string] src_animal_country_code: Code pays d'origine du bovin. length: 2
    # @param [string] src_animal_id: Numéro national d'origine du bovin. max length: 12
    private def create_imported_animal_notice( token, farm_country_code, farm_number, src_animal_country_code, src_animal_id )

      { jeton_authentification: token, exploitation: { code_pays: farm_country_code, numero_exploitation: farm_number }, bovin: { code_pays_origine_bovin: src_animal_country_code, numero_origine_bovin: src_animal_id } }
              #TODO
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
    # @param [string] src_country_code: Code pays de l'exploitation de provenance. length: 2
    # @param [string] src_farm_number: Numéro d'exploitation de provenance. length: 12
    # @param [string] src_owner_name: Nom du détenteur. max length: 60
    # @param [string] prod_code: Le type d'atelier du type AtelierBovinIPG. length: 2
    # @param [string] cattle_categ_code: Le code catégorie du bovin. length: 2
    private def create_imported_animal( token, farm_number, animal_country_code, animal_id, sex, race_code, birth_date, witness, work_number, cattle_name, status, mother_animal_country_code, mother_animal_id, mother_race_code, father_animal_country_code, father_animal_id, father_race_code, birth_farm_country_code, birth_farm_number, src_animal_country_code, src_animal_id, entry_date, entry_reason, src_country_code, src_farm_number, src_owner_name, prod_code, cattle_categ_code )

      { jeton_authentification: token, exploitation_notification: farm_number, bovin: { code_pays: animal_country_code, numero_national: animal_id }, sexe: sex, type_racial: race_code, date_naissance: '', attributes!: { date_naissance: { date: birth_date, temoin_completude: witness } }, numero_travail: work_number, nom_bovin: cattle_name, statut_filie: status, mere_porteuse: { bovin: { code_pays: mother_animal_country_code, numero_national: mother_animal_id }, type_racial: mother_race_code }, pere_ipg: { bovin: { code_pays: father_animal_country_code, numero_national: father_animal_id }, type_racial: father_race_code }, exploitation_naissance: { code_pays: birth_farm_country_code, numero_exploitation: birth_farm_number }, code_pays_origine_bovin: src_animal_country_code, numero_origine_bovin: src_animal_id, date_entree: entry_date, cause_entree: entry_reason, exploitation_provenance: { exploitation: { code_pays: src_country_code, numero_exploitation: src_farm_number }, nom_exploitation: src_owner_name }, code_atelier: prod_code, code_categorie_bovin: cattle_categ_code  }
              #TODO
    end

    ##
    # get_cattle_list: fournir l’inventaire des bovins d’une exploitation entre deux dates. L’inventaire peut être complété par la liste des boucles disponibles.
    # @param [string] token: token from reswel, length: 50
    # @param [string] farm_country_code: Toujours 'FR'. length: 2
    # @param [string] farm_number: Numéro d'exploitation française. length: 8
    # @param [date] start_date: Date début de période de présence des bovins
    # @param [date] end_date: Date fin de période de présence des bovins
    # @param [Object] stock: Indique si le stock de boucles doit être retourné
    private def get_cattle_list( token, farm_country_code, farm_number, start_date, end_date, stock)

      { jeton_authentification: token, exploitation: { code_pays: farm_country_code, numero_exploitation: farm_number }, date_debut: start_date, date_fin: end_date, stock_boucles: stock}
              #TODO
    end

    ##
    # get_case_feedback: permet de fournir, pour une exploitation, les animaux ayant eu une modification d’identité ou de mouvement depuis la dernière demande effectuée
    # @param [string] farm_country_code: Toujours 'FR'. length: 2
    # @param [string] farm_number: Numéro d'exploitation française concernée par la demande de dossiers. length: 8
    # @param [date] start_date: Date début de fourniture des dossiers
    def get_case_feedback( token, farm_country_code, farm_number, start_date )

      { jeton_authentification: token, exploitation: { code_pays: farm_country_code, numero_exploitation: farm_number }, date_debut: start_date }
      #TODO
    end

    ##
    # get_animal_case: permet de fournir le dossier d’un bovin (identité et mouvements) concernant une exploitation.
    # @param [string] token: token from reswel, length: 50
    # @param [string] farm_country_code: Toujours 'FR'. length: 2
    # @param [string] farm_number: Numéro d'exploitation française. length: 8
    # @param [string] animal_country_code: Code Pays UE. length: 2
    # @param [string] animal_id: Numéro national du bovin. max length: 12
    private def get_animal_case( token, farm_country_code, farm_number, animal_country_code, animal_id )

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
    # @param [string] cause_remplacement: Motif de la commande de la boucle de rebouclage. length: 1 (C/E/I/L/P/X/Y/Z) Cassé/Electronisation/Illisible/électronique perdu/perdu/anomalie de commande/anomalie de pose/anomalie de fabrication
    private def create_rebouclage( token, farm_country_code, farm_number, animal_country_code, animal_id, boucle_conventionnelle, boucle_travail, boucle_electronique, cause_remplacement )

      { jeton_authentification: token, exploitation: { code_pays: farm_country_code, numero_exploitation: farm_number }, bovin: { code_pays: animal_country_code, numero_national: animal_id }, rebouclage: { boucle_conventionelle: boucle_conventionnelle, attributes!: { boucle_conventionelle: { boucle_travail: boucle_travail } }, boucle_electronique: boucle_electronique }, cause_remplacement: cause_remplacement }
              #TODO
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
    private def create_insemination( token, farm_country_code, farm_number, female_animal_country_code, female_animal_id, insemination_date, bull_animal_country_code, bull_animal_id, public, collect, insemination, traitement_hormonal, paillette_fractionnee, reference_paillette, semence_sexee )

      { jeton_authentification: token, exploitation: { code_pays: farm_country_code, numero_exploitation: farm_number }, femelle: { code_pays: female_animal_country_code, numero_national: female_animal_id }, date_insemination: insemination_date, taureau: { code_pays: bull_animal_country_code, numero_national: bull_animal_id }, monte_publique: public, pour_collecte_embryon: collect, mode_insemination: insemination, traitement_hormonal: traitement_hormonal, paillette_fractionnee: paillette_fractionnee, reference_paillette: reference_paillette, semence_sexee: semence_sexee }
              #TODO
    end

    ##
    # get_presumed_exit: permet de fournir les sorties présumées d'un bovin d'une exploitation.
    # @param [string] token: token from reswel, length: 50
    # @param [string] farm_country_code: Toujours 'FR'. length: 2
    # @param [string] farm_number: Numéro d'exploitation française. length: 8
    private def get_presumed_exit( token, farm_country_code, farm_number )

      { jeton_authentification: token, exploitation: { code_pays: farm_country_code, numero_exploitation: farm_number } }
              #TODO
    end

        end
end