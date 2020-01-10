import 'whatwg-fetch'
import {StateSet, StateBadgeSet} from "components/state_badge_set"
import {customFetch, ajax} from "services/ajax"
import RBush from "rbush"
import * as moment from 'moment'

export let Ekylibre = {
  fetch: customFetch,
  ajax: ajax
}

export let globals = {
  visualization: {},
  mapeditor: {},
  calcul: {},
  golumn: {},
  StateSet: StateSet,
  StateBadgeSet: StateBadgeSet
}

export let vendors = {
  _: require('lodash'),
  RBush: RBush,
  moment: moment
}

