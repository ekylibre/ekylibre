require 'tilt/coffee'

if defined? Encoding
  Encoding.default_internal = Encoding::UTF_8
  Encoding.default_external = Encoding::UTF_8
end

module Ekylibre
  module I18n
    # Ruby 2 convertissait en mots-clés le hash final d'un appel ; Ruby 3 ne le
    # fait plus. Or les raccourcis de traduction ci-dessous relaient leurs
    # arguments à `I18n.translate`, dont la signature est
    # `translate(key = nil, **options)` : elle n'accepte qu'un positionnel.
    # Sous Ruby 3, `:x.tl(count: 3)` levait donc
    # `wrong number of arguments (given 2, expected 0..1)`.
    #
    # Deux formes d'appel coexistent dans l'application et doivent survivre
    # toutes les deux : les mots-clés — `:x.tl(count: 3)`, l'immense majorité —
    # et le hash passé en positionnel — `:x.th(defaults)` dans les vues de
    # chronologie, `"...".tl(options)` dans les helpers. La seconde ne se
    # convertit plus toute seule, d'où cette normalisation explicite.
    #
    # @param args [Array] positionnels résiduels : au plus un hash d'options
    # @param options [Hash] mots-clés reçus
    # @return [Hash] options à passer à `I18n.translate`
    # @raise [ArgumentError] si un positionnel n'est pas un hash d'options
    def self.translation_options(args, options)
      return options if args.empty?

      positional = args.last
      unless args.size == 1 && positional.is_a?(::Hash)
        raise ArgumentError, "Expected at most one options hash, got #{args.inspect}"
      end

      # `merge` rend un nouveau hash : les mots-clés l'emportent, et le hash de
      # l'appelant n'est jamais modifié — ce que `th` faisait auparavant.
      positional.merge(options)
    end
  end
end

class ::String
  def tl(*args, **options)
    ::I18n.translate('labels.' + self, **::Ekylibre::I18n.translation_options(args, options))
  end
end

class ::Symbol
  def tl(*args, **options)
    ::I18n.translate('labels.' + to_s, **::Ekylibre::I18n.translation_options(args, options))
  end

  def ta(*args, **options)
    ::I18n.translate('rest.actions.' + to_s, **::Ekylibre::I18n.translation_options(args, options))
  end

  def tn(*args, **options)
    ::I18n.translate('notifications.messages.' + to_s, **::Ekylibre::I18n.translation_options(args, options))
  end

  # Met en évidence chaque interpolation, sauf les options d'I18n elles-mêmes.
  def th(*args, **options)
    emphasized = ::Ekylibre::I18n.translation_options(args, options).each_with_object({}) do |(key, value), result|
      result[key] = if %i[locale scope default].include?(key) || value.html_safe?
                      value
                    else
                      ('<em>' + CGI.escapeHTML(value) + '</em>').html_safe
                    end
    end
    tl(**emphasized).html_safe
  end
end

class ::Time
  def to_usec
    (utc.to_f * 1000).to_i
  end

  def round_off(interval = 60)
    Time.at((to_f / interval).round * interval).utc
  end
end

class ::Numeric
  # FROM ActiveSupport 6.0
  def minutes
    ActiveSupport::Duration.minutes(self)
  end
  alias minute minutes

  # FROM ActiveSupport 6.0
  def hours
    ActiveSupport::Duration.hours(self)
  end
  alias hour hours

  def semester
    (self * 6).months
  end

  def trimester
    (self * 3).months
  end

  alias trimesters trimester
  alias semesters semester

  def rounded_localize(precision: 2, **options)
    round(precision).localize(precision: precision, **options)
  end

  alias round_l rounded_localize
end

class ::BigDecimal
  # Overwrite badly bigdecimal
  # TODO: What to do for that ?
  def to_f
    to_s('F').to_f
  end
end

class ::Array
  def jsonize_keys
    map do |v|
      (v.respond_to?(:jsonize_keys) ? v.jsonize_keys : v)
    end
  end
end

class ::Hash
  def jsonize_keys
    deep_transform_keys do |key|
      key.to_s.camelize(:lower)
    end
  end

  def deep_compact
    each_with_object({}) do |pair, hash|
      k = pair.first
      v = pair.second
      v2 = (v.is_a?(Hash) ? v.deep_compact : v)
      hash[k] = v2 unless v2.nil? || (v2.is_a?(Hash) && v2.empty?)
      hash
    end
  end

  # Build a struct from the hash
  def to_struct
    OpenStruct.new(self)
  end
end

module Ekylibre
  module I18n
    # Ces trois raccourcis prennent leur clé en premier argument positionnel ;
    # le reste suit la même normalisation que String#tl et Symbol#tl.
    module ContextualModelHelpers
      def tc(key, *args, **options)
        ::I18n.translate('models.' + model_name.singular + '.' + key.to_s,
                         **::Ekylibre::I18n.translation_options(args, options))
      end
    end

    module ContextualModelInstanceHelpers
      def tc(key, *args, **options)
        ::I18n.translate('models.' + self.class.model_name.singular + '.' + key.to_s,
                         **::Ekylibre::I18n.translation_options(args, options))
      end
    end

    module ContextualHelpers
      def tl(key, *args, **options)
        ::I18n.translate('labels.' + key.to_s,
                         **::Ekylibre::I18n.translation_options(args, options))
      end
    end
  end
end

ActionController::Base.send :extend, Ekylibre::I18n::ContextualHelpers
ActionController::Base.send :include, Ekylibre::I18n::ContextualHelpers
ActiveRecord::Base.send :extend, Ekylibre::I18n::ContextualModelHelpers
ActiveRecord::Base.send :include, Ekylibre::I18n::ContextualModelInstanceHelpers
ActionView::Base.send :include, Ekylibre::I18n::ContextualHelpers

module ActiveModel
  module Validations
    module SymbolHandlingClusitivity
      private

        # Redefining the #include? method to make sure we only pass strings
        # to be validated instead of "sometime strings, sometime symbols"
        def include?(record, value)
          value = value.to_s if value.is_a? Symbol
          super record, value
          # `super` here references ActiveModel::Validations::Clusitivity#include?
        end
    end

    # Including new module in the validators that use Clusivity
    InclusionValidator.include SymbolHandlingClusitivity
    ExclusionValidator.include SymbolHandlingClusitivity
  end
end

# Deux extensions d'ActiveSupport::Duration, et rien de plus.
#
# Le reste de ce bloc était une rétroportation d'ActiveSupport 6.0 vers 5.2,
# gardée par `unless ActiveSupport::Duration.methods.include?(:parse)`. Depuis
# le passage à Rails 6 elle ne s'installe plus — et avec elle avait disparu, en
# silence, la lecture des durées au format PostgreSQL. Ce que Rails fournit
# désormais est repris tel quel ; seul ce qu'il ne fournit pas est conservé.
module ActiveSupport
  class Duration
    # Les colonnes `interval` de PostgreSQL reviennent en « 08:30:00 » ou
    # « 3 days », que `Duration.parse` ne sait pas lire : elle n'accepte que
    # l'ISO 8601. `WorkerTimeIndicator.durations` somme précisément une telle
    # colonne, et `HasInterval` relit les durées du lexique.
    module PostgresIntervalParsing
      HOURLY = /\A(\d{2}):(\d{2}):(\d{2})\z/.freeze
      DAILY = /\A(\d+) days\z/.freeze

      def parse(string)
        # `HasInterval` relit des colonnes `interval` qu'ActiveRecord peut déjà
        # avoir converties en Duration : seul le cas String nous concerne.
        return super unless string.is_a?(::String)

        if (match = HOURLY.match(string))
          match[1].to_i.hour + match[2].to_i.minute + match[3].to_i.second
        elsif (match = DAILY.match(string))
          match[1].to_i.day
        else
          super
        end
      end
    end
    singleton_class.prepend(PostgresIntervalParsing)

    # Durée entière exprimée dans une seule unité, sans reste — Rails n'offre
    # que `in_hours`, `in_days`… qui renvoient des flottants.
    def in_full(unit)
      to_i / PARTS_IN_SECONDS[unit.to_s.pluralize.to_sym]
    end
  end
end

module Charta
  class Polygon
    def without_hole_outside_shell
      sql = <<-SQL
        SELECT ST_AsText(
                 ST_MakePolygon(
                   ST_ExteriorRing(:feature)
                 )
               ) AS simplfied_shape
      SQL
      query = ActiveRecord::Base.send(:sanitize_sql_array, [sql, feature: feature.as_text])
      simplfied_shape_text = ActiveRecord::Base.connection.execute(query).first['simplfied_shape']
      Charta.new_geometry(simplfied_shape_text)
    end

    def hole_outside_shell?
      sql = <<-SQL
        SELECT St_IsValidreason(:feature) AS reason
      SQL
      query = ActiveRecord::Base.send(:sanitize_sql_array, [sql, feature: feature.as_text])
      result = ActiveRecord::Base.connection.execute(query).first['reason']
      result.start_with?("Hole lies outside shell")
    end

  end

  class Geometry
    # Generates a simpler geometry.
    # see ST_SimplifyPreserveTopology on http://revenant.ca/www/postgis/workshop/advanced.html#processing-functions

    # @param [Float] tolerance
    # @return [Charta::Geometry]
    def simplify(tolerance)
      sql = <<-SQL
        SELECT ST_AsText(
                 ST_SimplifyPreserveTopology(ST_GeomFromText(:feature), :tolerance )
               ) AS simplfied_shape
      SQL
      query = ActiveRecord::Base.send(:sanitize_sql_array, [sql, feature: feature.as_text, tolerance: tolerance ])
      simplfied_shape_text = ActiveRecord::Base.connection.execute(query).first['simplfied_shape']
      Charta.new_geometry(simplfied_shape_text)
    end
  end
end

# Because RGeo broke compatibility in their serialization model with `projector_class` becoming `projectorclass`
module RGeo
  module Geographic
    class Factory
      def init_with(coder)
        # :nodoc:
        if (proj4_data = coder["proj4"])
          CoordSys.check!(:proj4)
          if proj4_data.is_a?(Hash)
            proj4 = CoordSys::Proj4.create(proj4_data["proj4"], radians: proj4_data["radians"])
          else
            proj4 = CoordSys::Proj4.create(proj4_data.to_s)
          end
        else
          proj4 = nil
        end
        if (coord_sys_data = coder["cs"])
          coord_sys = CoordSys::CS.create_from_wkt(coord_sys_data.to_s)
        else
          coord_sys = nil
        end
        initialize(coder["impl_prefix"],
                   has_z_coordinate: coder["has_z_coordinate"],
                   has_m_coordinate: coder["has_m_coordinate"],
                   srid: coder["srid"],
                   wkt_generator: symbolize_hash(coder["wkt_generator"]),
                   wkb_generator: symbolize_hash(coder["wkb_generator"]),
                   wkt_parser: symbolize_hash(coder["wkt_parser"]),
                   wkb_parser: symbolize_hash(coder["wkb_parser"]),
                   uses_lenient_assertions: coder["lenient_assertions"],
                   buffer_resolution: coder["buffer_resolution"],
                   proj4: proj4,
                   coord_sys: coord_sys
        )
        if (proj_klass = coder["projectorclass"] || coder["projector_class"]) && (proj_factory = coder["projection_factory"])
          klass_ = RGeo::Geographic.const_get(proj_klass)
          if klass_
            projector = klass_.allocate
            projector.set_factories(self, proj_factory)
            @projector = projector
          end
        end
      end
      
      #patch waiting for rgeo 3.0 https://github.com/rgeo/rgeo/issues/277
      def set_property(prop, value)
        case prop
        when :has_z_coordinate
          @support_z = value
        when :has_m_coordinate
          @support_m = value
        when :uses_lenient_assertions
          @lenient_assertions = value
        when :buffer_resolution
          @buffer_resolution = value
        when :is_geographic
          value
        end
      end
    end
  end
end
