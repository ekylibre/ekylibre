module Nomen
  XMLNS = 'http://www.ekylibre.org/XML/2013/nomenclatures'.freeze
  NS_SEPARATOR = '-'.freeze
  PROPERTY_TYPES = %i[boolean item item_list choice choice_list string_list date decimal integer nomenclature string symbol].freeze

  class Error < ::StandardError
  end

  class MissingNomenclature < Error
  end

  class ItemNotFound < Error
  end

  class MissingChoices < Error
  end

  class InvalidPropertyNature < Error
  end

  class InvalidProperty < Error
  end

  autoload :Item,                'nomen/item'
  autoload :Migration,           'nomen/migration'
  autoload :Migrator,            'nomen/migrator'
  autoload :Nomenclature,        'nomen/nomenclature'
  autoload :NomenclatureSet,     'nomen/nomenclature_set'
  autoload :PropertyNature,      'nomen/property_nature'
  autoload :Reference,           'nomen/reference'
  autoload :Relation,            'nomen/relation'
  autoload :Reflection,          'nomen/reflection'

  class << self
    def root_path
      Rails.root.join('db', 'nomenclatures')
    end

    def migrations_path
      root_path.join('migrate')
    end

    def reference_path
      root_path.join('db.xml')
    end

    # Returns version of DB
    def reference_version
      return 0 unless reference_path.exist?
      reference_document.root['version'].to_i
    end

    def reference_document
      unless @document
        f = File.open(reference_path, 'rb')
        @document = Nokogiri::XML(f) do |config|
          config.strict.nonet.noblanks.noent
        end
        f.close
      end
      @document
    end

    # Returns list of Nomen::Migration
    def migrations
      Dir.glob(migrations_path.join('*.xml')).sort.collect do |f|
        Nomen::Migration::Base.parse(Pathname.new(f))
      end
    end

    # Returns list of migrations since last done
    def missing_migrations
      last_version = reference_version
      migrations.select do |m|
        m.number > last_version
      end
    end

    # Returns the names of the nomenclatures
    def names
      set.nomenclature_names
    end

    def all
      set.nomenclatures
    end

    # Give access to named nomenclatures
    delegate :[], to: :set

    # Give access to named nomenclatures
    def find(*args)
      options = args.extract_options!
      name = args.shift
      nomenclature = find_or_initialize(name)
      if args.empty?
        return nomenclature
      elsif args.size == 1
        return nomenclature.find(args.shift) if nomenclature
      end
      nil
    end

    def find_or_initialize(name)
      set[name] || set.load_data_from_xml(name)
    end

    # Force loading of nomenclatures
    def load!
      @@set = NomenclatureSet.load_file(reference_path)
    end

    # Browse all nomenclatures
    def each(&block)
      set.each(&block)
    end

    def set
      @@set ||= NomenclatureSet.new
    end
  end
end
