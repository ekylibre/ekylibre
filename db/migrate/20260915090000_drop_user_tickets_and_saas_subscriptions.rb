# Deux tables que plus rien ne sert (décision du 15 septembre 2026).
#
# `user_tickets` était déjà du code mort : aucune route ne menait à son
# contrôleur. `saas_subscriptions` portait un `tenant_name` — une ferme y
# désignait une *autre* ferme par son nom —, ce que le mono-schéma rend
# explicite autrement.
#
# Leurs modèles, contrôleur et vues sont partis avec ; les tables restaient, et
# `FixturesTest` les dérivant du schéma, la suite ne démarrait plus.
class DropUserTicketsAndSaasSubscriptions < ActiveRecord::Migration[8.1]
  def up
    drop_table :user_tickets
    drop_table :saas_subscriptions
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
          'Les deux tables sont supprimées avec leurs modèles : les recréer vides n’aurait pas de sens.'
  end
end
