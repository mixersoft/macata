'use strict'

HandyStuff = ($window, $document, amMoment) ->
  self = {
    # format img.src as background img
    # usage: img.hero(ng-style="{{imgInBg(url)}}")
    imgAsBg: (url)->
      return {
        'background': "url({src}) center center".replace('{src}', url)
        'background-size': 'cover'
      }
    getChildOfParent: (el, parentClass, childSelector)->
      el = el[0] if el instanceof angular.element
      parent = ionic.DomUtil.getParentWithClass(el, parentClass)
      return child = parent.querySelector(childSelector)

    range: (min, max, step)->
      step ?= 1
      range = (x for x in [min..max] by step)
      return range
  }
  return self


HandyStuff.$inject = ['$window', '$document', 'amMoment']

angular.module 'starter.core'
  .factory 'utils', HandyStuff
