module Versionable
  extend ActiveSupport::Concern

  included do
    has_many :versions, -> { order(created_at: :desc) }, as: :item, dependent: :delete_all

    after_create  :add_creation_version
    after_update  :add_update_version
    before_destroy :add_destruction_version

    class_attribute :versioning_excluded_attributes
    self.versioning_excluded_attributes = [:updated_at, :updater_id, :lock_version]
  end

  def add_creation_version
    self.versions.create!(event: :create)
  end

  def add_update_version
    if notably_changed?
      self.versions.create!(event: :update)
    end
  end

  def add_destruction_version
    self.versions.create!(event: :destroy)
  end

  def notably_changed?
    if version = self.last_version
      if Version.diff(self.version_object, version.item_object).empty?
        return false
      end
    end
    return true
  end

  def last_version
    self.versions.before(Time.now).first
  end

  def version_object
    hash = self.attributes.with_indifferent_access
    hash.delete_if{|k,v| self.class.versioning_excluded_attributes.include?(k.to_sym)}
    return hash
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
