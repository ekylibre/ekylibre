# coding: utf-8

class ::String
  MAJUSCULES = %w[Á À Â Ä Å Ã Æ É È Ê Ë Ì Ï Î Ò Ô Ö Œ Û Ü Ù Ç].freeze
  MINUSCULES = %w[á à â ä å ã æ é è ê ë ì ï î ò ô ö œ û ü ù ç].freeze
  MOLUSCULES = %w[a a a a a a ae é é é é i i i o o o oe u u u ss].freeze # Phonétique
  MEJUSCULES = %w[A A A A A A AE E E E E I I I O O O OE U U U C].freeze  # Simplification "lisible"
  MENUSCULES = %w[a a a a a a ae e e e e i i i o o o oe u u u c].freeze  # Simplification "lisible"

  def dig(depth = 1)
    strip.indent(depth) + "\n"
  end

  def indent(depth = 1)
    gsub(/^/, '  ' * depth)
  end

  def translate(from, to)
    dup.translate!(from, to)
  end

  def translate!(from, to)
    force_encoding('UTF-8') if respond_to? :force_encoding
    from.length.times { |x| gsub!(from[x], to[x]) }
    self
  end

  def lower
    dup.lower!
  end

  def lower!
    translate!(MAJUSCULES, MINUSCULES)
    downcase!
    self
  end

  def upper
    dup.upper!
  end

  def upper!
    translate!(MINUSCULES, MAJUSCULES)
    upcase!
    self
  end

  def ascii
    translate(MINUSCULES, MENUSCULES).translate(MAJUSCULES, MEJUSCULES)
  end

  def upper_ascii
    ascii.upcase
  end

  def lower_ascii
    ascii.downcase
  end

  def simpleize
    ascii.gsub(/[^a-zA-Z0-9\_]/, '_').squeeze('_')
  end

  def codeize
    upper_ascii.gsub(/[^A-Z0-9]/, '')
  end
end
