# require 'procedo/procedure/product_parameter'
# require 'procedo/procedure/group_parameter'

module Procedo
  # This class represents a procedure
  class Procedure
    ROOT_NAME = 'root_'

    attr_reader :id, :name, :categories, :mandatory_actions, :optional_actions
    delegate :add_product_parameter, :add_group_parameter, :find, :find!,
             :each_product_parameter, :each_group_parameter, :each_parameter,
             :product_parameters, :group_parameters, :parameters,
             :position_of, to: :root_group

    def initialize(name, options = {})
      @name = name.to_sym
      @categories = []
      @mandatory_actions = []
      @optional_actions = []
      @root_group = Procedo::Procedure::GroupParameter.new(self, ROOT_NAME, cardinality: 1)
      # Adds categories & action
      options[:categories].each { |c| add_category(c) } if options[:categories]
      options[:mandatory_actions].each { |c| add_action(c) } if options[:mandatory_actions]
      options[:optional_actions].each { |c| add_action(c, true) } if options[:optional_actions]
      # Compile it
      # self.compile!
    end

    # All actions (mandatory and optional)
    def actions
      @mandatory_actions + @optional_actions
    end

    # Adds category to procedure
    def add_category(name)
      category = Nomen::ProcedureCategory.find(name)
      fail "Invalid category: #{name.inspect}" unless category
      @categories << category unless @categories.include?(category)
    end

    # Removes category of procedure
    def remove_category(name)
      @categories.delete_if { |c| c.name == name.to_sym }
    end

    # Returns names of categories of procedure
    def category_names
      @categories.map(&:name).map(&:to_sym)
    end

    # Adds action to procedure
    def add_action(name, optional = false)
      action = Nomen::ProcedureAction.find(name)
      fail "Invalid action: #{name.inspect}" unless action
      actions = optional ? @optional_actions : @mandatory_actions
      actions << action unless actions.include?(action)
    end

    # Returns +true+ if action is one of the procedure, +false+ otherwise.
    def has_action?(action)
      actions.detect { |a| a.name.to_s == action.to_s }
    end

    # Removes action of procedure
    def remove_action(name)
      @mandatory_actions.delete_if { |c| c.name == name.to_sym }
      @optional_actions.delete_if { |c| c.name == name.to_sym }
    end

    # Retrieve all parameters recursively in group or subgroups
    def parameters
      @root_group.parameters(true)
    end

    # Lists names of all parameters
    def parameter_names
      @parameter_names ||= parameters.map(&:name)
    end

    def check!
      # Check ungiven roles
      remaining_roles = roles - given_roles.uniq
      if remaining_roles.any?
        fail Procedo::Errors::MissingRole, "Remaining roles of procedure #{name} are not given: #{remaining_roles.join(', ')}"
      end

      # Check producers
      new_parameters.each do |parameter|
        unless parameter.producer.is_a?(Parameter)
          fail Procedo::Errors::UnknownAspect, "Unknown parameter producer for #{parameter.name}"
        end
      end
    end

    def of_activity_family?(*families)
      (activity_families & families).any?
    end

    def of_category?(*categories)
      (category_names & categories).any?
    end

    def mandatory_actions_selection
      action_selection(@mandatory_actions)
    end

    def optional_actions_selection
      action_selection(@optional_actions)
    end

    def actions_selection
      action_selection(actions)
    end

    def can_compute_duration?
      @duration_tree.present?
    end

    # Returns activity families of the procedure
    def activity_families
      @activity_families ||= categories.map do |c|
        families = c.activity_family || []
        families.map do |f|
          Nomen::ActivityFamily.all(f)
        end
      end.flatten.uniq.map(&:to_sym)
    end

    alias_method :uid, :name

    # Returns if the procedure is required
    def required?
      @required
    end

    # Returns human_name of the procedure
    def human_name(options = {})
      default = []
      default << "labels.procedures.#{name}".to_sym
      default << "labels.#{name}".to_sym
      default << name.to_s.humanize
      "procedures.#{name}".t(options.merge(default: default))
    end

    # Returns only parameters which must be built during runnning process
    def new_parameters
      parameters.select(&:new?)
    end

    def handled_parameters
      parameters.select(&:handled?)
    end

    # Generates a hash associating one actor (as the hash value) to each
    # procedure parameter (as the hash key) whenever possible
    # @param [Array<Product>] actors a list of actors possibly matching procedure
    #   parameters
    def matching_variables_for(*actors)
      actors.flatten!
      result = {}
      # generating arrays of actors matching each parameter
      # and parameters matching each actor
      actors_for_each_parameter = {}
      each_parameter do |parameter|
        actors_for_each_parameter[parameter] = parameter.possible_matching_for(actors)
      end

      parameters_for_each_actor = actors_for_each_parameter.inject({}) do |res, (parameter, actors_ary)|
        unless actors_ary.blank?
          actors_ary.each do |actor|
            res[actor] ||= []
            res[actor] << parameter
          end
        end
        res
      end

      # cleaning parameters with no actor
      actors_for_each_parameter.each do |parameter, actors_ary|
        if actors_ary.empty?
          result[parameter] = nil
          actors_for_each_parameter.delete(parameter)
        end
      end

      # setting cursors
      current_parameter = current_actor = 0

      while actors_for_each_parameter.values.flatten.compact.present?
        # first, manage all parameters having only one actor matching
        while current_parameter < actors_for_each_parameter.length
          current_parameter_key = actors_for_each_parameter.keys[current_parameter]
          if actors_for_each_parameter[current_parameter_key].count == 1 && actors_for_each_parameter[current_parameter_key].present? # only one actor for the current parameter
            result[current_parameter_key] = actors_for_each_parameter[current_parameter_key].first
            clean(parameters_for_each_actor, actors_for_each_parameter, result[current_parameter_key], current_parameter_key)
            # restart from the beginning
            current_parameter = 0
          else
            current_parameter += 1
          end
        end

        # then, manage first actor having only one parameter matching and go back to the first step
        while current_actor < parameters_for_each_actor.length
          current_actor_key = parameters_for_each_actor.keys[current_actor]
          if parameters_for_each_actor[current_actor_key].count == 1
            current_parameter_key = parameters_for_each_actor[current_actor_key].first
            result[current_parameter_key] = current_actor_key
            clean(parameters_for_each_actor, actors_for_each_parameter, result[current_parameter_key], current_parameter_key)
            # return to first step
            current_actor = 0
            break
          else
            current_actor += 1
          end
        end
        # then, manage the case when no actor has only one parameter matching
        if current_actor >= parameters_for_each_actor.length
          current_parameter = 0
          current_parameter_key = actors_for_each_parameter.keys[current_parameter]
          result[current_parameter_key] = actors_for_each_parameter[current_parameter_key].first unless actors_for_each_parameter[current_parameter_key].nil?
          clean(parameters_for_each_actor, actors_for_each_parameter, result[current_parameter_key], current_parameter_key)
          # return to first step
        end

        # finally, manage the case when there's no more actor to match with parameters
        next unless parameters_for_each_actor.empty?
        actors_for_each_parameter.keys.each do |parameter_key|
          result[parameter_key] = nil
        end

      end
      result.delete_if { |_k, v| v.nil? }
    end

    private

    attr_reader :root_group

    def action_selection(list)
      list.map do |action|
        [action.human_name, action.name]
      end
    end

    # clean
    # removes newly matched actor and parameter from hashes
    # associating all possible actors for each parameter and
    # all possible parameters for each actor
    # @params:  - actors_hash, parameters_hash, the hashes to clean
    #           - actor, parameter, the values to remove
    def clean(actors_hash, parameters_hash, actor, parameter)
      # deleting actor from hash "actor => parameters"
      actors_hash.delete(actor)
      # deleting actor for all remaining parameters
      parameters_hash.values.each { |ary| ary.delete(actor) }
      # removing current parameter for all remaining actors
      actors_hash.values.each { |ary| ary.delete(parameter) }
      # removing current parameter from hash "parameter => actors"
      parameters_hash.delete(parameter)
    end
  end
end
