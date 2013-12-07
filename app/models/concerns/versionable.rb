module Versionable
  extend ActiveSupport::Concern

  included do
    has_many :versions, -> { order(created_at: :desc) }, as: :item, dependent: :nullify

    after_create  :add_creation_version
    after_update  :add_update_version
    after_destroy :add_destruction_version
  end

  def add_creation_version
    self.versions.create!(event: :create)
  end

  def add_update_version
    self.versions.create!(event: :update)
  end

  def add_destruction_version
    self.versions.create!(event: :destroy)
  end

end
