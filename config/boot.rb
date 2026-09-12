if RUBY_PLATFORM =~ /linux/
  # Load JAVA env variables
  begin
    ENV['JAVA_HOME'] ||= `readlink -f /usr/bin/java | sed "s:/jre/bin/java::"`.strip
    architecture = `dpkg --print-architecture`.strip
    ENV['LD_LIBRARY_PATH'] = "#{ENV['LD_LIBRARY_PATH']}:#{ENV['JAVA_HOME']}/jre/lib/#{architecture}:#{ENV['JAVA_HOME']}/jre/lib/#{architecture}/client"
  rescue
    STDERR.puts "JAVA_HOME has not been set automatically because it's not Debian here."
  end
end

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.
require 'bootsnap/setup' # Speed up boot time by caching expensive operations.

# Psych 4 — livré avec Ruby 3.1, et donc avec la 3.4 — désactive les alias YAML
# par défaut. Or plusieurs fichiers de configuration en emploient : le nôtre
# (`config/database.yml`, que Rails charge lui-même avec `aliases: true`) mais
# aussi ceux de gems que nous ne maîtrisons pas — webpacker 4 lit ses propres
# valeurs par défaut, `lib/install/config/webpacker.yml`, par un simple
# `YAML.load_file`, et l'application ne démarrait plus.
#
# On rétablit les alias pour `load_file` uniquement, et seulement quand
# l'appelant n'a rien précisé. Ce n'est pas la surface d'attaque que Psych 4
# visait : ces fichiers viennent du disque, pas d'une entrée utilisateur. Les
# colonnes `serialize`, elles, restent protégées par
# `ActiveRecord.yaml_column_permitted_classes` — voir l'initialiseur du même nom.
#
# Le correctif se pose après bootsnap, qui décore aussi `load_file`.
module PsychFileAliases
  def load_file(path, **options)
    super(path, **{ aliases: true }.merge(options))
  end
end
YAML.singleton_class.prepend(PsychFileAliases)

# Filtre les warnings irreductibles (gems en conflit Ruby 2.6 stdlib + valeurs d'enum
# qui collisionnent avec des predicats d'ActiveSupport). Les autres warnings Ruby
# restent visibles.
module SilencedWarnings
  PATTERNS = [
    %r{net/protocol\.rb.*already initialized constant},
    %r{net/protocol\.rb.*previous definition},
    %r{It's not recommended to use `.+` as a field value since `.+\?` is defined}
  ].freeze

  def warn(message)
    return if PATTERNS.any? { |p| message =~ p }
    super
  end
end
Warning.singleton_class.prepend(SilencedWarnings)

if ENV['RAILS_ENV'] != 'production'
  require 'dotenv'

  Dotenv.load(Pathname.new(__dir__).join('..', '.env'))
end
