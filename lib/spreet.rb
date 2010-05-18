require 'fastercsv'
require 'spreadsheet'



# Abstract Simple SpreadSheet
# Take only the first sheet
class Spreet

  @@formats = [:csv, :xcsv]

  # Open a spreadsheet to read it
  def open(file, format=:csv)
    @format = format.to_sym
    @handler = case @format
               when :csv
                 FasterCSV.open(file)
               when :xcsv
                 FasterCSV.open(file, :col_sep=>';', :encoding=>'cp1252')
               else
                 raise ArgumentError.new("Unknown format #{format.inspect} (accepts only #{@@formats.to_sentence})")                 
               end
  end


  def shift
    @handler.shift
  end

end


    
