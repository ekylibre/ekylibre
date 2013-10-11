module Procedo

  class Task
    attr_reader :expression, :operation

    # TODO Build nomenclatures?
    ACTIONS = {
      # Localization
      "{product} moves to {localizable}" =>                    :move_to,
      "{product} moves-to {localizable}" =>                    :move_to,
      "{product} moves in {localizable}" =>                    :move_in,
      "{product} moves-in {localizable}" =>                    :move_in,
      "{product} moves in default storage" =>                  :move_in_default_storage,
      "{product} moves-in-default-storage" =>                  :move_in_default_storage,
      "{product} moves in default storage of {localizable}" => :move_in_given_default_storage,
      "{product} moves-in-default-storage-of {localizable}" => :move_in_given_default_storage,
      # Production/consumption
      "{product} produces {producible}" => :production,
      "{product} consumes {consumable}" => :consumption,
      "{product} dies" =>                  :death,
      # Physical links
      "{carrier} catches {carried}" =>     :attachment,
      "{carrier} releases {carried}" =>    :detachment,
      # Membership
      "{group} includes {member}" =>       :group_inclusion,
      "{member} goes into {group}" =>      :group_inclusion,
      "{member} goes-into {group}" =>      :group_inclusion,
      "{group} excludes {member}" =>       :group_exclusion,
      "{member} goes out {group}" =>       :group_exclusion,
      "{member} goes-out {group}" =>       :group_exclusion,
      # Ownership
      "{product} loses its owner" =>                   :ownership_loss,
      # "we lose {product}" =>                           :ownership_loss,
      "{owner} becomes owner of {product}" =>          :owner_change,
      "{owner} becomes-owner-of {product}" =>          :owner_change,
      "{product} is owned by {owner}" =>               :owner_change,
      "{product} is-owned-by {owner}" =>               :owner_change,
      # Merge/split
      "{product} merges with {merged}" =>              :merging,
      "{product} merges-with {merged}" =>              :merging,
      "{merged} is merged with {product}" =>           :merging,
      "{merged} is-merged-with {product}" =>           :merging,
      "{product} parts with {parted}" =>               :division,
      "{product} parts-with {parted}" =>               :division,
      "{parted} is separated from {product}" =>        :division,
      "{parted} is-separated-from {product}" =>        :division,
      # Browse
      "{browser} acts on {browsed}" =>                 :browsing,
      "{browser} acts-on {browsed}" =>                 :browsing,
      "{browser} browses {browsed}" =>                 :browsing,
      # Indicators
      "{indicator} is measured" =>                     :simple_measure,
      "{reporter} measures {indicator}" =>             :measure,
      "{reporter} measures {indicator} with {tool}" => :assisted_measure,
      # Deliveries
      "{product} is delivered" =>                      :outgoing_delivery,
      "{product} is-delivered" =>                      :outgoing_delivery,
      "{product} is delivered to {client}" =>          :identified_outgoing_delivery,
      "{product} is-delivered-to {client}" =>          :identified_outgoing_delivery,
      "{product} is received" =>                       :incoming_delivery,
      "{product} is-received" =>                       :incoming_delivery,
      "{product} is received from {supplier}" =>       :identified_incoming_delivery,
      "{product} is-received-from {supplier}" =>       :identified_incoming_delivery
    }.collect{ |expr, type| Action.new(expr, type) }.freeze

    def initialize(operation, element)
      @operation = operation
      if element.has_attribute?("do")
        @expression = element.attr("do").to_s.strip.gsub(/[[:space:]]+/, ' ')
      else
        raise MissingAttribute, "Attribute 'do' is mandatory"
      end
      @action = nil
      
      for action in ACTIONS
        if action.match(@expression)
          if @action
            raise AmbiguousExpression, "Given expression #{@expression.inspect} match with many actions: #{@action.name} and #{action.name}"
          else
            @action = action
          end
        end
      end
      unless @action
        raise InvalidExpression, "Expression #{@expression.inspect} is invalid"
      end

      # Returns a hash with parameters
      # If an action is defined as super_action: "{hero} does something excellent with {cool_guy} and {another_guy} under {indicator}"
      # If you give expression: "spa does something excellent with alice and charlene under bathroom:temperature"
      # This method will return: {hero: <Variable:spa>, cool_guy: <Variable:alice>, another_guy: <Variable:charlene>, indicator: <Indicator:temperature>}
      @parameters = {}
      data = expression.match(@action.pattern)
      for parameter, type in @action.definition
        expr = data[parameter]
        if type == :indicator
          @parameters[parameter] = Indicator.new(self, *expr.split(/\:/))
        else
          @parameters[parameter] = procedure.variables[expr]
        end
      end
    end

    def procedure
      @operation.procedure
    end

    def human_parameters
      @parameters.inject({}) do |hash, pair|
        hash[pair.first] = pair.second.human_name
        hash
      end
    end

    def human_expression
      return "procedo.actions.#{@action.type}".t(human_parameters)
    end

  end

end
