{ eng: {
  i18n: {
    dir: 'ltr',
    iso2: 'en',
    name: 'English',
    plural: {
      keys: %i[one other],
      rule: ->(n) { n == 1 ? :one : :other }
    }
  },
  date: {
    order: %i[month day year]
  }
} }
