module Lexiconable
  class ReferenceDataNotUpdateable < StandardError; end

  extend ActiveSupport::Concern

  included do
    before_save :forbid!
    before_destroy :forbid!

    scope :including_references, -> (refs) { where(reference_name: refs) }
    scope :excluding_references, -> (refs) { where.not(reference_name: refs) }

    class << self
      attr_accessor :id_column
      attr_accessor :name_column

      def find(id)
        find_by(id_column => id)
      end
    end

    self.id_column = :id
    self.name_column = :name
  end

  def forbid!
    raise ReferenceDataNotUpdateable
  end

  def id
    return super if self.class.id_column == :id
    send(self.class.id_column)
  end
end
