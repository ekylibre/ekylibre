# -*- coding: utf-8 -*-
{ arb: {
  i18n: {
    dir: 'rtl',
    iso2: 'ar',
    name: 'لعربية',
    plural: {
      keys: %i[zero one two few many other],
      #        :rule=> lambda { |n| n == 1 ? :one : n == 2 ? :two : (3..10).include?(n % 100) ? :few : (11..99).include?(n % 100) ? :many : :other }
      rule: ->(n) { n == 1 ? :one : :other } # Use the english rule temporarly

    }
  },
  date: {
    order: %i[month day year]
  }
} }
