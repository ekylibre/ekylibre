class ReadingsCoder

  def self.load(json)
    return {} if json.blank?
    hash = JSON.parse(json.to_json)
    hash = {} unless hash.is_a?(Hash)
    hash.each do |indicator, value|
      klass, value = value
      klass = klass.constantize
      hash[indicator] = klass.new(value)
    end
    hash
  end

  def self.dump(hash)
    readings = hash.map do |indicator, value|
      value = value.to_ewkt if value.is_a? Charta::Geometry
      [indicator, [value.class.name, value]]
    end
    readings.to_h.to_json
  end
end
