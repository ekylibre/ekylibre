# require 'procedo/procedure/product_parameter'
# require 'procedo/procedure/group_parameter'

module Procedo
  # This class represents a procedure. It's the definition
  class Procedure
    ROOT_NAME = 'root_'.freeze

    attr_reader :id, :name, :categories, :mandatory_actions, :optional_actions
    delegate :add_product_parameter, :add_group_parameter, :find, :find!,
             :each_product_parameter, :each_group_parameter, :each_parameter,
             :product_parameters, :group_parameters,
             :position_of, :parameters_of_type, to: :root_group

    class << self
      def find(name)
        Procedo.find(name)
      end

      def find_each(&block)
        Procedo.procedures.each(&block)
      end

      # Returns procedures of given activity families
      def of_activity_family(*families)
        options = families.extract_options!
        select(options) do |p|
          p.of_activity_family?(*families)
        end
      end

      # Returns procedures of given categories
      def of_category(*categories)
        options = categories.extract_options!
        select(options) do |p|
          p.of_category?(*categories)
        end
      end

      # Returns procedures which main category match given ones
      def of_main_category(*categories)
        options = categories.extract_options!
        select(options) do |p|
          categories.detect { |c| p.categories.first <= c }
        end
      end

      # Select procedures with given block
      def select(options = {})
        include_deprecated = options[:include_deprecated]
        Procedo.procedures.select do |p|
          (include_deprecated || (!include_deprecated && !p.deprecated?)) &&
            yield(p)
        end
      end
    end

    def initialize(name, options = {})
      @name = name.to_sym
      @categories = []
      @mandatory_actions = []
      @optional_actions = []
      @root_group = Procedo::Procedure::GroupParameter.new(self, ROOT_NAME, cardinality: 1)
      @deprecated = !!options[:deprecated]
      # Adds categories & action
      options[:categories].each { |c| add_category(c) } if options[:categories]
      options[:mandatory_actions].each { |c| add_action(c) } if options[:mandatory_actions]
      options[:optional_actions].each { |c| add_action(c, true) } if options[:optional_actions]
    end

    # All actions (mandatory and optional)
    def actions
      @mandatory_actions + @optional_actions
    end

    def deprecated?
      @deprecated
    end

    # Adds category to procedure
    def add_category(name)
      category = Nomen::ProcedureCategory.find(name)
      raise "Invalid category: #{name.inspect}".red unless category
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
      raise "Invalid action: #{name.inspect}".red unless action
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

    def lint
      messages = []
      product_parameters.each do |p|
        if p.filter
          begin
            WorkingSet.to_sql(p.filter)
          rescue SyntaxError => e
            messages << "Cannot parse filter of #{p.name}: #{e.message}"
          rescue WorkingSet::InvalidExpression => e
            messages << "Invalid expression in filter of #{p.name}: #{e.message}"
          end
        end
        if p.component_of?

        end
        p.handlers.each do |handler|
          %w(condition forward backward).each do |tree|
            next unless handler.send("#{tree}?")
            parameters = handler.send("#{tree}_parameters")
            parameters.each do |parameter|
              unless find(parameter)
                messages << "Cannot find #{parameter} from #{handler.name}/#{tree} in #{p.name}"
              end
            end
          end
        end
      end
      messages
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

    alias uid name

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

    private

    attr_reader :root_group

    def action_selection(list)
      list.map do |action|
        [action.human_name, action.name]
      end
    end
  end
end
