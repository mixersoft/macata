'use strict'

_findParentByTagName = (el, tagName)->
  parent = el
  tagName = tagName.toUpperCase()
  while parent && parent.parentNode
    return parent if parent.tagName == tagName
    parent = parent.parentNode
  return null

StyleScoped = ($timeout)->
  return {
    restrict: 'E'
    scope:
      rootTag: '@'
      rootClass: '@'
      id: '='
      cssStyle: '='
    link:
      post: (scope, element, attrs, controllers) ->
        root = element[0]
        if scope.rootClass
          root = ionic.DomUtil.getParentOrSelfWithClass el, scope.rootClass
        if scope.rootTag
          root = _findParentByTagName( root, scope.rootTag)
        return if !root

        $style = angular.element('<STYLE></STYLE>')
        $timeout().then ()->
          #  $timeout to let root.id get $parsed
          scope.id = root.id || scope.id
          root.id = scope.id
          $style.attr('id', 'style-scoped-' + root.id)
          angular.element(root).prepend($style)

        scope.$watch 'cssStyle', (newV)->
          return if !newV
          $style.html(scope.cssStyle)
        return
  }

StyleScoped.$inject = ['$timeout']

angular.module('blocks.components')
  .directive 'styleScoped', StyleScoped
