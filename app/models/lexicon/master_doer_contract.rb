# frozen_string_literal: true

class MasterDoerContract < LexiconRecord
  include Lexiconable
  belongs_to :translation, class_name: 'MasterTranslation'
end
