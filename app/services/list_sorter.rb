class ListSorter
  # @param [#to_s] reference name
  # @param [Array<#name>] array of object that responds to #read
  def initialize(reference_name, list)
    @list = list
    @references = Ekylibre::Application.config.sorting_reference[reference_name.to_s]
  end

  # @return [Array<#name>] sorted list
  def sort
    @list.sort_by{ |a| @references.index(a.name) || Float::INFINITY }
  end
end
