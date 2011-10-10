# Spaced Values Format
module SVF
end

dir = File.join(File.dirname(__FILE__), 'svf')
require File.join(dir, 'loader')

SVF.load(:isa, File.join(dir, 'isa.yml'))
