# ng-repeat-grid.direcctive.coffee
'use strict'

NgRepeatGridSvc = ($rootScope, $window)->
  _minWidth = "160"
  vm = this

  vm.minWidth = (value)->
    if value
      _minWidth = value
      vm.resetColWidth(_minWidth)
    return _minWidth

  vm.clearColSpec = ($element)->
    classes = $element.attr('class')
    return $element if _.isEmpty classes

    classes = classes.split(' ')
    clean = _.reduce classes, (result, className)->
      result.push className if not /col-/.test(className)
      return result
    , []
    $element.attr('class', clean.join(' '))
    return $element

  # use _.memoize to cache value, clear cache when window.innerWidth changes
  vm.calcColWidth = (minW, maxW)->
    if maxW?   # for .list-item-detail
      pct = maxW/$window.innerWidth
      return colSpec = 'col-100' if pct > 0.80
      return colSpec = 'col-offset-10 col-80' if pct > 0.60
      return colSpec = 'col-offset-20 col-60' if pct > 0.5
      return colSpec = 'col-offset-25 col-50 col-offset-25-right' if pct > 0.33
      return colSpec = 'col-offset-33 col-33 col-offset-33-right'

    pct = minW/$window.innerWidth
    return colSpec = 'col-20' if pct <= 0.20
    return colSpec = 'col-25' if pct <= 0.25
    return colSpec = 'col-33' if pct <= 0.33
    return colSpec = 'col-50' if pct <= 0.50
    return colSpec = 'col-full'

  vm.resetColWidth = (minW)->
    return _getColWidth.cache.delete(minW) if minW
    # hack: how do you clear the memoize cache properly?
    _getColWidth.cache.clear()
    return

  # use ng-class="getColWidth()"
  vm.getColWidth = (minW)->
    minW ?= _minWidth
    return _getColWidth(minW)
  _getColWidth = _.memoize vm.calcColWidth

  _handleWindowResize = ()->
    vm.resetColWidth()
    $rootScope.$apply()
    return

  angular.element($window).bind 'resize', _handleWindowResize

  $rootScope.$on '$destroy', ()->
    angular.element($window).unbind 'resize', _handleWindowResize
    return

  return vm

NgRepeatGridSvc.$inject =['$rootScope', '$window']

NgRepeatGridDirective = ($compile)->
  MARKUP = {
    colwrap : "<div class='col content' ng-class='dvm.getColWidth()'></div>"
  }
  return {
    restrict: 'EA'
    # transclude: true
    # replace: true
    controllerAs: 'dvm'
    controller: ['ngRepeatGridSvc', (ngRepeatGridSvc)->
      dvm = this
      dvm.minWidth ?= ngRepeatGridSvc.minWidth()
      dvm.resetColWidth = ngRepeatGridSvc.resetColWidth
      dvm.getColWidth = ()->
        return ngRepeatGridSvc.getColWidth(dvm.minWidth)
      return dvm
    ]
    scope: false
    link:
      pre: (scope, element, attrs, controller, transclude) ->
        if element.children()[0].getAttribute('ng-repeat')
          throw new Error "directive:ng-repeat-grid does NOT support wrapping ng-repeat (yet)"
        return
      post: (scope, element, attrs, controller, transclude) ->
        dvm = controller
        dvm.minWidth = attrs.minWidth
        element.addClass('row').addClass('ng-repeat-grid')
        _.each element.children(), (el)->
          wrap = angular.element(MARKUP.colwrap)
            .addClass('no-padding')
            .append( el )
          element.append(wrap)
          return
        $compile( element.children() )(scope)
        attrs.$observe 'minWidth', (newV)->
          dvm.minWidth = newV
          dvm.resetColWidth(dvm.minWidth)
          return
        return
  }
NgRepeatGridDirective.$inject = ['$compile']

angular.module 'blocks.components'
  .service 'ngRepeatGridSvc', NgRepeatGridSvc
  .directive 'ngRepeatGrid', NgRepeatGridDirective
