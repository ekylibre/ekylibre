# -*- coding: utf-8 -*-
{ spa: {
  i18n: {
    dir: 'ltr',
    iso2: 'es',
    name: 'Español',
    plural: {
      keys: %i[one other],
      rule: ->(n) { n == 1 ? :one : :other }
    }
  },
  date: {
    order: %i[day month year]
  }
} }
