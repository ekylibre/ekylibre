# frozen_string_literal: true

module Printers
  # Devine le type MIME d'un fichier d'après son contenu.
  #
  # S'appuyait sur `mimemagic`, retirée : sa série 0.3 ne se construit plus sous
  # Ruby 3 — le Rakefile de son extension appelle une méthode avec deux
  # arguments là où Ruby 3.4 en attend un — et les séries suivantes portent
  # l'héritage de licence de la base freedesktop.
  #
  # `marcel` rend le même service, se limite à la reconnaissance par signature,
  # et arrive déjà par Active Storage : c'est la bibliothèque que Rails emploie
  # lui-même pour cela.
  class MimeTypeGuesser
    # @param file [String, Pathname, IO] chemin ou flux à examiner
    # @return [String] type MIME, « application/octet-stream » à défaut
    def guess(file)
      Marcel::MimeType.for(Pathname.new(file.to_s))
    end
  end
end
