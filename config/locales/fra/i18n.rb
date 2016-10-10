# -*- coding: utf-8 -*-
{ fra: {
  i18n: {
    dir: 'ltr',
    iso2: 'fr',
    name: 'Français',
    plural: {
      keys: [:one, :other],
      rule: ->(n) { n < 2 ? :one : :other }
    }
  },
  date: {
    order: [:day, :month, :year]
  }
} }
