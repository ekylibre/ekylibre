module Numisma

  class Currency
    attr_reader :code, :active, :cash, :countries, :number, :precision, :unit
    
    def initialize(code, options = {})
      @code = code.strip.upcase
      @active = (options[:active] ? true : false)
      @cash = options[:cash].to_a.collect{|x| x.to_f}.sort
      @countries = options[:countries].to_a.collect{|x| x.to_s}.sort.collect{|x| x.to_sym}
      @number = options[:number].to_i
      @precision = options[:precision].to_i
      @unit = options[:unit].to_s
    end

    def name
      ::I18n.translate("currencies.#{self.code}")
    end

    def label
      ::I18n.translate("labels.currency_with_code", :code=>self.code, :name=>self.name, :default=>"%{name} (%{code})")
    end

    def round(value, options={})
      precision = self.precision
      if RUBY_VERSION.match(/^1\.8/)
        magnitude = 10**precision 
        return (value * magnitude).to_i.to_f*magnitude
      else
        return value.round(precision)
      end
    end

    def ==(other_currency)
      self.code == other_currency.code
    end
    
  end

end
