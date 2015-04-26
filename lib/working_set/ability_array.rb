module WorkingSet
  class AbilityArray < Array

    class << self

      # Convert DB format (string) to SymbolArray
      def load(string)
        array = []
        tree = nil
        begin
          tree = WorkingSet.parse(string, root: :abilities_list)
        rescue WorkingSet::SyntaxError => e
          Rails.logger.warn("Cannot parse invalid ability array: #{string.inspect}")
        end
        if tree and list = tree.list and list.present?
          array << list.first_ability.text_value
          if other_abilities = list.other_abilities and other_abilities.present?
            other_abilities.elements.each do |other_ability|
              array << other_ability.ability.text_value
            end
          end
        end
        # puts "#{string.inspect} => #{array.inspect}".blue
        return array
      end

      # Convert SymbolArray to DB format (string)
      def dump(array)
        string = [array].flatten.map(&:to_s).sort.join(', ')
        # puts "#{string.inspect} <= #{array.inspect}".red
        return string
      end

    end

  end
end
