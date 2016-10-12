module WorkingSet
  class SQLCompiler
    def initialize(tree)
      @tree = tree
    end

    def compile(options = {})
      # Set env if needed here...
      @tables = {}
      if variety = options[:variety] || options[:default]
        @tables[:variety] = variety
        @tables[:derivative_of] = variety
      end
      if derivative_of = options[:derivative_of] || options[:derivative] || options[:default]
        @tables[:derivative_of] = derivative_of
      end
      if abilities = options[:abilities] || options[:default]
        @tables[:abilities_list] = abilities
      end
      if indicators = options[:indicators] || options[:default]
        @tables[:frozen_indicators_list] = indicators
        @tables[:variable_indicators_list] = indicators
      end
      if indicators = options[:frozen_indicators] || options[:default]
        @tables[:frozen_indicators_list] ||= indicators
      end
      if indicators = options[:variable_indicators] || options[:default]
        @tables[:variable_indicators_list] ||= indicators
      end
      rewrite(@tree)
    end

    protected

    def rewrite(object)
      if object.is_a?(WorkingSet::QueryLanguage::BooleanExpression)
        '(' + rewrite(object.boolean_expression) + ')'
      elsif object.is_a?(WorkingSet::QueryLanguage::Conjunction)
        rewrite(object.head) + ' AND ' + rewrite(object.operand)
      elsif object.is_a?(WorkingSet::QueryLanguage::Disjunction)
        rewrite(object.head) + ' OR ' + rewrite(object.operand)
      elsif object.is_a?(WorkingSet::QueryLanguage::NegativeTest)
        'NOT(' + rewrite(object.negated_test) + ')'
      elsif object.is_a?(WorkingSet::QueryLanguage::EssenceTest) || object.is_a?(WorkingSet::QueryLanguage::DerivativeTest)
        column = object.is_a?(WorkingSet::QueryLanguage::EssenceTest) ? :variety : :derivative_of
        item = find_nomenclature_item(:varieties, object.variety_name.text_value)
        compliants = item.self_and_children.map { |i| "'#{i.name}'" }.join(', ')
        "#{column_for(column)} IN (#{compliants})"
      elsif object.is_a?(WorkingSet::QueryLanguage::NonEssenceTest) || object.is_a?(WorkingSet::QueryLanguage::NonDerivativeTest)
        column = object.is_a?(WorkingSet::QueryLanguage::NonEssenceTest) ? :variety : :derivative_of
        item = find_nomenclature_item(:varieties, object.variety_name.text_value)
        compliants = item.self_and_children.map { |i| "'#{i.name}'" }.join(', ')
        "#{column_for(column)} NOT IN (#{compliants})"
      elsif object.is_a?(WorkingSet::QueryLanguage::AbilityTest)
        ability = object.ability
        unless ability_item = Nomen::Ability.find(ability.ability_name.text_value)
          raise InvalidExpression, "Unknown ability: #{ability.ability_name.text_value}"
        end
        parameters = []
        if ability.ability_parameters.present? && ability.ability_parameters.parameters.present?
          ps = ability.ability_parameters.parameters
          parameters << ps.first_parameter
          for other_parameter in ps.other_parameters.elements
            parameters << other_parameter.parameter
          end if ps.other_parameters
        end
        if ability_item.parameters
          if parameters.any?
            lists = []
            ability_item.parameters.each_with_index do |parameter, index|
              if parameter == :variety
                item = find_nomenclature_item(:varieties, parameters[index].text_value)
              elsif parameter == :issue_nature
                item = find_nomenclature_item(:issue_natures, parameters[index].text_value)
              else
                raise InvalidExpression, "What parameter type: #{parameter}?"
              end
              # lists << item.self_and_children.map(&:name)
              lists << item.self_and_parents.map(&:name)
            end
            "#{column_for(:abilities_list)} ~ E'\\\\m#{ability_item.name}\\\\(\\\\s*" + lists.map { |l| '(' + l.join('|') + ')' }.join('\\\\s*,\\\\s*') + "\\\\s*\\\\)\\\\Y'"
          else
            raise InvalidExpression, "Argument expected for ability #{ability_item.name}"
          end
        else
          if parameters.any?
            raise "No argument expected for ability #{ability_item.name}"
          else
            "#{column_for(:abilities_list)} ~ E'\\\\m#{ability_item.name}\\\\M'"
          end
        end
      elsif object.is_a?(WorkingSet::QueryLanguage::IndicatorTest)
        only = nil
        if object.indicator_filter.present?
          only = object.indicator_filter.mode.text_value.to_sym
        end
        indicator = find_nomenclature_item(:indicators, object.indicator_name.text_value)
        exp = "E'\\\\m#{indicator.name}\\\\M'"
        if only.nil?
          "(#{indicator_test(:frozen, exp)} OR #{indicator_test(:variable, exp)})"
        else
          indicator_test(only, exp)
        end
      elsif object.nil?
        'NULL'
      else
        '(' + object.class.name + ')'
      end
    end

    def find_nomenclature_item(nomenclature, name)
      unless item = Nomen[nomenclature].find(name)
        raise InvalidExpression, "Unknown item in #{nomenclature} nomenclature: #{name}"
      end
      item
    end

    def column_for(name)
      if @tables[name].is_a?(Symbol)
        return "#{@tables[name]}.#{name}"
      elsif @tables[name].is_a?(String)
        return @tables[name]
      end
      name
    end

    def indicator_test(type, exp)
      column = column_for("#{type}_indicators_list".to_sym)
      "(#{column} IS NOT NULL AND #{column} ~ #{exp})"
    end
  end
end
