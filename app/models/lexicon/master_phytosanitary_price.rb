# frozen_string_literal: true

class MasterPhytosanitaryPrice < LexiconRecord
  include Lexiconable

  belongs_to :master_variant, class_name: 'RegisteredPhytosanitaryProduct', foreign_key: :reference_article_name, primary_key: :id
  belongs_to :packaging, class_name: 'MasterPackaging'

end
