# encoding: utf-8
desc "Create schema_hash.rb"
task :shash => :environment do
  hash = {}; 
  Company.reflections.select{|k,v| v.macro==:has_many}.each do |k,v| 
    cols={}; 
    v.class_name.constantize.columns.each do |c| 
      cols[c.name]={:null=>c.null, :type=>c.type} 
    end
    hash[k] = cols
  end
  File.open("#{RAILS_ROOT}/db/schema_hash.rb", "wb") do |f|
    f.write("# Auto-generated from Ekylibre\n")
    f.write("EKYLIBRE = "+hash.inspect)
  end
end

def annotate_one_file(file_name, info_block)
  puts "------------------------- "+ file_name.inspect
  unless File.exist?(file_name)
    File.open(file_name, "w") { |f| f.puts "# Generated" }
  end
  if File.exist?(file_name)
    content = File.read(file_name)
    lines = "\nEkylibre - Simple ERP\nCopyright (C) 2009 Brice Texier, Thibaud Mérigon\n\nThis program is free software: you can redistribute it and/or modify\nit under the terms of the GNU General Public License as published by\nthe Free Software Foundation, either version 3 of the License, or\nany later version.\n\nThis program is distributed in the hope that it will be useful,\nbut WITHOUT ANY WARRANTY; without even the implied warranty of\nMERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the\nGNU General Public License for more details.\n\nYou should have received a copy of the GNU General Public License\nalong with this program.  If not, see <http://www.gnu.org/licenses/>.\n\n".split(/[\r\n]+/).compact

    for line in lines
      unless line.match(/^\s*$/)
        #  puts line.inspect
        content.gsub!(/^#{line}$/, '#') 
      end
    end
    content.gsub!(/^Copyright.*$/, '#') 
    
    content.gsub!(/\#\n\#\n\s*\n\s*(\n\s*)?\#\n\#/, "#")
    content.gsub!(/\#\n\#\n\s*\n\s*(\n\s*)?\#\n\#/, "#")
    #    content.gsub!(/\#\s+\#/, "#")
    #    content.gsub!(/\#\s+\#/, "#")
    #    content.gsub!(/\#\s+\#/, "#")

    # puts content
    # Remove old schema info
    # content.sub!(/^# #{PREFIX}.*?\n(#.*\n)*\n/, '')
    
    
    # Write it back
    File.open(file_name, "wb") { |f| f.puts(content) }
  end
end

desc ""
task :lig do
  models = []
  Dir.chdir("app/models") do 
    models = Dir["**/*.rb"].sort
  end
  
  info =  "\nEkylibre - Simple ERP\nCopyright (C) 2009 Brice Texier, Thibaud Mérigon\n\nThis program is free software: you can redistribute it and/or modify\nit under the terms of the GNU General Public License as published by\nthe Free Software Foundation, either version 3 of the License, or\nany later version.\n\nThis program is distributed in the hope that it will be useful,\nbut WITHOUT ANY WARRANTY; without even the implied warranty of\nMERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the\nGNU General Public License for more details.\n\nYou should have received a copy of the GNU General Public License\nalong with this program.  If not, see <http://www.gnu.org/licenses/>.\n\n"
  models.each do |m|
    cn = m.sub(/\.rb$/,'')
    class_name = m.sub(/\.rb$/,'').camelize
    begin
      
      #      klass = class_name.split('::').inject(Object){ |klass,part| klass.const_get(part) }
      #      if klass < ActiveRecord::Base && !klass.abstract_class?
      puts "Annotating #{class_name}"
      
      model_file_name = File.join("app/models", cn + ".rb")
      annotate_one_file(model_file_name, info)
      
      fixture_file_name = File.join("test/fixtures", cn.pluralize + ".yml")
      annotate_one_file(fixture_file_name, info)

      unit_file_name = File.join("test/unit", cn + "_test.rb")
      annotate_one_file(unit_file_name, info)

      #      else
      #        puts "Skipping #{class_name}"
      #      end
    rescue Exception => e
      puts "Unable to annotate #{class_name}: #{e.message}"
    end
  end

end


def color_to_array(color)
  values = []
  for i in 0..3
    values << color.to_s[2*i..2*i+1].to_s.to_i(16).to_f
  end
  values
end

def array_to_css(color)
  code = '#'
  for x in 0..2
    code += color[x].to_i.to_s(16)
  end
  code.upcase
end

def color_merge(c1, c2)
  r = []
  t = c2[3].to_f/255.to_f
  for i in 0..2
    r << c1[i]*(1-t)+c2[i]*t
  end
  r << 255.to_f
  # puts [array_to_css(c1), array_to_css(c2), c2[3], t, r].inspect
  r
end

desc "Create dyta-colors.css for the default theme"
task :dytacolor do
  
  dims = [
          {:__default__=>"D1DAFFFF", :notice=>"D8FFA3FF", :warning=>"FFE0B3FF", :error=>"FFAD87FF"}, # tr
          # {:__default__=>"E1E6FFFF", :notice=>"D8FFA3FF", :warning=>"FFE0B3FF", :error=>"FFC8BFFF"}, # tr
          {:__default__=>"FFFFFF00", :odd=>"FFFFFF70", :even=>"FFFFFF40"}, # tr
          # {:__default__=>"FFFFFF00", :act=>"AE702234", :sorted=>"1410FF20"} # td
          {:__default__=>"FFFFFF00", :act=>"FF860022", :sorted=>"00128410"} # td
          #                                 FFDDDD60             1410FF20 00128fff
         ]
  hover = color_to_array("00447730")
  dims[0][:advance]     = dims[0][:notice]
  dims[0][:late]        = dims[0][:warning]
  dims[0][:verylate]    = dims[0][:error]
  dims[0][:enough]      = dims[0][:notice]
  dims[0][:minimum]     = dims[0][:warning]
  dims[0][:critic]      = dims[0][:error]
  dims[0][:balanced]           = dims[0][:notice]
  dims[0][:unbalanced]         = dims[0][:error]
  dims[0][:pointable]          = dims[0][:notice]
  dims[0][:unpointabled]       = dims[0][:warning]
  dims[0][:unpointable]        = dims[0][:error]
  dims[0][:letter]             = dims[0][:notice]
  dims[0]['letter-unbalanced'] = dims[0][:warning]

  code = ''

  for k0, v0 in dims[0].sort{|a,b| a[0].to_s<=>b[0].to_s}
    raise Exception.new("Color must given for :#{k0}") if v0.nil?
    dim0 = (k0==:__default__ ? '' : '.'+k0.to_s)
    code += "\n/* #{k0.to_s.camelcase} */\n"
    base = color_to_array(v0)
    for k1, v1 in dims[1].sort{|a,b| a[0].to_s<=>b[0].to_s}
      raise Exception.new("Color must given for :#{k1}") if v1.nil?
      dim1 = (k1==:__default__ ? '' : '.'+k1.to_s)
      inter = color_merge(base, color_to_array(v1))
      for k2, v2 in dims[2].sort{|a,b| a[0].to_s<=>b[0].to_s}
        raise Exception.new("Color must given for :#{k2}") if v2.nil?
        dim2 = (k2==:__default__ ? '' : '.'+k2.to_s)
        last = color_merge(inter, color_to_array(v2))
        code += "table.dyta tr#{dim0}#{dim1} td#{dim2} {background:#{array_to_css(last)}}\n"
        code += "table.dyta tr#{dim0}#{dim1}:hover td#{dim2} {background:#{array_to_css(color_merge(last, hover))}}\n"
      end
    end
  end

  File.open("#{RAILS_ROOT}/public/templates/tekyla/stylesheets/dyta-colors.css", "wb") do |f|
    f.write("/* Auto-generated from Ekylibre (rake dytacolor) */\n")
    f.write(code)
  end
end
