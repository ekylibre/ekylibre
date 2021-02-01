module IdHumanizable
  extend ActiveSupport::Concern
  # Permits to consider something and something_id like the same
  def human_attribute_name(attribute, options = {})
    super(attribute.to_s.gsub(/_id\z/, ''), options)
  end
end
