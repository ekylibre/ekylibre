# coding: utf-8

{ por: {
  i18n: {
    dir: 'ltr',
    iso2: 'pt',
    name: 'Português',
    plural: {
      keys: %i[one other],
      rule: ->(n) { n < 2 ? :one : :other }
    }
  },
  date: {
    order: %i[day month year]
  }
} }
