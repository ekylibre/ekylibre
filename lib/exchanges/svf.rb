# encoding: utf-8
module SVF

  # Build submodule to handle format defined in the file
  # Format must be defined in YAML
  def self.load(name, file)
    # raise Formater.new(name, file).generate
    module_eval(Formater.new(name, file).generate)
  end


  class Cell
    attr_reader :name, :type, :length, :format, :options, :default, :start

    def initialize(name, definition, start=nil)
      @name = name.to_sym
      if definition.is_a? String
        definition = {:type => definition}
      elsif definition.is_a? Hash
        definition.symbolize_keys!
      else
        return nil
      end
      if definition[:type].match("-")
        type, format = definition[:type].split("-")[0..1]
        definition = {:type => type.to_sym}
        if format.match(/^\d+$/)
          definition[:length] = format.to_i
        elsif type.to_sym == :float and format.match(/^\d+\.\d+$/)
          definition[:format] = format
          definition[:length] = format.split(".").inject(1){|s,e| s += e.to_i}
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
      @options = definition.delete(:options)||{}
      @default = definition.delete(:default)
      @start = start
    end

    def required?
      false
    end

    def inspect
      "#{self.name}(#{self.type}/#{self.length})"
    end

    def parse_value(line = 'line', start=nil)
      start ||= @start
      value = "#{line}[#{start}..#{start+self.length-1}]"
      if self.type == :boolean
        value = "(#{value} == '1' ? true : false)"
      elsif self.type == :date
        value = "(#{value}.blank? ? nil : Date.civil(#{line}[#{start+4}..#{start+7}].to_i, #{line}[#{start+2}..#{start+3}].to_i, #{line}[#{start+0}..#{start+1}].to_i))"
      elsif self.type == :integer
        value = "#{value}.strip.to_i"
      elsif self.type == :float
        # size = self.format.split(".")[0].to_i
        # value = "(#{line}[#{start}..#{start+size-1}]+'.'+#{line}[#{start+size+1}..#{start+self.length-1}]).to_d"
        value = "#{value}.gsub(',', '.').to_d"
      elsif self.type == :string
        if "Une phrase spéciale".respond_to?(:encode)
          value = "#{value}.strip.encode('UTF-8')"
        else
          value = "Iconv.conv('UTF-8', 'ISO8859-1', #{value}.strip)"
        end
      end
      return value
    end

    def format_value(variable)
      if self.type == :boolean
        value = "(#{variable} ? '1' : '0')"
      elsif self.type == :date
        value = "(#{variable}.nil? ? '#{' '*8}' : #{variable}.strftime('%d%m%Y'))"
      elsif self.type == :integer
        value = "#{variable}.to_i.to_s.rjust(#{self.length})[0..#{self.length-1}]"
      elsif self.type == :float
        size = self.format.split(".")
        value = "(#{variable}.to_i.to_s+','+((#{variable}-#{variable}.to_i)*#{10**size[1].to_i}).to_i.abs.to_s.rjust(#{size[1].to_i}, '0')).rjust(#{self.length})[0..#{self.length-1}]"
      elsif self.type == :string
        value = "#{variable}.to_s.rjust(#{self.length})[0..#{self.length-1}]"
      end
      return value
    end

  end


  class Line
    attr_reader :name, :key, :cells, :children, :to

    def initialize(name, key, cells, children=[], to=nil)
      @name = name.to_sym
      @key = key
      @cells = [] # ActiveSupport::OrderedHash.new
      for cell in cells
        for name, definition in cell
          unless c = Cell.new(name, definition, @key.length+@cells.inject(0){|s,c| s += c.length})
            raise "Element #{@name} has an cell #{name} with no definition"
          end
          @cells << c
        end
      end if cells
      @children = SVF.occurrencify(children||[])
      @to = to
    end

    def class_name(prefix=nil)
      if prefix.nil?
        @name.to_s.classify
      else
        "SVF::#{prefix.to_s.classify}::Lines::#{self.class_name}"
      end
    end

    def inspect
      i = "#{self.name}(#{self.key}) #{@cells.inspect}"
      i << "\n"+@children.collect{|c| c.inspect.gsub(/^/, '  ')}.join("\n") if @children.size > 0
      return i
    end

    def has_cells?
      return !@cells.size.zero?
    end

    def has_children?
      return !@children.size.zero?
    end

  end


  class Occurrence
    attr_reader :name, :range, :line
    def initialize(name, definition)
      @name = name.to_s
      @line, @range = @name, definition
      if definition.to_s.match('-')
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
      elsif @range.match(/\.\./)
        pr = @range.split(/\.\./)[0..1]
        pr[1] = -1 if pr[1].blank?
        @range = pr[0].to_i..pr[1].to_i
      end
    end
  end


  class Formater
    attr_reader :name, :lines

    def initialize(name, file)
      @name = name
      source = YAML.load_file(file)
      @lines = {}
      for name, line in source["lines"]
        @lines[name.to_sym] = Line.new(name, line["key"], line["cells"], line["children"], line["to"])
      end
      @root = SVF.occurrencify(source["root"])
    end

    def generate()
      code  = "module #{@name.to_s.classify}\n"

      code << "\n  module Lines\n\n"
      for element in @lines.values
        code << compile_element(element).gsub(/^/, '    ')
      end
      code << "  end\n\n"

      code << "  class Base\n"
      code << "    attr_accessor "+@lines.keys.collect{|x| ":#{x}"}.join(', ')+"\n\n"
      code << "    def initialize()\n"
      code << "    end\n\n"
      code << "    def self.parse_line(line)\n"
      code << "      return nil if line.nil?\n"
      code << "      "
      for line in @lines.values
        code << "if line.match(/^#{line.key.gsub(' ', '\\ ')}/)\n"
        code << "        #{line.class_name(@name)}.new("+line.cells.collect{|c| c.parse_value}.join(', ')+")\n"
        # code << "        #{line.class_name(@name)}.parse(line)\n"
        code << "      els"
      end
      code << "e\n"
      code << "        return nil\n"
      code << "      end\n"
      code << "    end\n\n"

      code << "    def self.parse(file)\n"
      code << "      base = Base.new\n"
      code << "      ::File.open(file, 'rb:ISO8859-1') do |f|\n"
      code << "        line_number = 0\n"
      code << parse_code(@root, :file => 'f', :root => 'base').strip.gsub(/^/, '        ')+"\n"
      code << "      end\n"
      code << "      return base\n"
      code << "    end\n\n"

      code << "    # Build file as a string\n"
      code << "    def to_s\n"
      code << "      _string = ''\n"
      code << build_code(@root, :variable => '_string', :root => 'self').strip.gsub(/^/, '      ')+"\n"
      code << "      return _string\n"
      code << "    end\n\n"

      code << "  end\n\n"

      code << "  # Shortcut to parse #{@name.to_s.classify} files\n"
      code << "  def self.parse(file)\n"
      code << "    return Base.parse(file)\n"
      code << "  end\n\n"

      code << "end\n"
      # list = code.split("\n"); list.each_index{|x| puts((x+1).to_s.rjust(4)+": "+list[x])}
      return code
    end




    def compile_element(element, depth=0)
      code  = "class #{element.class_name}\n"
      code << "  attr_accessor "+element.cells.collect{|c| ":#{c.name}"}.join(', ')+"\n" if element.has_cells?
      code << "  attr_accessor "+element.children.collect{|c| ":#{c.name}"}.join(', ')+"\n" if element.has_children?
      code << "  attr_accessor :text\n" if element.to
      for bool in element.cells.select{|c| c.type == :boolean}
        code << "  alias :#{bool.name}? :#{bool.name}\n"
      end
      code << "  def initialize("+element.cells.collect{|c| c.name}.join(', ')+")\n"
      code << "    "+element.cells.collect{|c| "@#{c.name}"}.join(', ')+" = "+element.cells.collect{|c| c.name}.join(', ')+"\n" if element.has_cells?
      childz = element.children.select{|c| c.range.max != 1}
      code << "    "+childz.collect{|c| "@#{c.name}"}.join(', ')+" = "+childz.collect{|c| "[]"}.join(', ')+"\n" unless childz.empty?
      code << "    @text = ''\n" if element.to
      code << "  end\n"
      code << "  def to_s\n"
      if element.to
      else
        code << "    '#{element.key}'+"+element.cells.collect{|c| c.format_value("@#{c.name}")}.join("+")+"+\"\\r\\n\"\n"
      end
      code << "  end\n"
      # code << "  def self.parse(line)\n"
      # code << "    raise StandardError.new(\"Bad key used for #{element.class_name}: '#{element.key}' expected, got '\#{line[0..#{element.key.length-1}]}'\") if line[0..#{element.key.length-1}] != '#{element.key}'\n"
      # code << "    return #{element.class_name}.new("+element.cells.collect{|c| c.parse_value}.join(', ')+")\n"
      # code << "  end\n"
      code << "end\n\n"
      return code
    end



    def parse_code(siblings=[], options={})
      parents, all_parents = options[:parents]||[], options[:all_parents]||[]
      code  = ''
      code << "line = self.parse_line(#{options[:file]}.gets)\n"
      code << "line_number += 1\n"
      code << "while (line)\n"
      # code << "  puts \"\#{__LINE__} \#{line.class.name}\"\n"
      # code << "  puts line.inspect\n"
      code << "  "
      for sibling in siblings
        line = @lines[sibling.line]
        full_name = "#{options[:root].to_s+'.' if options[:root]}#{sibling.name}"
        code << "if line.is_a?(#{line.class_name(@name)})\n"
        new_line = (line.has_children? ? sibling.line : 'line')
        code << "    #{sibling.line} = line\n" if line.has_children?
        if sibling.range.max == 1
          code << "    #{full_name} = #{new_line}\n"
        else
          code << "    #{full_name} << #{new_line}\n"
        end
        if line.to
          code << "    line = #{options[:file]}.gets\n"
          code << "    line_number += 1\n"
          code << "    while (!line.nil? and line.match(/^#{line.to.gsub(/\ /, '\\ ')}\\ *$/))\n"
          code << "      #{full_name}.text << line\n"
          code << "      line = #{options[:file]}.gets\n"
          code << "      line_number += 1\n"
          code << "    end\n"
        end
        if line.has_children?
          code << parse_code(line.children, :file => options[:file], :root => sibling.line, :parents => siblings, :all_parents => siblings+all_parents).strip.gsub(/^/, '    ')+"\n"
        else
          code << "    line = self.parse_line(#{options[:file]}.gets)\n"
          code << "    line_number += 1\n"
        end
        code << "  els"
      end
      if parents.size > 0

        code << "if ["+all_parents.collect{|s| raise([s, s.line].inspect) if @lines[s.line].nil?; @lines[s.line].class_name(@name)}.sort.join(', ')+"].include?(line.class)\n"
        # code << "if "+all_parents.collect{|s| "line.is_a?(#{@lines[s.line].class_name(@name)})"}.join(" or ")+"\n"
        code << "    break\n"
        code << "  else\n"
        rep = '[#{__LINE__}]'
        code << "    raise StandardError.new(\"#{rep} Unexpected element at line \#{line_number}: \#{line.class.name}:\#{line.inspect}\")\n"
      else
        code << "e\n"
        code << "    raise StandardError.new(\"#{rep} Unexpected element at line \#{line_number}: \#{line.class.name}:\#{line.inspect}\")\n"
      end
      code << "  end\n"


      code << "end\n"
      return code
    end


    def build_code(siblings, options={})
      code  = ''
      var, root = options[:variable], options[:root].to_s
      # code << "_string )\n"
      for sibling in siblings
        line = @lines[sibling.line]
        full_name = "#{root+'.' if options[:root]}#{sibling.name}"
        code << "if #{sibling.name} = #{full_name}\n"
        if sibling.range.max == 1
          code << "  #{var} << #{sibling.name}.to_s\n"
          code << build_code(line.children, :variable => var, :root => sibling.line).strip.gsub(/^/, '  ')+"\n" if line.has_children?
        else
          code << "  for #{sibling.line} in #{sibling.name}\n"
          code << "    #{var} << #{sibling.line}.to_s\n"
          code << build_code(line.children, :variable => var, :root => sibling.line).strip.gsub(/^/, '    ')+"\n" if line.has_children?
          code << "  end\n"
        end
        code << "end\n"
      end
      return code
    end


  end


  def self.occurrencify(array)
    occurrences = []
    for items in array
      for name, definition in items
        occurrences << Occurrence.new(name, definition)
      end
    end
    return occurrences
  end


end


# Load Parser/Exporter based on SVF structures
SVF.load(:isa_8550, Rails.root.join('lib', 'exchanges', 'svf', 'isa-8550.yml'))
# SVF.load(:isa_8700, Rails.root.join('lib', 'exchanges', 'svf', 'isa-8700.yml'))


# isa = SVF::Isa8550.parse(Rails.root.join("FDSEA-1998.ISA"))
# SVF.load(:isa_8700, Rails.root.join('lib', 'exchanges', 'svf', 'isa-8700.yml'))
# isa = SVF::Isa8700.parse(Rails.root.join("FDSEA-1998.ISA"))

# File.open(Rails.root.join("FDSEA-1998-2.ISA"), "wb") do |f|
#   f.write isa.to_s
# end
# raise isa.to_s
