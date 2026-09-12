# frozen_string_literal: true

module Versionable
  extend ActiveSupport::Concern

  included do
    has_many :versions, -> { order(created_at: :desc) }, as: :item, dependent: :delete_all

    after_create :add_creation_version
    after_update :add_update_version
    before_destroy :add_destruction_version

    class_attribute :versioning_excluded_attributes
    self.versioning_excluded_attributes = %i[updated_at updater_id lock_version]
  end

  # Les versions sont créées par `Version.create!` et non par `versions.create!` :
  # ce dernier pousse l'enregistrement dans la cible chargée de l'association,
  # et l'autosave d'Active Record la reparcourt après les callbacks `after_create`
  # / `after_update`. Rails 6 y voit alors une version déjà persistée à
  # réenregistrer, ce que `Version#before_update` interdit — Rails 5.2 n'y
  # échappait que parce qu'une sauvegarde imbriquée remettait à faux son drapeau
  # `@new_record_before_save`, comportement corrigé depuis.
  def add_creation_version
    Version.create!(item: self, event: :create)
  end

  def add_update_version
    Version.create!(item: self, event: :update) if notably_changed?
  end

  def add_destruction_version
    Version.create!(item: self, event: :destroy)
  end

  def notably_changed?
    if version = last_version
      return false if Version.diff(version_object, version.item_object).empty?
    end
    true
  end

  def last_version
    versions.before(Time.zone.now).first
  end

  def version_object
    hash = attributes.with_indifferent_access
    hash.delete_if { |k, _v| self.class.versioning_excluded_attributes.include?(k.to_sym) }
    # `attributes` rend la valeur d'un attribut `enumerize` sous la forme d'un
    # `Enumerize::Value`, sous-classe de String qui porte l'attribut dont elle
    # vient. Rails 7.1 écrit les colonnes sérialisées avec `YAML.safe_dump` et
    # la refuserait ; et rien ne justifie de graver une classe de gem dans la
    # colonne, la chaîne décrivant la version tout aussi bien. Les lignes
    # écrites avant cette bascule en contiennent : la classe reste admise en
    # lecture, voir `config/initializers/yaml_column_permitted_classes.rb`.
    hash.transform_values { |value| value.is_a?(::Enumerize::Value) ? value.to_s : value }
  end

  module ClassMethods
    def versionize(options = {})
      if options[:exclude]
        self.versioning_excluded_attributes += [options[:exclude]].flatten
        self.versioning_excluded_attributes.uniq!
      end
    end
  end
end
