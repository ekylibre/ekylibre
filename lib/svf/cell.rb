module SVF
  class Cell
    attr_reader :name, :type, :length, :format, :options, :default, :start

    def initialize(name, definition, start = nil)
      @name = name.to_sym
      if definition.is_a? String
        definition = { type: definition }
      elsif definition.is_a? Hash
        definition.symbolize_keys!
      else
        return nil
      end
      if definition[:type] =~ /\-/
        type, format = definition[:type].split('-')[0..1]
        definition = { type: type.to_sym }
        if format =~ /^\d+$/
          definition[:length] = format.to_i
        elsif type.to_sym == :float && format.match(/^\d+\.\d+$/)
          definition[:format] = format
          definition[:length] = format.split('.').inject(1) { |s, e| s += e.to_i }
        end
      else
        definition[:type] = definition[:type].to_sym
      end
      @type = definition.delete(:type)
      if @type == :boolean
        definition[:length] = 1
      elsif @type == :date
        definition[:length] = 8
      end
      @length = definition.delete(:length)
      raise definition.inspect if @length.nil?
      @format = definition.delete(:format)
      @options = definition.delete(:options) || {}
      @default = definition.delete(:default)
      @start = start
    end

    def required?
      false
    end

    def inspect
      "#{name}(#{type}/#{length})"
    end

    def parse_value(line = 'line', start = nil)
      start ||= @start
      value = "#{line}[#{start}..#{start + length - 1}]"
      if type == :boolean
        value = "(#{value} == '1' ? true : false)"
      elsif type == :date
        value = "(#{value}.blank? ? nil : Date.civil(#{line}[#{start + 4}..#{start + 7}].to_i, #{line}[#{start + 2}..#{start + 3}].to_i, #{line}[#{start + 0}..#{start + 1}].to_i))"
      elsif type == :integer
        value = "#{value}.to_s.strip.to_i"
      elsif type == :float
        # size = self.format.split(".")[0].to_i
        # value = "(#{line}[#{start}..#{start+size-1}]+'.'+#{line}[#{start+size+1}..#{start+self.length-1}]).to_d"
        value = "#{value}.to_s.tr(',', '.').to_d"
      elsif type == :string
        value = "#{value}.to_s.strip.encode('UTF-8')"
      end
      value
    end

    def stop
      @start + length - 1
    end

    def format_value(variable)
      if type == :boolean
        value = "(#{variable} ? '1' : '0')"
      elsif type == :date
        value = "(#{variable}.nil? ? '#{' ' * 8}' : #{variable}.strftime('%d%m%Y'))"
      elsif type == :integer
        value = "#{variable}.to_i.to_s.rjust(#{length})[0..#{length - 1}]"
      elsif type == :float
        size = format.split('.')
        value = "(#{variable}.to_i.to_s + ',' + ((#{variable} - #{variable}.to_i)*#{10**size[1].to_i}).to_i.abs.to_s.rjust(#{size[1].to_i}, '0')).rjust(#{length})[0..#{length - 1}]"
      elsif type == :string
        value = "#{variable}.to_s.rjust(#{length})[0..#{length - 1}]"
      end
      value
    end
  end
end
