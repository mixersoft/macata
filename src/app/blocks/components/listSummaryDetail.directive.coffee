# placeholder.direcctive.coffee
'use strict'

ListItemDirective = ($compile, $window, $ionicScrollDelegate)->

  _findByName = ($elements, name)->
    found = _.find $elements, (el)->
      return true if el.getAttribute?('name') == name
    return angular.element(found)

  _calcColWidth = (minW, maxW)->
    if maxW?
      pct = maxW/$window.innerWidth
      return colSpec = 'col-100' if pct > 0.80
      return colSpec = 'col-offset-10 col-80' if pct > 0.60
      # return colSpec = 'col-offset-20 col-60' if pct > 0.5 # col-60 does not exist
      return colSpec = 'col-offset-25 col-50' if pct > 0.33
      return colSpec = 'col-offset-33 col-33'

    pct = minW/$window.innerWidth
    return colSpec = 'col-20' if pct <= 0.20
    return colSpec = 'col-25' if pct <= 0.25
    return colSpec = 'col-33' if pct <= 0.33
    return colSpec = 'col-50' if pct <= 0.50
    return colSpec = null

  # use _.memoize to cache value, clear cache when window.innerWidth changes
  _getColWidth = _.memoize _calcColWidth
  _resetColWidth = (minW)->
    _getColWidth.cache.delete(minW)
    return

  _clearColSpec = ($element)->
    classes = $element.attr('class').split(' ')
    clean = _.reduce classes, (result, className)->
      result.push className if not /col-/.test(className)
      return result
    , []
    $element.attr('class', clean.join(' '))
    return $element


    console.log this.className
    return this

  return {
    restrict: 'EA'
    transclude: true
    template: """
      <div name="list-item-summary-wrap">
        <div class="list-item-wrap col" ng-class="getColWidth()" ng-repeat="item in collection">
          <div class="card" ng-transclude-compile="list-item-summary">
          </div>
        </div>
      </div>
      <div name="list-item-detail-wrap" class="item-detail">
        <div class="card" ng-transclude-compile="list-item-detail">
        </div>
      </div>
    """
    scope: {
      collection:"="
      summaryMinWidth: "="
      detailMaxWidth: "="
      scrollHandle: "@"
    }
    link: (scope, element, attrs, controller, transclude) ->
      # element.addClass('row').addClass('ng-repeat-grid')

      _handleWindowResize = ()->
        # access to scope via closure
        _resetColWidth(scope.summaryMinWidth)
        scope.$apply()
        return


      liSummary_Wrap = _findByName element.children(), 'list-item-summary-wrap'
      liSummary_Wrap.addClass('row').addClass('ng-repeat-grid')
      liDetail = _findByName element.children(), 'list-item-detail-wrap'
      ionScroll = $ionicScrollDelegate.$getByHandle(scope.scrollHandle)
      scrollPos = {}
      
      scope.selected = null
      scope.on = {
        select : (event, item)->
          event.stopImmediatePropagation()
          target = angular.element event.currentTarget
          liSummary_Selected = target.parent().parent()
          if liSummary_Selected.hasClass('selected')
            # hide detail
            _clearColSpec(liSummary_Selected)
              .removeClass('selected')
              .addClass( _getColWidth(scope.summaryMinWidth) )
            
            _clearColSpec(liDetail)
            liDetail
              .addClass('hide')
            liSummary_Wrap.children()
              .removeClass('hide')
            ionScroll.scrollTo(scrollPos.left, scrollPos.top, true)
            scrollPos = {}
          else
            scope.selected = item
            # show detail
            scrollPos = ionScroll.getScrollPosition()
            ionScroll.scrollTo(0,0, true)

            liSummary_Wrap.children().addClass('hide')

            _clearColSpec(liSummary_Selected)
              .removeClass('hide')
              .addClass('selected')
              .addClass(_calcColWidth(null, scope.detailMaxWidth))

            liDetail
              .addClass(_calcColWidth(null, scope.detailMaxWidth))
              .removeClass('hide')
            

          return
      }

      
      scope.getColWidth = ()->
        return _getColWidth(scope.summaryMinWidth)


      angular.element($window).bind 'resize', _handleWindowResize

      scope.$watch 'summaryMinWidth', (newV)->
        _resetColWidth(scope.summaryMinWidth)
        return

      scope.$on '$destroy', ()->
        angular.element($window).unbind 'resize', _handleWindowResize
        return

      return
  }

ListItemDirective.$inject = ['$compile', '$window', '$ionicScrollDelegate']

# allows ng-repeat > ng-transclude-parent
NgTranscludeCompile = ($compile)->

  _findByName = ($elements, name)-> _.find $elements, (el)->
    return true if el.getAttribute?('name') == name

  return {
    restrict: 'A'
    # controller: ($scope, $element, $attrs, $transclude) ->
    #   if !$transclude
    #     throw minErr('ngTransclude')('orphan',
    #      'Illegal use of ngTransclude directive in the template! ' +
    #      'No parent directive that requires a transclusion found. ' +
    #      'Element: {0}',
    #      startingTag($element))
    #     this.$transclude = $transclude
    #     return


    link: ($scope, $element, $attrs, controller, $transclude) ->
      if !$transclude
        throw minErr('ngTransclude')('orphan',
         'Illegal use of ngTransclude directive in the template! ' +
         'No parent directive that requires a transclusion found. ' +
         'Element: {0}',
         startingTag($element))

      _attach = (clone)->
        part = _findByName(clone, $attrs.ngTranscludeCompile)
        $element.empty()
        $element.append $compile(part)($scope)

      if $transclude.$$element
        _attach($transclude.$$element)
      else
        $transclude $scope, (clone)->
          $transclude.$$element = clone
          _attach(clone)

      return

      # $transclude $scope, (clone)->
      #   $element.empty()
      #   clone = _findByName(clone, $attrs.ngTranscludeCompile)
      #   $element.append $compile(clone)($scope)
      #   return
  }

NgTranscludeCompile.$inject = ['$compile']

angular.module 'blocks.components'
  .directive 'ngTranscludeCompile', NgTranscludeCompile
  .directive 'listSummaryDetail', ListItemDirective