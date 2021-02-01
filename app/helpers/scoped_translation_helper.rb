module ScopedTranslationHelper
  # TODO: Put this back into the module after Rails 5 upgrade
  class << self
    def i18n_scope
      @i18n_scope ||= ''
    end

    def i18n_scope_set(*scope)
      @i18n_scope = translation_key *scope
    end

    def with_i18n_scope(*parts, replace: false)
      orig = i18n_scope
      if replace
        i18n_scope_set parts
      else
        i18n_scope_set i18n_scope, parts
      end

      begin
        result = yield
      ensure
        i18n_scope_set orig
      end

      result
    end

    def translation_key(*parts)
      parts.flatten.map(&:to_s).join('.')
    end
  end

  def with_i18n_scope(*parts, replace: false, &block)
    ScopedTranslationHelper.with_i18n_scope *parts, replace: replace, &block
  end

  def stl(unit, **options)
    return unit if unit.is_a?(String) && unit == ''

    t ScopedTranslationHelper.translation_key(ScopedTranslationHelper.i18n_scope, unit), options
  end
end
