module Products
  class SearchVariantByExpressionQuery
    def self.call(relation, scope, input_text, max)
      result = relation
               .availables
               .of_expression(scope)

      result = result.select { |product| product.name.downcase.include?(input_text.mb_chars.downcase) } if input_text.present?

      result
        .to_a
        .take(max.to_i)
    end
  end
end
