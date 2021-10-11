# frozen_string_literal: true

class MasterPrice < LexiconRecord
  include Lexiconable

  belongs_to :master_variant, class_name: 'MasterVariant', foreign_key: :reference_packaging_name, primary_key: :reference_name
  belongs_to :packaging, class_name: 'MasterPackaging'

end
