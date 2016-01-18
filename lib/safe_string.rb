# coding: utf-8

class ::String
  MAJUSCULES = %w(Á À Â Ä Å Ã Æ É È Ê Ë Ì Ï Î Ò Ô Ö Œ Û Ü Ù Ç).freeze
  MINUSCULES = %w(á à â ä å ã æ é è ê ë ì ï î ò ô ö œ û ü ù ç).freeze
  MOLUSCULES = %w(a a a a a a ae é é é é i i i o o o oe u u u ss).freeze # Phonétique
  MEJUSCULES = %w(A A A A A A AE E E E E I I I O O O OE U U U C).freeze  # Simplification "lisible"
  MENUSCULES = %w(a a a a a a ae e e e e i i i o o o oe u u u c).freeze  # Simplification "lisible"

  def dig(depth = 1)
    strip.gsub(/^/, '  ' * depth) + "\n"
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

  def pdfize
    ascii.gsub(/\\W/, '_')
  end

  def to_ss
    ss = dup.to_s
    ss.downcase!
    ss.strip!
    ss.gsub!('@', ' arobase ')
    ss.gsub!('€', ' euro ')
    ss.gsub!('$', ' dollar ')
    ss.gsub!('£', ' livre ')
    ss.gsub!('%', ' pourcent ')
    ss.gsub!('★', ' étoile ')
    ss.gsub!(/(–|-)/, ' tiret ')

    ss = ss.translate(MAJUSCULES, MOLUSCULES).translate(MINUSCULES, MOLUSCULES)
    ss += ' '
    ss.gsub!('.', ' . ')
    ss.tr!("'", ' ')
    ss.gsub!(/(\\|\/|\-|\_|\&|\||\,|\.|\!|\?|\*|\+|\=|\(|\)|\[|\]|\{|\}|\$|\#)/, ' ')

    # Analyse phonétique
    ss.tr!('y', 'i')
    ss.gsub!(/(a|e|é|i|o|u)s(a|e|é|i|o|u)/, '\1z\2')
    ss.gsub!(/oi/, 'oa')
    ss.gsub!(/ii/,  'ie')
    ss.gsub!(/ess/, 'és')

    ss.squeeze! 'a-z'
    ss.gsub!(/(^| )ou(a|e|i|o|u)/, '\1w\2')
    ss.gsub!(/ph/, 'f')
    ss.gsub!(/ou/, 'u')
    ss.gsub!(/oe/, 'e')
    ss.gsub!(/(.)ent( |$)/, '\1e\2')
    ss.gsub!(/eu(s|x)?/, 'e')
    ss.gsub!(/(ai|ei)n/, 'in')
    ss.gsub!(/(i|u|y)e(\ |$)/, '\1 ')
    ss.gsub!(/(e|a)i/, 'é')
    ss.gsub!(/est( |$)/, 'é\1')
    ss.gsub!(/(e)?au/, 'o')

    ss.gsub!(/(l|k)s( |$)/, '\1')
    ss.gsub!(/(e|é)(r|t|s)s? /, 'é ')
    ss.gsub!(/c(é|e|i)/, 's\1')
    ss.gsub!(/g(é|e|i)/, 'j\1')
    ss.gsub!(/e(m|n)/, 'an')
    ss.gsub!('gu', 'g')
    ss.gsub!(/(c|q)/, 'k')
    ss.gsub!(/ku([aeiou])/, 'k\1')
    ss.gsub!('mn', 'm')
    ss.gsub!(/(g|k)n/, 'n')
    ss.gsub!(/(m|n|r)(t|d|p|q|k)?s?( |$)/, '\1\3')
    ss.gsub!(/(.)t( |$)/, '\1\2')
    ss.gsub!(/ati/, 'asi')
    ss.gsub!('tion', 'sion')
    ss.gsub!(/(e|i|u|o|a)(s|x) /, '\1 ')

    ss.gsub!(/é/, 'e')
    ss.squeeze! 'a-z'
    ss.gsub!('skh', 'sh')
    ss.gsub!('kh', 'sh')
    ss.gsub!('sh', '@')
    ss.delete!('h')
    ss.gsub!('@', 'sh')
    ss.gsub!(/[^a-z0-9]/, ' ')
    ss.squeeze! ' '
    ss.strip!
    ss
  end

  def soundex2
    word = dup
    steps = ':' #+word+"/"
    word = word.strip.downcase
    word.delete!('\\ -_&|,.!?%$*+=()[]{}#')
    word.tr!('^bcdfghjklmnpqrstvwxz', 'a')
    steps += word + ' / '
    #    word.gsub!(/gui/,"ki")
    #    word.gsub!(/gue/,"ke")
    word.gsub!(/ga/, 'ka')
    #    word.gsub!(/go/,"ko")
    word.gsub!(/gu/, 'k')
    word.gsub!(/ca/, 'ka')
    #    word.gsub!(/co/,"ko")
    #    word.gsub!(/cu/,"ku")
    word.tr!('q', 'k')
    word.gsub!(/cc/, 'k')
    word.gsub!(/ck/, 'k')
    steps += word + ' / '
    word.tr!('eiou', 'a') if word[0] != 'a'
    steps += word + ' / '
    word.gsub!(/mac/, 'mcc')
    word.gsub!(/asa/, 'aza')
    word.gsub!(/kn/, 'nn')
    word.gsub!(/pf/, 'ff')
    word.gsub!(/sch/, 'sss')
    word.gsub!(/ph/, 'ff')
    steps += word + ' / '
    word.gsub!(/ch/, 'ç')
    word.gsub!(/sh/, '@')
    word.delete!('h')
    word.gsub!(/ç/, 'ch')
    word.gsub!(/@/, 'sh')
    steps += word + ' / '
    #    word.gsub!(/ay/,"ç")
    #    word.delete!("h")
    #    word.gsub!(/ç/,"ay")
    steps += word + ' / '
    word.gsub!(/[atds]$/, '')
    steps += word + ' / '
    word[0] = '@' if word[0] == 'a'
    word.delete!('a')
    word.gsub!(/@/, 'a')
    steps += word + ' / '
    word.squeeze!
    steps += word + ' / '
    word[0..3].strip.upcase.ljust(4, ' ') #+":: "+steps.dump
  end
end
