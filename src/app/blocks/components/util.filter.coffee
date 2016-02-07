'use strict'

###
# @description filter event.feed for demo data
###
DateFilter = ()->
  return (rows, field)->
    return [] if !rows?.length
    field ?= 'createdAt'
    if rows[0].head
      sorted = _.sortBy rows, (o)->return o.head[field]
    else
      sorted = _.sortBy rows, field
    return sorted

MostRecentFilter = ()->
  return (rows, field)->
    return [] if !rows?.length
    field ?= 'createdAt'
    if rows[0].head
      sorted = _.sortBy rows, (o)->return o.head[field]
    else
      sorted = _.sortBy rows, field
    return sorted.reverse()

angular.module 'blocks.components'
  .filter 'dateFilter', DateFilter
  .filter 'mostRecentFilter', MostRecentFilter
