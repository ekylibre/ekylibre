class UpdateInvalidProductNatureVariants < ActiveRecord::Migration
  def up
    execute "UPDATE product_natures AS pn SET variety = 'preparation' WHERE variety != 'preparation' AND reference_name = 'organic_fertilizer'"
  end
end
