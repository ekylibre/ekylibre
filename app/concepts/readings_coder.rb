class ReadingsCoder
  SERIALIZE   = Hash.new { proc { |_, value| value } }
                    .tap { |h| h[Measure]              = proc { |_, value| value.to_s    } }
                    .tap { |h| h[Charta::Point]        = proc { |_, value| value.to_ewkt } }
                    .tap { |h| h[Charta::MultiPolygon] = proc { |_, value| value.to_ewkt } }

  UNSERIALIZE = Hash.new { proc { |klass, value| klass.new(value) } }
                    .tap { |h| h[Charta::MultiPolygon] = proc { |_, value| Charta.new_geometry(value) } }
                    .tap { |h| h[Charta::Point]        = proc { |_, value| Charta.new_geometry(value) } }
                    .tap { |h| h[FalseClass]           = proc { |_, _| false                          } }
                    .tap { |h| h[TrueClass]            = proc { |_, _| true                           } }
                    .tap { |h| h[Integer]              = proc { |_, value| value.to_i } }
                    .tap { |h| h[String]               = proc { |_, value| value } }
                    .tap { |h| h[Bignum]               = proc { |_, value| value.to_i } }
                    .tap { |h| h[Fixnum]               = proc { |_, value| value.to_i } }
                    .tap { |h| h[Float]                = proc { |_, value| value.to_f } }
                    .freeze

  def self.load(json)
    return {} if json.blank?
    hash = JSON.parse(json.to_json)
    hash = {} unless hash.is_a?(Hash)
    hash.each do |indicator, value|
      klass, value = value
      klass = klass.constantize
      hash[indicator] = UNSERIALIZE[klass][klass, value]
    end
    hash
  end

  def self.dump(hash)
    readings = hash.compact.map do |indicator, value|
      klass = value.class
      [indicator, [klass.name, SERIALIZE[klass][klass, value]]]
    end
    readings.to_h.to_json
  end
end
