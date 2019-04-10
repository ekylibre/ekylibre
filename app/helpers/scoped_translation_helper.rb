module ScopedTranslationHelper
  def stl(unit, **options)
    return unit if unit.is_a?(String) && unit == ''
    t translation_key(i18n_scope, unit), options
  end

  def with_i18n_scope(*parts, replace: false)
    orig = i18n_scope
    if replace
      i18n_scope_set parts
    else
      i18n_scope_set i18n_scope, parts
    end
    result = yield
    i18n_scope_set orig

    result
  end

  def i18n_scope
    @i18n_scope ||= ''
  end

  def i18n_scope_set(*scope)
    @i18n_scope = translation_key *scope
  end

  private

    def translation_key(*parts)
      parts.flatten.map(&:to_s).join('.')
    end
end
