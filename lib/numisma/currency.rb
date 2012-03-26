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
      @unit = (options[:unit].nil? ? nil : options[:unit].to_s)
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

    # Produces a amount of the currency with the locale parameters
    # TODO: Find a better way to specify number formats which are more complex that the default Rails use
    def localize(amount, options={})
      return unless amount

      options.symbolize_keys!
      
      defaults  = I18n.translate('number.format'.to_sym, :locale => options[:locale], :default => {})
      defaultt  = I18n.translate('number.currency.format'.to_sym, :locale => options[:locale], :default => {})
      defaultt[:negative_format] ||= "-" + defaultt[:format] if defaultt[:format]
      formatcy  = I18n.translate("number.currency.formats.#{self.code}".to_sym, :locale => options[:locale], :default => {})
      formatcy[:negative_format] ||= "-" + formatcy[:format] if formatcy[:format]
      
      prec = {}
      prec[:separator] = formatcy[:separator] || defaultt[:separator] || defaults[:separator]
      prec[:delimiter] = formatcy[:delimiter] || defaultt[:delimiter] || defaults[:delimiter]
      prec[:precision] = formatcy[:precision] || self.precision || defaultt[:precision]
      format           = formatcy[:format] || defaultt[:format] || defaults[:format]
      negative_format  = formatcy[:negative_format] || defaultt[:negative_format] || defaults[:negative_format] || "-" + format
      unit             = formatcy[:unit] || self.unit || self.code
      
      if amount.to_f < 0
        format = negative_format # options.delete(:negative_format)
        amount = amount.respond_to?("abs") ? amount.abs : amount.sub(/^-/, '')
      end
      
      value = amount.to_s
      integers, decimals = value.split(/\./)
      decimals = decimals.gsub(/0+$/, '').ljust(prec[:precision], '0').reverse.split(/(?=\d{3})/).reverse.collect{|x| x.reverse}.join(prec[:delimiter])
      value = integers.gsub(/^0+[1-9]+/, '').gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{prec[:delimiter]}")
      value += prec[:separator] + decimals unless decimals.blank?
      return format.gsub(/%n/, value).gsub(/%u/, unit).gsub(/%s/, "\u{00A0}").html_safe
    end
    
  end

end
