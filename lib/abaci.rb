module Abaci
  autoload :Row,   'abaci/row'
  autoload :Table, 'abaci/table'

  # Read a CSV abaci and returns an Abaci::Table
  def self.read(file)
    Abaci::Table.new(file)
  end
end
