# frozen_string_literal: true

class MasterPackaging < LexiconRecord
  include Lexiconable

  composed_of :value, class_name: 'Measure', mapping: [%w[capacity to_d], %w[capacity_unit unit]]
  belongs_to :capacity_unit, class_name: 'MasterUnit', foreign_key: :capacity_unit, primary_key: :reference_name
  belongs_to :translation, class_name: 'MasterTranslation'
end
