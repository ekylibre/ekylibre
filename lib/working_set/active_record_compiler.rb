module WorkingSet
  class ActiveRecordCompiler
    def initialize(tree)
      @tree = tree
    end

    def compile(record, options = {})
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
        @tables[:frozen_indicators_list] = indicators
      end
      if indicators = options[:variable_indicators] || options[:default]
        @tables[:variable_indicators_list] = indicators
      end
      compute(@tree, record)
    end

    protected

    def compute(object, record)
      if object.is_a?(WorkingSet::QueryLanguage::BooleanExpression)
        compute(object.boolean_expression, record)
      elsif object.is_a?(WorkingSet::QueryLanguage::Conjunction)
        compute(object.head, record) && compute(object.operand, record)
      elsif object.is_a?(WorkingSet::QueryLanguage::Disjunction)
        compute(object.head, record) || compute(object.operand, record)
      elsif object.is_a?(WorkingSet::QueryLanguage::NegativeTest)
        !compute(object.negated_test, record)
      elsif object.is_a?(WorkingSet::QueryLanguage::EssenceTest) || object.is_a?(WorkingSet::QueryLanguage::DerivativeTest)
        column = object.is_a?(WorkingSet::QueryLanguage::EssenceTest) ? :variety : :derivative_of
        value = record.send(column)
        value.present? && find_nomenclature_item(:varieties, object.variety_name.text_value) >= value
      elsif object.is_a?(WorkingSet::QueryLanguage::InclusionTest)
        column = :derivative_of
        value = record.send(column)
        value.present? && find_nomenclature_item(:varieties, object.variety_name.text_value) < value
      elsif object.is_a?(WorkingSet::QueryLanguage::NonEssenceTest) || object.is_a?(WorkingSet::QueryLanguage::NonDerivativeTest)
        column = object.is_a?(WorkingSet::QueryLanguage::NonEssenceTest) ? :variety : :derivative_of
        find_nomenclature_item(:varieties, object.variety_name.text_value) < record.send(column)
      elsif object.is_a?(WorkingSet::QueryLanguage::AbilityTest)
        ability = object.ability
        unless ability_item = Nomen::Ability.find(ability.ability_name.text_value)
          raise "Unknown ability: #{ability.ability_name.text_value}"
        end
        parameters = []
        if ability.ability_parameters.present? && ability.ability_parameters.parameters.present?
          ps = ability.ability_parameters.parameters
          parameters << ps.first_parameter
          if ps.other_parameters
            ps.other_parameters.elements.each do |other_parameter|
              parameters << other_parameter.parameter
            end
          end
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
                raise "What parameter type: #{parameter}?"
              end
              lists << item.self_and_parents.map(&:name)
            end
            exp = Regexp.new("^#{ability_item.name}\\(\\s*" + lists.map { |l| "(#{l.join('|')})" }.join('\\s*,\\s*') + '\\s*\\)$')
            record.abilities_list.detect do |a|
              a =~ exp
            end.present?
          else
            raise "Argument expected for ability #{ability_item.name}"
          end
        else
          if parameters.any?
            raise "No argument expected for ability #{ability_item.name}"
          else
            record.abilities_list.include?(ability_item.name.to_s)
          end
        end
      elsif object.is_a?(WorkingSet::QueryLanguage::IndicatorTest)
        only = nil
        if object.indicator_filter.present?
          only = object.indicator_filter.mode.text_value.to_sym
        end
        indicator = find_nomenclature_item(:indicators, object.indicator_name.text_value)
        indicator_name = indicator.name.to_sym
        if only.nil?
          record.indicators.include?(indicator_name)
        elsif only == :frozen
          record.frozen_indicators.include?(indicator_name)
        elsif only == :variable
          record.variable_indicators.include?(indicator_name)
        else
          raise "Unknown only value: #{only.inspect}"
        end
      elsif object.nil?
        nil
      else
        raise "Unknown node: #{object.class.name}"
      end
    end

    def find_nomenclature_item(nomenclature, name)
      unless item = Nomen[nomenclature].find(name)
        raise "Unknown item in #{nomenclature} nomenclature: #{name}"
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
