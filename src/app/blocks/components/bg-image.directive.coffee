# bg-image.directive.coffee
'use strict'

BgImageDirective = ()->

  return {
    restrict: 'A'
    link: (scope, element, attrs) ->
      attrs.$observe 'bgImage', (src)->
        element
          .addClass('bg-image')
          .css('background-image', "url({src})".replace('{src}', src) )
      return
  }

BgImageDirective.$inject = []

angular.module 'blocks.components'
  .directive 'bgImage', BgImageDirective