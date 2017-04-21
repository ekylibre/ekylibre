module Abaci
  class Column
    attr_reader :name, :type, :references

    def initialize(name)
      components = name.to_s.strip.split(/\s+/)
      @name = components.shift
      type = (components.shift || '').downcase
      @type = if type == 'd'
                :decimal
              elsif type == 'i'
                :integer
              elsif type == 'b'
                :boolean
              elsif type == 'l'
                :list
              else
                :string
              end
      if type =~ /r\(\w+\)/
        @references = Nomen[type[2..-2]] || raise("Cannot find #{type}")
      end
    end

    # Cast value from string
    def cast(value)
      return nil if value.blank?
      if @type == :decimal
        value.to_d
      elsif @type == :integer
        value.to_i
      elsif @type == :boolean
        %w[true yes ok t 1].include?(value.downcase)
      elsif @type == :list
        value.split(/[[:space:]]*\,[[:space:]]*/)
      else
        value
      end
    end
  end
end
