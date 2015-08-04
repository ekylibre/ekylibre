module SVF
  autoload :Cell,      'svf/cell'
  autoload :Formater,  'svf/formater'
  autoload :Line,      'svf/line'
  autoload :Occurence, 'svf/occurrence'

  # Build submodule to handle format defined in the file
  # Format must be defined in YAML
  def self.load(name, file)
    # raise Formater.new(name, file).generate
    module_eval(Formater.new(name, file).generate)
  end

  # Convert an array of items to an array of occurrences
  def self.occurrencify(array)
    occurrences = []
    for items in array
      for name, definition in items
        occurrences << Occurrence.new(name, definition)
      end
    end
    occurrences
  end

  # Returns the default path where the norms are loaded
  def norms_path
    Pathname.new(__FILE__).dirname.join('svf', 'norms')
  end
end

# Load Parser/Exporter based on SVF structures
SVF.load(:isacompta_8550, SVF.norms_path.join('isacompta', '8550.yml'))
# SVF.load(:isacompta_8700, SVF.norms_path.join('isacompta', '8700.yml'))
