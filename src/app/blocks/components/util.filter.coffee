'use strict'

###
# @description filter event.feed for demo data
###
DateFilter = ()->
  return (rows, field)->
    field ?= 'createdAt'
    sorted = _.sortBy rows, field
    return sorted

MostRecentFilter = ()->
  return (rows, field)->
    field ?= 'createdAt'
    sorted = _.sortBy rows, field
    return sorted.reverse()

angular.module 'blocks.components'
  .filter 'dateFilter', DateFilter
  .filter 'mostRecentFilter', MostRecentFilter
