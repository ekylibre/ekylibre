module Backend
  module FinancialYearHelper
    def warnings(financial_year, **collections)
      warning_htmls = collections.map do |keyword, collection_or_method|
        collection = fetch_collection(financial_year, collection_or_method)
        next unless collection.any?
        render("backend/financial_years/close/warning_#{keyword}", financial_year: financial_year).html_safe
      end
      warning_htmls.compact.join("\n").html_safe
    end

    def checks(financial_year, **check_statuses)
      check_htmls = check_statuses.map do |keyword, status|
        render("backend/financial_years/close/check_#{keyword}", financial_year: financial_year, success: status).html_safe
      end
      check_htmls.join("\n").html_safe
    end

    private

      def fetch_collection(financial_year, collection_or_method)
        return financial_year.send(collection_or_method) if collection_or_method.is_a? Symbol
        collection_or_method
      end
  end
end
