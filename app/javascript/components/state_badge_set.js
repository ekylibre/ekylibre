export class StateSet {
  constructor(selector, base) {
    this.$element = $(selector)
    this.base = base
  }

  _getStateClasses() {
    const classes = this.$element.attr('class')
    if (classes) {
      return classes.split(/\s+/).filter(e => e.match(new RegExp(`^${this.base}--(.*)$`)))
    } else {
      return []
    }
  }

  setState(state) {
    this.$element.removeClass(this._getStateClasses().join(' '))

    if (state)
      this.$element.addClass(`${this.base}--${state}`)
  }
}

export class StateBadgeSet extends StateSet {
  constructor(selector) {
    super(selector, 'state-badge-set')
  }
}
