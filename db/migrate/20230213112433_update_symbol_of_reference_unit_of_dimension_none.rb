class UpdateSymbolOfReferenceUnitOfDimensionNone < ActiveRecord::Migration[5.2]
  def up
    ReferenceUnit.joins(:base_unit).where(base_units_units: { reference_name: :unity }).all.each do |unit|
      onoma_unit = Onoma::Unit.find(unit.reference_name)
      if onoma_unit && unit.symbol != onoma_unit.symbol
        unit.update(symbol: onoma_unit.symbol)
      end
    end 
  end
end
