# placeholder.direcctive.coffee
'use strict'

# ListController = ($scope, $window)->
#   vm = this
#   vm.item = {}
#   vm.selected = (item)->
#     console.log ["setSelected", item.name] if item?
#     vm.item = angular.copy item if item?
#     return vm.item
#   return vm

# ListController.$inject = ['$scope', '$window']

ListItemContainerDirective = ()->
  return {
    restrict: 'E'
    scope: {
      summaryMinWidth: "="
      detailMaxWidth: "="
      scrollHandle: "@"
    }
    controllerAs: 'listItemCtrl'
    controller: [
      '$scope', '$window', '$ionicScrollDelegate', '$timeout'
      ($scope, $window, $ionicScrollDelegate, $timeout)->
        vm = this
        vm._selected = {}
        vm.$summaryEl = null  # set in postLink
        vm.$detailEl = null   # set in postLink
        vm.selected = (item, $el)->
          console.log ["setSelected", item.name] if item?
          vm._selected = angular.copy item if item?
          vm._selected['$el'] = $el
          return vm._selected
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

        vm.getAllSelected = ($container, $skip)->
          all = _.reduce $container.children(), (result, el)->
            result.push el if ~el.className.indexOf('selected')
            return result
          , []
          return angular.element _.difference( all, $skip) if $skip?
          return angular.element all

        vm.layout = (type, $selectedEl)->
          # console.log ionic.DomUtil.getPositionInParent($selectedEl[0])
          switch type
            when 'summary'
              vm.clearColSpec(vm.$detailEl).addClass('hide')

              unSelect = vm.getAllSelected vm.$summaryEl
              vm.clearColSpec( unSelect )
                .removeClass('selected')
                .addClass(vm.getColWidth())

              $timeout ()->
                # vm.$summaryEl.children().removeClass('hide') # optional
                # _ionScroll.scrollTo(vm.scrollPos.left, vm.scrollPos.top, true)
                # vm.scrollPos = {}
                vm.scrollPos = {
                  left: 0
                  top: ionic.DomUtil.getPositionInParent($selectedEl[0]).top
                }
                _ionScroll.scrollTo(vm.scrollPos.left, vm.scrollPos.top, true)
                return

            when 'detail'
              vm.clearColSpec($selectedEl)
                .removeClass('hide')
                .addClass('selected')
                .addClass(vm.calcColWidth(null, $scope.detailMaxWidth))
                # move $detailEl after $selectedEl
                .after(vm.$detailEl)   

              unSelect = vm.getAllSelected vm.$summaryEl, $selectedEl
              vm.clearColSpec( unSelect )
                .removeClass('selected')
                .addClass(vm.getColWidth())

              vm.$detailEl
                .addClass(vm.calcColWidth(null, $scope.detailMaxWidth))
                .removeClass('hide')

              
              $timeout ()->
                # vm.scrollPos = _ionScroll.getScrollPosition()
                # _ionScroll.scrollTo(0,0, true)
                # vm.$summaryEl.children().addClass('hide') # optional
                vm.scrollPos = {
                  left: 0
                  top: ionic.DomUtil.getPositionInParent($selectedEl[0]).top
                }
                _ionScroll.scrollTo(vm.scrollPos.left, vm.scrollPos.top, true)
                return
          return

        


        ##
        ## layout methods
        ##
        # use _.memoize to cache value, clear cache when window.innerWidth changes
        vm.calcColWidth = (minW, maxW)->
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
        vm.getColWidth = ()->
          return _getColWidth($scope.summaryMinWidth)
        _getColWidth = _.memoize vm.calcColWidth
        _resetColWidth = (minW)->
          _getColWidth.cache.delete(minW)
          return
        _handleWindowResize = ()->
          # access to $scope via closure
          _resetColWidth($scope.summaryMinWidth)
          $scope.$apply()
          return
        vm.scrollPos = {}

        # restore _ionScroll position, as necessary
        # TODO: move listItemDetail position in list and don't hide???
        _ionScroll = $ionicScrollDelegate.$getByHandle($scope.scrollHandle)
        

        angular.element($window).bind 'resize', _handleWindowResize

        $scope.$watch 'summaryMinWidth', (newV)->
          _resetColWidth($scope.summaryMinWidth)
          return

        $scope.$on '$destroy', ()->
          angular.element($window).unbind 'resize', _handleWindowResize
          return

        return vm
    ]
    link:
      post: (scope, element, attrs, controller, transclude) ->
        _findByName = ($elements, name)->
          found = _.find $elements, (el)->
            return true if el.getAttribute?('name') == name
          return angular.element(found)

        vm = controller
        vm['$summaryEl'] = _findByName(element.children(), 'list-summary-wrap')
        vm['$detailEl']  = _findByName(element.children(), 'list-detail-wrap')
  }
ListItemContainerDirective.$inject =[]




ListSummaryDirective = ($compile, $window, $controller, $ionicScrollDelegate)->
  return {
    restrict: 'E'
    require: '^listItemContainer'
    transclude: true
    replace: true
    template: """
      <div name="list-summary-wrap" class="list-item-summary row ng-repeat-grid">
        <div class="list-item-wrap col" ng-class="getColWidth()" ng-repeat="item in collection">
          <div class="card" ng-transclude-compile>
          </div>
        </div>
      </div>
    """
    scope: {
      collection:"="
    }
    link:
      # pre: (scope, element, attrs, controller, transclude) ->
      #   return
      post: (scope, element, attrs, controller, transclude) ->
        # element.addClass('row').addClass('ng-repeat-grid')
        controller.selected(null)

        scope.getColWidth = controller.getColWidth
        scope.on = {
          'select' : (event, model)->
            event.stopImmediatePropagation()
            target = angular.element event.currentTarget
            $selectedEl = target.parent().parent()
            if $selectedEl.hasClass('selected')
              controller.selected(null)
              controller.layout('summary', $selectedEl)
            else
              controller.selected(model, $selectedEl)
              controller.layout('detail', $selectedEl)
            return
          'close' : (event)->
            event.stopImmediatePropagation()
            target = angular.element event.currentTarget
            $selectedEl = target.parent().parent()
            controller.selected(null)
            controller.layout('summary', $selectedEl)

        }
        scope.listItemCtrl = controller
        return
  }

ListSummaryDirective.$inject = ['$compile', '$window', '$controller', '$ionicScrollDelegate']





ListDetailDirective = ()->
  return {
    restrict: 'E'
    require: '^listItemContainer'
    transclude: true
    replace: true
    template: """
      <div name="list-detail-wrap" class="list-item-detail col">
        <div class="card" ng-transclude-compile>
        </div>
      </div>
      """
    scope: {}
    link:
      # pre: (scope, element, attrs, controller, transclude) ->
      #   return
      post: (scope, element, attrs, controller, transclude) ->
        scope.listItemCtrl = controller
        scope.on = {
          'click': (event)->
            event.stopImmediatePropagation()
            console.log ['ListDetailDirective.on.click',scope.item.name]
          'close': (event, model)->
            event.stopImmediatePropagation()
            target = angular.element event.currentTarget
            $selectedEl = model.$el
            controller.selected(null)
            controller.layout('summary', $selectedEl)

        }
        scope.$watch 'listItemCtrl._selected', (newV, oldV)->
          scope.item = newV
          # console.log [ "watch detail selected", newV]
        return
  }
ListDetailDirective.$inject = []












# allows ng-repeat > ng-transclude-parent
NgTranscludeCompile = ($compile)->

  _findByName = ($elements, name)->
    return $elements if _.isEmpty name
    found = _.find $elements, (el, i)->
      if el.getAttribute?('name') == name
        return true
    return found

  return {
    restrict: 'A'
    compile: (tElement, tAttrs, transclude)->
      return {
        pre: ($scope, $element, $attrs, controller, $transclude) ->
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
            # $element.append( part )
            # compile at the end


          if $transclude.$$element
            console.log "attach element FIRST branch"
            _attach($transclude.$$element)
          else
            $transclude $scope, (clone)->
              $transclude.$$element = clone
              _attach(clone)
          return
        post: ($scope, $element, $attrs, controller, $transclude) ->
          return
      }

  }

NgTranscludeCompile.$inject = ['$compile']

angular.module 'blocks.components'
  .directive 'ngTranscludeCompile', NgTranscludeCompile
  .directive 'listItemContainer', ListItemContainerDirective
  .directive 'listItemSummary', ListSummaryDirective
  .directive 'listItemDetail', ListDetailDirective