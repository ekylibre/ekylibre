class ReadingsCoder
  def self.load(json)
    return {} if json.blank?
    hash = JSON.parse(json.to_json)
    hash = {} unless hash.is_a?(Hash)
    hash.each do |indicator, value|
      hash[indicator] = value.class
    end
    hash
  end

  def self.dump(hash)
    hash.to_json if hash.present?
  end
end
