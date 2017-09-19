class ReadingsCoder
  SERIALIZE   = Hash.new { Proc.new { |_, value| value } }
    .tap { |h| h[Measure]              = Proc.new { |_, value| value.to_s    }}
    .tap { |h| h[Charta::Point]        = Proc.new { |_, value| value.to_ewkt }}
    .tap { |h| h[Charta::MultiPolygon] = Proc.new { |_, value| value.to_ewkt }}

  UNSERIALIZE = Hash.new { Proc.new { |klass, value| klass.new(value) } }
    .tap { |h| h[Charta::MultiPolygon] = Proc.new { |_, value| Charta.new_geometry(value) }}
    .tap { |h| h[Charta::Point]        = Proc.new { |_, value| Charta.new_geometry(value) }}
    .tap { |h| h[FalseClass]           = Proc.new { |_, _| false                          }}
    .tap { |h| h[TrueClass]            = Proc.new { |_, _| true                           }}
    .tap { |h| h[String]               = Proc.new { |_, value| value                      }}
    .tap { |h| h[Fixnum]               = Proc.new { |_, value| value.to_i                 }}
    .tap { |h| h[Float]                = Proc.new { |_, value| value.to_f                 }}
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
