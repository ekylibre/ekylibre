module Procedo

  # Type of action a task can do
  class Action
    TYPES = {
      # Localizations
      direct_movement:   {product: :product, localizable: :product},
      direct_entering:   {product: :product, localizable: :product},
      movement:          {product: :product, localizable: :product},
      entering:          {product: :product, localizable: :product},
      home_coming:       {product: :product},
      given_home_coming: {product: :product, localizable: :product},
      out_going:         {product: :product},
      # Births
      birth:       {product: :product},
      creation:    {product: :product, producer: :product},
      division:    {product: :product, producer: :product},
      # Deaths
      death:       {product: :product},
      consumption: {product: :product, absorber: :product},
      merging:     {product: :product, absorber: :product},
      # Linkages
      attachment:        {carrier: :product, carried: :product, point: :symbol},
      detachment:        {carrier: :product, carried: :product},
      simple_attachment: {carrier: :product, carried: :product},
      simple_detachment: {carrier: :product, point: :symbol},
      # Memberships
      group_inclusion: {group: :product_group, member: :product},
      group_exclusion: {group: :product_group, member: :product},
      # Ownerships
      ownership_loss: {product: :product},
      owner_change:   {product: :product, owner: :entity},
      # Enjoyments
      enjoyment_loss: {product: :product},
      enjoyer_change: {product: :product, enjoyer: :entity},
      # Phases (cast)
      nature_cast:  {product: :product, nature: :product_nature},
      variant_cast: {product: :product, variant: :product_variant},
      # Browsings
      browsing: {browser: :product, browsed: :product},
      # Measurement
      simple_measurement:   {indicator: :indicator},
      measurement:          {indicator: :indicator, reporter: :product},
      assisted_measurement: {indicator: :indicator, reporter: :product, tool: :product},
      # Deliveries
      outgoing_delivery:            {product: :product},
      identified_outgoing_delivery: {product: :product, client: :entity},
      incoming_delivery:            {product: :product},
      identified_incoming_delivery: {product: :product, supplier: :entity}
    }

    ACTORS = {
      indicator: "\\w+\\:\\w+(\\:\\w+)?"
    }

    attr_reader :type, :expression, :pattern

    def initialize(expression, type)
      unless TYPES[type]
        raise ArgumentError, "Action type #{type.inspect} is unknown. Expecting: #{TYPES.keys.to_sentence}."
      end
      @type = type
      @expression = expression
      stakeholders = definition.keys
      @expression.scan(/\{\w+\}/) do |expr|
        stakeholder = expr[1..-2].to_sym
        if definition[stakeholder]
          stakeholders.delete(stakeholder)
        else
          raise ArgumentError, "Unknown stakeholder for #{@type} action: #{stakeholder.inspect}"
        end
      end
      if stakeholders.any?
        raise InvalidExpression, "Expression #{@expression.inspect} doesn't give all stakeholders. Missing stakeholders: #{stakeholders.inspect}"
      end
      exp = "\\A" + @expression.gsub(/[[:space:]]+/, '\\s+').gsub(/\{[^\}]+\}/) do |actor|
        actor = actor[1..-2].to_sym
        e = ACTORS[definition[actor]] || "\\w+"
        # "\\[(?<#{actor}>#{e})\\]"
        "((?<#{actor}>#{e})|\\[(?<#{actor}>#{e})\\])"
      end + "\\z"
      # puts "#{@expression}: " + exp
      @pattern = Regexp.new(exp)
    end

    def match(expression)
      # puts [@pattern, expression].inspect
      return pattern.match(expression)
    end

    def definition
      TYPES[@type]
    end

  end


end
