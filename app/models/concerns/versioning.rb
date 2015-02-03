module Versioning
  extend ActiveSupport::Concern

  included do
    extend Enumerize
    cattr_accessor :current_user
    belongs_to :creator, class_name: "User"
    enumerize :event, in: [:create, :update, :destroy], predicates: true

    scope :creations,    -> { where(event: "create") }
    scope :updates,      -> { where(event: "update") }
    scope :destructions, -> { where(event: "destroy") }
    scope :after,   lambda { |at| where("created_at > ?", at) }
    scope :before,  lambda { |at| where("created_at < ?", at) }
    scope :between, lambda { |started_at, stopped_at|
      where(created_at: started_at..stopped_at).order(created_at: :desc)
    }

    serialize :item_object,  HashWithIndifferentAccess
    serialize :item_changes, HashWithIndifferentAccess

    before_save do
      self.created_at ||= Time.now
      self.creator ||= self.class.current_user
      if self.creator
        self.creator_name ||= self.creator.name
      end
      self.item_object = self.item.version_object
      if previous = self.previous
        self.item_changes = self.class.diff(previous.item_object, self.item_object)
      end
    end

    before_update do
      raise StandardError, "Cannot update a past version"
    end

    before_destroy do
      raise StandardError, "Cannot destroy a past version"
    end

  end

  module ClassMethods

    def versioner
      belongs_to :item, class_name: self.name.gsub(/Version$/, '')
    end

    def diff(a, b)
      # return a.diff(b)
      return a.dup.
              delete_if { |k, v| b[k] == v }.
              merge!(b.dup.delete_if { |k, v| a.has_key?(k) })
    end

  end

  def siblings
    self.item.versions
  end

  def following
    @following ||= self.siblings.after(self.created_at).first
  end

  def previous
    @previous ||= self.siblings.before(self.created_at).first
  end

  def changes
    return @changes ||= self.item_changes.collect do |name, value|
      VersionChange.new(self, name, value, self.item_object[name])
    end
  end

  def visible_changes
    return @changes ||= self.item_changes.collect do |name, value|
      unless value.blank? and self.item_object[name].blank?
        VersionChange.new(self, name, value, self.item_object[name])
      end
    end
  end

end
