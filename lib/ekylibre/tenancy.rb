module Ekylibre
  # Contexte de ferme pour le mono-schéma (points 1.17 et 1.18 de la feuille de
  # route v6).
  #
  # C'est le pendant applicatif de la Row Level Security : la base refuse de
  # rendre quoi que ce soit tant que `app.tenant_id` n'est pas posé, et c'est
  # ici qu'il se pose. Rien de ce fichier n'est branché sur l'application tant
  # qu'Apartment est en place ; il vit à côté, et le prototype le met à
  # l'épreuve.
  #
  #   Ekylibre::Tenancy.with(tenant_id) { Product.count }
  #
  # Quatre précautions, toutes apprises en mesurant sur le prototype :
  #
  #   1. `SET LOCAL` porte sur la *transaction*, pas sur le bloc Ruby. Dans une
  #      transaction imbriquée — un savepoint — le réglage survit à la sortie du
  #      bloc et contamine la transaction englobante. On restaure donc soi-même
  #      la valeur précédente, ce qui rend au passage deux contextes
  #      imbricables ;
  #   2. le cache de requêtes de Rails est indexé sur le seul texte SQL : il
  #      ignore le tenant, et resservirait sous B une lecture faite sous A. On
  #      le vide de part et d'autre ;
  #   3. la sortie du bloc doit *toujours* rétablir l'état, y compris quand le
  #      bloc lève — d'où le `ensure` ;
  #   4. sans contexte, la base ne rend rien. C'est voulu : une requête qui
  #      s'échappe du contexte doit rendre zéro ligne, jamais celles d'autrui.
  module Tenancy
    SETTING = 'app.tenant_id'.freeze

    class MissingTenant < StandardError
      def initialize(message = 'Aucune ferme dans le contexte courant')
        super
      end
    end

    class Current < ActiveSupport::CurrentAttributes
      attribute :tenant_id
    end

    class << self
      def current
        Current.tenant_id
      end

      def current!
        current || raise(MissingTenant)
      end

      # Pose le contexte le temps du bloc, puis rétablit ce qu'il y avait avant.
      def with(tenant_id, &block)
        raise ArgumentError.new('tenant_id manquant') if tenant_id.blank?

        switch(tenant_id, &block)
      end

      # Le chemin explicite pour sortir de toute ferme : migrations, tâches
      # d'administration, requêtes inter-fermes du point 1.22. Il est nommé pour
      # être cherchable — un `grep without_tenant` doit lister tous les endroits
      # où l'isolation est volontairement mise de côté.
      def without_tenant(&block)
        switch(nil, &block)
      end

      private

        def switch(tenant_id, &block)
          previous = Current.tenant_id
          connection.clear_query_cache
          Current.tenant_id = tenant_id

          if connection.transaction_open?
            bounded(tenant_id, previous, &block)
          else
            # `SET LOCAL` hors transaction n'a aucun effet — PostgreSQL le dit
            # dans un avertissement. Une transaction porte donc le contexte, et
            # c'est elle qui le fait mourir à la sortie. C'est le choix le plus
            # sûr ; l'autre — poser le réglage sur la connexion et le nettoyer
            # à son retour au pool — évite des transactions longues mais confie
            # l'isolation à un `ensure` de plus.
            connection.transaction { bounded(tenant_id, previous, &block) }
          end
        ensure
          Current.tenant_id = previous
          connection.clear_query_cache
        end

        # Le réglage est rétabli à la main, et non laissé mourir avec la
        # transaction : dans un savepoint, il lui survivrait.
        def bounded(tenant_id, previous)
          apply(tenant_id)
          yield
        ensure
          apply(previous)
        end

        def apply(tenant_id)
          value = tenant_id.presence || ''
          connection.execute("SET LOCAL #{SETTING} = #{connection.quote(value)}")
        end

        def connection
          ApplicationRecord.connection
        end
    end
  end
end
