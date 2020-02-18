module Importable
  extend ActiveSupport::Concern

  SOURCES = %w[Lexicon Nomenclature].freeze

  included do
    enumerize :imported_from, in: SOURCES

    SOURCES.each do |source|
      scope "from_#{source.downcase}".to_sym, -> { where(imported_from: source) }
    end
  end
end
