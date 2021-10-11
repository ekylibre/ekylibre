# frozen_string_literal: true

class MasterCropProductionCapSnaCode < LexiconRecord

  include Lexiconable
  belongs_to :translation, class_name: 'MasterTranslation'
end
