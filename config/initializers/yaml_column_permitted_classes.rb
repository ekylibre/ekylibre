# frozen_string_literal: true

require 'bigdecimal'
require 'ostruct'
require 'rgeo'

# Depuis le correctif de la CVE-2022-32224 (Rails 5.2.8.1 et 6.0.6.1), les
# colonnes `serialize` sont relues avec `YAML.safe_load` et une liste blanche
# vide. Or `versions.item_object` et `versions.item_changes` stockent
# l'instantané complet des attributs d'un modèle : dates, horodatages zonés,
# décimaux, mesures, et — pour tous les modèles géolocalisés — les objets
# géométriques avec leur fabrique.
#
# `use_yaml_unsafe_load` rétablirait l'ancien comportement d'un seul réglage
# mais rouvrirait la faille : on énumère plutôt les classes réellement
# présentes dans les colonnes sérialisées.
#
# L'affectation se fait sur `ActiveRecord::Base` depuis `to_prepare`, et non
# sur `config.active_record` : le railtie `active_record.set_configs` recopie
# cette configuration au premier chargement d'`ActiveRecord::Base`, qui sous
# Rails 6 a déjà eu lieu quand cet initialiseur s'exécute — la liste y restait
# alors lettre morte. `to_prepare` a en outre le mérite d'être rejoué à chaque
# rechargement, ce qui évite de garder dans la liste une classe périmée après
# un reload en développement.
# Rails 7 a déplacé le réglage d'`ActiveRecord::Base` vers le module
# `ActiveRecord` lui-même.
YAML_COLUMN_TARGET = if ActiveRecord.respond_to?(:yaml_column_permitted_classes=)
                       ActiveRecord
                     else
                       ActiveRecord::Base
                     end

Rails.application.config.to_prepare do
  # Deux familles de géométries cohabitent dans ces colonnes : les objets
  # RGeo bruts, avec leur fabrique, tels qu'ils sortent de l'adaptateur
  # PostGIS, et les enveloppes Charta posées par `HasShape`. Les unes comme
  # les autres sont des porteuses de données inertes.
  #
  # Côté RGeo, l'implémentation concrète dépend de la fabrique active au
  # moment de l'écriture (CAPI, FFI, ZM, Cartesian, Geographic) : on autorise
  # toute la famille plutôt que de deviner laquelle a produit une ligne
  # historique. Côté Charta les classes sont nommées une à une — énumérer
  # `Charta.constants` forcerait l'autochargement de tout le module, ce à quoi
  # certains de ses fichiers ne se prêtent pas.
  geometries = [::RGeo::Geos, ::RGeo::Cartesian, ::RGeo::Geographic].flat_map do |mod|
    mod.constants.map { |name| mod.const_get(name) }.select { |const| const.is_a?(::Class) }
  end
  geometries += [
    ::Charta::BoundingBox,
    ::Charta::Geometry,
    ::Charta::GeometryCollection,
    ::Charta::LineString,
    ::Charta::MultiPolygon,
    ::Charta::Point,
    ::Charta::Polygon
  ]

  YAML_COLUMN_TARGET.yaml_column_permitted_classes = [
    ::ActiveSupport::HashWithIndifferentAccess,
    ::ActiveSupport::TimeWithZone,
    ::ActiveSupport::TimeZone,
    ::BigDecimal,
    ::Date,
    ::DateTime,
    # Écrit par `Versionable#version_object` jusqu'à Rails 7.0 : la classe n'est
    # plus produite mais les lignes d'avant la bascule en contiennent.
    ::Enumerize::Value,
    ::Measure,
    ::Nori::StringWithAttributes,
    ::OpenStruct,
    ::Rational,
    ::Symbol,
    ::Time
  ] + geometries
end
