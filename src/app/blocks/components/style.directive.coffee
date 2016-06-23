'use strict'

_findParentByTagName = (el, tagName)->
  parent = el
  tagName = tagName.toUpperCase()
  while parent && parent.parentNode
    return parent if parent.tagName == tagName
    parent = parent.parentNode
  return null

###
# @description directive <style-scoped> prepends a <style> element with
#   dynamic CSS styles into the DOM at the rootTag/rootClass element
#   use '#%rootId%' in CSS to scope the styles below the
#   rootTag/rootClass element
#   adds an auto-generated id to the rootTag/rootClass is missing
###
StyleScoped = ($timeout)->
  rootEl = null
  return {
    restrict: 'E'
    scope:
      # prepend the <style> element under the rootTag/rootClass element
      rootTag: '@'
      rootClass: '@'
      # css styles for the <style> element
      cssStyle: '='
    link:
      post: (scope, element, attrs, controllers) ->
        rootEl = element[0]
        if scope.rootClass
          rootEl = ionic.DomUtil.getParentOrSelfWithClass rootEl, scope.rootClass
        if scope.rootTag
          rootEl = _findParentByTagName( rootEl, scope.rootTag)
        return if !rootEl

        $style = angular.element('<STYLE></STYLE>')
        # #  $timeout to let rootEl.id get $parsed
        rootEl.id ?= 'style-scope-' + Meteor.uuid()
        element.append($style)

        
        # $timeout().then ()->
        #   # #  $timeout to let rootEl.id get $parsed
        #   rootEl.id ?= 'style-scope-' + Meteor.uuid()
        #   element.append($style)

        scope.$watch 'cssStyle', (newV)->
          return if !newV
          # preprend CSS scope to style
          scope.cssStyle = scope.cssStyle.replace(/%rootId%/g, rootEl.id)
          $style.html(scope.cssStyle)
        return
  }

StyleScoped.$inject = ['$timeout']

angular.module('blocks.components')
  .directive 'styleScoped', StyleScoped
