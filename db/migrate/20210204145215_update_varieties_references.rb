class UpdateVarietiesReferences < ActiveRecord::Migration[5.0]

  VARIETY_CHANGES = [
    %w[malus_pumila malus_domestica],
    %w[allium_ascalonicum allium_cepa_aggregatum],
    %w[rosmarinus salvia_rosmarinus],
    %w[triticosecale x_triticosecale],
    %w[curcuma_aromatica curcuma_longa]
  ].freeze

  TABLE_COLUMNS = [
    %w[product_natures variety], %w[product_natures derivative_of],
    %w[product_nature_variants variety], %w[product_nature_variants derivative_of],
    %w[products variety], %w[products derivative_of],
    %w[activities cultivation_variety], %w[manure_management_plan_zones cultivation_variety]
  ].freeze

  def change
    request = VARIETY_CHANGES.flat_map do |(former_variety, new_variety)|
      TABLE_COLUMNS.map do |(table, column)|
        <<~SQL
          UPDATE #{table}
            SET #{column} = '#{new_variety}'
          WHERE #{column} = '#{former_variety}'
        SQL
      end
    end

    execute request.join(';')
  end
end
