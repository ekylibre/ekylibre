{ ita: {
    i18n: {
      dir: 'ltr',
      iso2: 'it',
      name: 'Italiano',
      plural: {
        keys: [:one, :other],
        rule: ->(n) { n == 1 ? :one : :other }
      }
    },
    date: {
      order: [:month, :day, :year]
    }
  }
}
