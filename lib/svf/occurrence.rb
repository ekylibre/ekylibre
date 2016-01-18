module SVF
  class Occurrence
    attr_reader :name, :range, :line
    def initialize(name, definition)
      @name = name.to_s
      @line = @name
      @range = definition
      if definition.to_s =~ '-'
        @line, @range = definition.split('-')[0..1]
        @line = @line.to_sym
      end
      @line = @line.to_s.singularize.to_sym
      if @range == '?'
        @range = 0..1
      elsif @range == '*'
        @range = 0..-1
      elsif @range == '+'
        @range = 1..-1
      elsif @range.is_a? Integer
        @range = @range..@range
      elsif @range =~ /\.\./
        pr = @range.split(/\.\./)[0..1]
        pr[1] = -1 if pr[1].blank?
        @range = pr[0].to_i..pr[1].to_i
      end
    end
  end
end
