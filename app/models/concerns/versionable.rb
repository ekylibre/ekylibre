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

  def add_creation_version
    versions.create!(event: :create)
  end

  def add_update_version
    versions.create!(event: :update) if notably_changed?
  end

  def add_destruction_version
    versions.create!(event: :destroy)
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
    hash
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
