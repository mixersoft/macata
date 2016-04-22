'use strict'
global = @

bootstrap = ()->
  # angular.bootstrap ['macata.server']

  # from package erasaur:meteor-lodash
  global._ = lodash
  console.log(['lodash.VERSION=', global._.VERSION, lodash.VERSION])
  return

Meteor.startup(bootstrap)
