module Autocomplete
  extend ActiveSupport::Concern

  module ClassMethods
    # Autocomplete helper
    def autocomplete_for(*columns)
      options = columns.extract_options!
      model = (options.delete(:model) || controller_name).to_s.classify.constantize
      columns = columns.map(&:to_s)
      define_method :autocomplete do
        unless params[:q]
          head :bad_request
          return
        end
        column = params[:column]
        unless column && columns.include?(column)
          head :bad_request
          return
        end
        pattern = '%' + params[:q].to_s.mb_chars.downcase.strip.gsub(/\s+/, '%').gsub(/[#{String::MINUSCULES.join}]/, '_') + '%'
        start_pattern = params[:q].to_s.mb_chars.downcase.strip.gsub(/\s+/, '%').gsub(/[#{String::MINUSCULES.join}]/, '_') + '%'
        start_ordering = 'CASE WHEN ' + model.send(:sanitize_sql_array, ["#{column} ILIKE E?", start_pattern]) + ' THEN -1 ELSE 1 END'
        items = model
                .select("DISTINCT #{column}, #{start_ordering}")
                .where("#{column} ILIKE ?", pattern)
                .group(column)
                .reorder(start_ordering)
                .order(column => :asc)
                .limit(15)
        respond_to do |format|
          format.html { render inline: '<%= content_tag(:ul, items.map { |item| content_tag(:li, item.send(column)) }.join.html_safe) %>' }
          format.json { render json: items.map { |item| item.send(column) }.to_json }
        end
      end
    end
  end
end
