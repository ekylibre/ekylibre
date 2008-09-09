# = Localized country names
# 
# Localizes the country list of the FormOptionsHelper module. This country list
# is used by some helpers of this module (ie. +country_options_for_select+).
# 
# == Used sections of the language file
# 
#   countries:
#     Germany: Deutschland
# 
# This feature uses the +countries+ section of the language file. This section
# contains a map used to replace the default countries with the ones specified.
# This is a simple replace operation so you don't need to translate all
# countries for this feature to work.

silence_warnings do
  ActionView::Helpers::FormOptionsHelper::COUNTRIES = ArkanisDevelopment::SimpleLocalization::CachedLangSectionProxy.new :sections => [:countries],
  :orginal_receiver => ActionView::Helpers::FormOptionsHelper::COUNTRIES do |localized, orginal|
    orginal.collect{|original_country| localized[original_country] || original_country}
  end
end