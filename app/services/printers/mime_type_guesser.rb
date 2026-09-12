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
      # `Marcel::MimeType.for` lit la signature d'un flux et ouvre un chemin ;
      # seule une chaîne demande d'être convertie. Convertir sans distinction
      # transformait un `File` en la chaîne « #<File:0x…> », que marcel tentait
      # alors d'ouvrir — `Errno::ENOENT` sur tout gabarit téléversé.
      Marcel::MimeType.for(file.is_a?(::String) ? ::Pathname.new(file) : file)
    end
  end
end
