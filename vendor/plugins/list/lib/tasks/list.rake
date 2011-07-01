
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


namespace :list do

  desc "Create public/stylesheets/list-colors.css"
  task :css do
    
#     dims = [
#             {:__default__=>"D1DAFFFF", :notice=>"D8FFA3FF", :warning=>"FFE0B3FF", :error=>"FFAD87FF"}, # tr
#             # {:__default__=>"E1E6FFFF", :notice=>"D8FFA3FF", :warning=>"FFE0B3FF", :error=>"FFC8BFFF"}, # tr
#             {:__default__=>"FFFFFF00", :odd=>"FFFFFF70", :even=>"FFFFFF40"}, # tr
#             # {:__default__=>"FFFFFF00", :act=>"AE702234", :sorted=>"1410FF20"} # td
#             {:__default__=>"FFFFFF00", :act=>"FF860022", :sor=>"00128410"} # td
#             #                                 FFDDDD60             1410FF20 00128fff
#            ]

    dims = [
            {:__default__=>"FFFFFFFF", :notice=>"D8FFA3FF", :warning=>"FFE0B3FF", :error=>"FFAD87FF", :subtotal=>"FFFFDDFF", :disabled=>"EEEEEEFF", :validated=>"EAFAEFFF"}, # tr
            {:__default__=>"FFFFFF00", :odd=>"FFFFFF70", :even=>"FFFFFF70"}, # tr
            {:__default__=>"FFFFFF00", :act=>"FF860022", :sor=>"0012840D"} # td
           ]
    # hover = color_to_array("00447730")
    hover = color_to_array("D1DAFF50")
    dims[0][:estimate]      = dims[0][:notice]
    dims[0][:order]         = dims[0][:warning]
    dims[0][:unpaid]        = dims[0][:error]

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
          code += "table.list tr#{dim0}#{dim1} td#{dim2} {background:#{array_to_css(last)}}\n"
          code += "table.list tr#{dim0}#{dim1}:hover td#{dim2} {background:#{array_to_css(color_merge(last, hover))}}\n"
        end
      end
    end

    File.open(Rails.root.join("app", "assets", "stylesheets", "list-colors.css"), "wb") do |f|
      f.write("/* Auto-generated from plugin List (rake list:css) */\n")
      f.write(code)
    end
  end

end
