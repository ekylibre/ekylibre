module SVF
  class Formater
    attr_reader :name, :lines

    def initialize(name, file)
      @name = name
      source = YAML.load_file(file)
      @lines = {}
      for name, line in source['lines']
        @lines[name.to_sym] = Line.new(name, line['key'], line['cells'], line['children'], line['to'])
      end
      @root = SVF.occurrencify(source['root'])
    end

    def generate
      code  = "module #{@name.to_s.classify}\n"

      code << "\n  module Lines\n\n"
      for element in @lines.values
        code << compile_element(element).gsub(/^/, '    ')
      end
      code << "  end\n\n"

      code << "  class Base\n"
      code << '    attr_accessor ' + @lines.keys.collect { |x| ":#{x}" }.join(', ') + "\n\n"
      code << "    def initialize()\n"
      code << "    end\n\n"
      code << "    def self.parse_line(line)\n"
      code << "      return nil if line.nil?\n"
      code << '      '
      for line in @lines.values
        code << "if line.match(/^#{line.key.gsub(' ', '\\ ')}/)\n"
        code << "        #{line.class_name(@name)}.new(" + line.cells.collect(&:parse_value).join(', ') + ")\n"
        # code << "        #{line.class_name(@name)}.parse(line)\n"
        code << '      els'
      end
      code << "e\n"
      code << "        return nil\n"
      code << "      end\n"
      code << "    end\n\n"

      code << "    def self.parse(file)\n"
      code << "      base = Base.new\n"
      code << "      ::File.open(file, 'rb:ISO8859-1') do |f|\n"
      code << "        line_number = 0\n"
      code << parse_code(@root, file: 'f', root: 'base').strip.gsub(/^/, '        ') + "\n"
      code << "      end\n"
      code << "      return base\n"
      code << "    end\n\n"

      code << "    # Build file as a string\n"
      code << "    def to_s\n"
      code << "      _string = ''\n"
      code << build_code(@root, variable: '_string', root: 'self').strip.gsub(/^/, '      ') + "\n"
      code << "      return _string\n"
      code << "    end\n\n"

      code << "  end\n\n"

      code << "  # Shortcut to parse #{@name.to_s.classify} files\n"
      code << "  def self.parse(file)\n"
      code << "    return Base.parse(file)\n"
      code << "  end\n\n"

      code << "end\n"
      # list = code.split("\n"); list.each_index{|x| puts((x+1).to_s.rjust(4)+": "+list[x])}
      code
    end

    def compile_element(element, _depth = 0)
      code  = "class #{element.class_name}\n"
      code << '  attr_accessor ' + element.cells.collect { |c| ":#{c.name}" }.join(', ') + "\n" if element.has_cells?
      code << '  attr_accessor ' + element.children.collect { |c| ":#{c.name}" }.join(', ') + "\n" if element.has_children?
      code << "  attr_accessor :text\n" if element.to
      for bool in element.cells.select { |c| c.type == :boolean }
        code << "  alias :#{bool.name}? :#{bool.name}\n"
      end
      code << '  def initialize(' + element.cells.collect(&:name).join(', ') + ")\n"
      code << '    ' + element.cells.collect { |c| "@#{c.name}" }.join(', ') + ' = ' + element.cells.collect(&:name).join(', ') + "\n" if element.has_cells?
      childz = element.children.select { |c| c.range.max != 1 }
      code << '    ' + childz.collect { |c| "@#{c.name}" }.join(', ') + ' = ' + childz.collect { |_c| '[]' }.join(', ') + "\n" unless childz.empty?
      code << "    @text = ''\n" if element.to
      code << "  end\n"
      code << "  def to_s\n"
      if element.to
      else
        code << "    '#{element.key}'+" + element.cells.collect { |c| c.format_value("@#{c.name}") }.join('+') + "+\"\\r\\n\"\n"
      end
      code << "  end\n"
      # code << "  def self.parse(line)\n"
      # code << "    raise StandardError.new(\"Bad key used for #{element.class_name}: '#{element.key}' expected, got '\#{line[0..#{element.key.length-1}]}'\") if line[0..#{element.key.length-1}] != '#{element.key}'\n"
      # code << "    return #{element.class_name}.new("+element.cells.collect{|c| c.parse_value}.join(', ')+")\n"
      # code << "  end\n"
      code << "end\n\n"
      code
    end

    def parse_code(siblings = [], options = {})
      parents = options[:parents] || []
      all_parents = options[:all_parents] || []
      code  = ''
      code << "line = self.parse_line(#{options[:file]}.gets)\n"
      code << "line_number += 1\n"
      code << "while (line)\n"
      code << '  '
      for sibling in siblings
        line = @lines[sibling.line]
        full_name = "#{options[:root].to_s + '.' if options[:root]}#{sibling.name}"
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
          code << parse_code(line.children, file: options[:file], root: sibling.line, parents: siblings, all_parents: siblings + all_parents).strip.gsub(/^/, '    ') + "\n"
        else
          code << "    line = self.parse_line(#{options[:file]}.gets)\n"
          code << "    line_number += 1\n"
        end
        code << '  els'
      end
      if parents.size > 0

        code << 'if [' + all_parents.collect { |s| fail([s, s.line].inspect) if @lines[s.line].nil?; @lines[s.line].class_name(@name) }.sort.join(', ') + "].include?(line.class)\n"
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
      code
    end

    def build_code(siblings, options = {})
      code  = ''
      var = options[:variable]
      root = options[:root].to_s
      # code << "_string )\n"
      for sibling in siblings
        line = @lines[sibling.line]
        full_name = "#{root + '.' if options[:root]}#{sibling.name}"
        code << "if #{sibling.name} = #{full_name}\n"
        if sibling.range.max == 1
          code << "  #{var} << #{sibling.name}.to_s\n"
          code << build_code(line.children, variable: var, root: sibling.line).strip.gsub(/^/, '  ') + "\n" if line.has_children?
        else
          code << "  for #{sibling.line} in #{sibling.name}\n"
          code << "    #{var} << #{sibling.line}.to_s\n"
          code << build_code(line.children, variable: var, root: sibling.line).strip.gsub(/^/, '    ') + "\n" if line.has_children?
          code << "  end\n"
        end
        code << "end\n"
      end
      code
    end
  end
end
