class InterventionParameter < Ekylibre::Record::Base
  # Amount computation represents how a amount is computed for a cost or an earn
  # in an intervention
  class AmountComputation
    NATURES = [:failed, :none, :quantity]
    ORIGINS = [:catalog, :purchase, :sale]

    class << self
      def failed
        new(:failed)
      end

      def none
        new(:none)
      end

      def quantity(origin, options = {})
        new(:quantity, origin, options)
      end
    end

    def initialize(nature, origin = nil, options = {})
      unless NATURES.include?(nature)
        fail ArgumentError, "Invalid nature. Got: #{nature.inspect}"
      end
      @nature = nature
      if quantity?
        unless ORIGINS.include?(origin)
          fail ArgumentError, "Invalid origin. Got: #{origin.inspect}"
        end
        @origin = origin
      end
      @options = options
      @options[:quantity] ||= 0
      check_option_presence!(:quantity, :unit_name) if quantity?
      check_option_presence!(:catalog_usage) if catalog?
      check_option_presence!(:purchase_item) if purchase?
      check_option_presence!(:sale_item) if sale?
    end

    [:quantity, :unit_name, :catalog_usage, :catalog_item, :purchase_item, :sale_item].each do |nature|
      define_method nature do
        @options[nature]
      end
    end

    NATURES.each do |nature|
      define_method "#{nature}?" do
        @nature == nature
      end
    end

    ORIGINS.each do |origin|
      define_method "#{origin}?" do
        @origin == origin
      end
    end

    # FIXME: Not suitable more multi-money support
    def currency
      Nomen::Currency.find(Preference[:currency])
    end

    def human_unit_amount(_options = {})
      unit_amount.l(currency: currency.name)
    end

    def item
      send("#{@origin}_item")
    end

    def unit_amount?
      item.present?
    end

    def unit_amount
      item ? item.unit_pretax_amount : 0.0
    end

    def amount?
      unit_amount?
    end

    def amount
      (unit_amount * quantity).round(currency.precision).to_i
    end

    def human_amount
      amount.l(currency: currency.name)
    end

    delegate :catalog, to: :catalog_item

    delegate :sale, to: :sale_item

    delegate :purchase, to: :purchase_item

    protected

    def check_option_presence!(*options)
      options.each do |option|
        unless @options[option]
          fail ArgumentError, "An option #{option.inspect} must be given. #{@options.inspect}"
        end
      end
    end
  end
end
