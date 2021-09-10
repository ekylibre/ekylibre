# frozen_string_literal: true

class MasterUnit < LexiconRecord
  include Lexiconable

  belongs_to :translation, class_name: 'MasterTranslation'
  scope :of_dimension, ->(dimension) { where(dimension: dimension.to_s) }
end
