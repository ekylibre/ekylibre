module WorkingSet
  class AbilityArray < Array
    class << self
      # Convert DB format (string) to SymbolArray
      # "sow, treat(thing, other_thing), care" => ["sow", "treat(thing, other_thing)", "care"]
      def load(string)
        array = new
        tree = nil
        begin
          tree = WorkingSet.parse(string, root: :abilities_list)
        rescue WorkingSet::SyntaxError => e
          Rails.logger.warn("Cannot parse invalid ability array: #{string.inspect}")
        end
        if tree && list = tree.list and list.present?
          array << list.first_ability.text_value
          if (other_abilities = list.other_abilities) && other_abilities.present?
            other_abilities.elements.each do |other_ability|
              array << other_ability.ability.text_value
            end
          end
        end
        # puts "#{string.inspect} => #{array.inspect}".blue
        array
      end

      # Convert SymbolArray to DB format (string)
      def dump(array)
        string = [array].flatten.map(&:to_s).sort.join(', ')
        # puts "#{string.inspect} <= #{array.inspect}".red
        string
      end
    end

    # Checks that all abilities are valid
    def check!
      each do |string|
        ability = nil
        begin
          ability = WorkingSet.parse(string, root: :ability)
        rescue WorkingSet::SyntaxError => e
          raise InvalidExpression, "Cannot parse invalid ability: #{string.inspect}: #{e.message}"
        end

        unless ability_item = Nomen::Ability.find(ability.ability_name.text_value)
          fail InvalidExpression, "Unknown ability: #{ability.ability_name.text_value}"
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
                fail StandardError, "What parameter type: #{parameter}?"
              end
              unless item
                fail InvalidExpression, "Parameter #{parameter} (#{parameters[index].text_value}) is unknown in its nomenclature"
              end
            end
          else
            fail InvalidExpression, "Argument expected for ability #{ability_item.name}"
          end
        else
          if parameters.any?
            fail InvalidExpression, "No argument expected for ability #{ability_item.name}"
          end
        end
      end
      true
    end

    protected

    def find_nomenclature_item(nomenclature, name)
      unless item = Nomen[nomenclature].find(name)
        fail "Unknown item in #{nomenclature} nomenclature: #{name}"
      end
      item
    end
  end
end
