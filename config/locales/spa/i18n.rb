{ :spa=>{
    :i18n=>{
      :dir=>'ltr',
      :iso2=>'es',
      :name=>'Español',
      :plural=>{
        :keys=> [:one, :other],
        :rule=> lambda { |n| n == 1 ? :one : :other }
      }
    }
  }
}
