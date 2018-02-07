module Products
  class SearchVariantByExpressionQuery
    def self.call(relation, scope, input_text, max)
      result = relation
                 .availables
                 .of_expression(scope)

      result = result.select {|product| product.name.include?(input_text)} unless input_text.blank?

      result
        .to_a
        .take(max.to_i)
    end
  end
end