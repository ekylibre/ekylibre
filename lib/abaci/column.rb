module Abaci
  class Column
    attr_reader :name, :type, :references

    def initialize(name)
      components = name.to_s.strip.split(/\s+/)
      @name = components.shift
      type = (components.shift || '').downcase
      if type == 'd'
        @type = :decimal
      elsif type == 'i'
        @type = :integer
      elsif type == 'b'
        @type = :boolean
      elsif type == 'l'
        @type = :list
      else
        @type = :string
      end
      if type =~ /r\(\w+\)/
        @references = Nomen[type[2..-2]] || fail("Cannot find #{type}")
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
        %w(true yes ok t 1).include?(value.downcase)
      elsif @type == :list
        value.split(/[[:space:]]*\,[[:space:]]*/)
      else
        value
      end
    end
  end
end
