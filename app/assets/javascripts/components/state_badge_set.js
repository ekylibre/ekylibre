function StateSet(selector, base){
  this.$element = $(selector)
  this.base = base
}

StateSet.prototype._getStateClasses = function () {
  const classes = this.$element.attr('class')
  if (classes) {
    var that = this
    return classes.split(/\s+/)
      .filter(function (e) {
        return e.match(new RegExp("^" + that.base + "--(.*)$"))
      })
  } else {
    return []
  }
}
StateSet.prototype.setState = function (state) {
  this.$element
    .removeClass(this._getStateClasses().join(' '))

  if (state)
    this.$element.addClass(this.base + '--' + state)
}

function StateBadgeSet(selector) {
  StateSet.call(this, selector, 'state-badge-set')
}
StateBadgeSet.prototype = Object.create(StateSet.prototype)