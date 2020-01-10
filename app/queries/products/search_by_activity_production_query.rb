module Products
  class SearchByActivityProductionQuery
    def self.call(relation, activity_production: nil)
      relation
        .where(product_id: Product.where(activity_production: activity_production))
    end
  end
end
