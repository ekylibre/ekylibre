# Helper for exports views
module Backend::ExportsHelper
  # Returns the export categories based on document categories nomenclature
  def export_categories
    Nomen::DocumentCategory.to_a
                           .select { |category| Aggeratio.of_category(category).any? }
                           .map { |c| Nomen::DocumentCategory[c] }
                           .sort_by { |a| a.human_name.ascii }
  end
end
