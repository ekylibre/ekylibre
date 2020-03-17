require 'mimemagic'
require 'mimemagic/overlay'

module Printers
  class MimeTypeGuesser

    def guess(file)
      MimeMagic.by_magic(file).type
    end
  end
end