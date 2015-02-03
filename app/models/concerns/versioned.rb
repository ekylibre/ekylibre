module Versioned
  extend ActiveSupport::Concern

  included do
    # has_many :versions, -> { order(created_at: :desc) }, foreign_key: :item_id, dependent: :delete_all, class_name: "#{self.name}Version"

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
    puts "Yeah #{self.class.name}?".red
    if notably_changed?
      self.versions.create!(event: :update)
      puts "Yeah".green
    end
  end

  def add_destruction_version
    self.versions.create!(event: :destroy)
  end

  def notably_changed?
    if version = self.last_version
      if self.class.diff(self.version_object, version.item_object).empty?
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

    def acts_as_versioned(options = {})
      has_many :versions, -> { order(created_at: :desc) }, foreign_key: :item_id, dependent: :delete_all, class_name: "#{self.name}Version"
      if options[:exclude]
        self.versioning_excluded_attributes += [options[:exclude]].flatten
        self.versioning_excluded_attributes.uniq!
      end
    end

    def diff(a, b)
      # return a.diff(b)
      return a.dup.
              delete_if { |k, v| b[k] == v }.
              merge!(b.dup.delete_if { |k, v| a.has_key?(k) })
    end

  end


end
