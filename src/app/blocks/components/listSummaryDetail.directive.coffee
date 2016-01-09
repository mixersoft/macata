# listSummaryDetail.direcctive.coffee
'use strict'

ListItemContainerDirective = ()->
  return {
    restrict: 'E'
    scope: {
      collection:"="
      itemHeight:"="
      summaryMinWidth: "="
      detailMaxWidth: "="
      showDetailInline: "="
      scrollHandle: "@"
      detailByReference: "@"
    }
    controllerAs: '$listItemDelegate'
    controller: [
      '$scope', '$window', '$ionicScrollDelegate', '$timeout'
      ($scope, $window, $ionicScrollDelegate, $timeout)->

        _styleEl = """
          <style class="item-style">
          .list-item-summary .list-item-wrap > .item,
          .list-item-summary .item.item-complex > .item-content {
            min-height: 160px; }
        </style>
        """

        vm = this
        vm.collection = $scope.collection
        vm.itemHeight ?= 160
        vm._selected = {}
        vm.$summaryEl = null  # set in postLink
        vm.$detailEl = null   # set in postLink
        vm.selected = (item, $el)->
          if item?
            console.log ["setSelected", item.id || item.name || item.title]
            vm._selected =
              if $scope.detailByReference
              then item
              else angular.copy item
            if $el?
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

        vm.layout = (type, $selectedElContainer)->
          if not vm['$summaryEl']?.length or not vm['$detailEl']?.length
            return throw new Error(
              """
              Missing: directive <list-item-container> requires both <list-item-summary> and <list-item-detail> child nodes
              """
            )
          switch type
            when 'summary'
              if $scope.showDetailInline == false
                vm.$summaryEl.children().removeClass('hide')

              vm.clearColSpec(vm.$detailEl)
                  .addClass('slide-under')
              unSelect = vm.getAllSelected vm.$summaryEl
              unSelect.removeClass('selected')
              vm.$summaryEl
                .removeClass('detail-view-active')

              $timeout ()->
                # clearColSpec after .slide-under animation
                vm.clearColSpec( unSelect )
                  .addClass(vm.getColWidth())
                vm.$summaryEl
                  .append(vm.$detailEl)
                vm.$detailEl.addClass 'hide'

                # vm.$summaryEl.children().removeClass('hide') # optional
                # _ionScroll.scrollTo(vm.scrollPos.left, vm.scrollPos.top, true)
                # vm.scrollPos = {}
                vm.scrollPos = {
                  left: 0
                  top: ionic.DomUtil.getPositionInParent($selectedElContainer[0]).top
                }
                # _ionScroll.scrollTo(vm.scrollPos.left, vm.scrollPos.top, false)
                return
              ,350



            when 'detail'
              if $scope.showDetailInline == false
                vm.$summaryEl.children().addClass('hide')

              vm.clearColSpec($selectedElContainer)
                .removeClass('hide')
                .addClass('selected')
                .addClass(vm.calcColWidth(null, $scope.detailMaxWidth))
                # append $detailEl to $selectedElContainer
                .append(vm.$detailEl)

              unSelectSummaryEl = vm.getAllSelected vm.$summaryEl, $selectedElContainer
              vm.clearColSpec( unSelectSummaryEl )
                .removeClass('selected')
                .addClass(vm.getColWidth())
              vm.$summaryEl
                .addClass('detail-view-active')

              vm.$detailEl
                .removeClass('hide')

              $timeout ()->
                vm.$detailEl
                  .removeClass('slide-under')
                # vm.scrollPos = _ionScroll.getScrollPosition()
                # _ionScroll.scrollTo(0,0, true)
                # vm.$summaryEl.children().addClass('hide') # optional
                return

              $timeout ()->
                vm.scrollPos = {
                  left: 0
                  top: ionic.DomUtil.getPositionInParent($selectedElContainer[0]).top
                }
                _ionScroll.scrollTo(vm.scrollPos.left, vm.scrollPos.top, true)
                return
              , 300
          return


        ##
        ## layout methods
        ##
        vm.setItemHeight = ($container, h)->
          h ?= vm.itemHeight
          styleEl = $container[0].querySelector('style')
          if !styleEl
            $container.prepend( _styleEl )
            styleEl = $container[0].querySelector('style')
          styleEl.innerHTML = styleEl.innerHTML
            .replace(/(min-height:.)(\d+)(px)/, "$1"+h+"$3").trim()
          return

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



        # these methods are available to transclude nodes
        vm.$listItemDelegate = {
          'collection': ()->
            return $scope.collection
          'selected' : ()->
            #note: $item should already be visible in scope of transclude nodes
            $item = vm.selected()
            return $item
          'select' : (event, $item, $index)->
            if not $item
              return vm.$listItemDelegate.closeDetail(event)

            event.stopImmediatePropagation()
            target = ionic.DomUtil.getParentOrSelfWithClass(event.currentTarget, 'list-item-wrap')
            throw new Error ["warning: cant find .list-item-wrap", event.currentTarget] if !target
            $selectedElContainer =  angular.element target # .list-item-wrap
            # console.log $selectedElContainer
            if $selectedElContainer.hasClass('selected')
              vm.selected( null )
              vm.layout('summary', $selectedElContainer)
            else
              vm.selected( $item, $selectedElContainer )
              vm.layout('detail', $selectedElContainer)
            return
          'closeDetail' : (event)->
            event.stopImmediatePropagation()
            target = angular.element event.currentTarget
            $selectedElContainer = target.parent() # .list-item-wrap
            vm.selected(null)
            vm.layout('summary', $selectedElContainer)
          'getColWidth': ()->
            return vm.getColWidth()
          'setItemHeight' : ()->
            throw new Error '$listItemDelegate.setItemHeight() not ready' # set in link
        }

        return vm
    ]
    link:
      post: (scope, element, attrs, controller, transclude) ->
        _findByName = ($elements, name)->
          found = _.find $elements, (el)->
            return true if el.getAttribute?('name') == name
          return angular.element(found)

        vm = controller
        vm['$listItemDelegate']['setItemHeight'] = (h)->
          controller.setItemHeight(element, h)
          return

        if attrs.itemHeight?
          scope.$watch 'itemHeight', (newV, oldV)->
            vm.setItemHeight(element, newV) if newV?
            return
        else
          vm.setItemHeight(element)

        if attrs.collection?
          # list-item-summary[collection] takes precedence
          scope.$watch 'collection', (newV, oldV)->
            vm.collection = newV
            return
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
        <div class="list-item-wrap col" ng-class="$listItemDelegate.getColWidth()" ng-repeat="$item in collection" ng-transclude-parent="parent">
        </div>
      </div>
    """
    scope: {
      collection:"="
    }
    link:
      pre: (scope, element, attrs, controller, transclude) ->
        controller['$summaryEl'] = element
        return
      post: (scope, element, attrs, controller, transclude) ->
        scope.$listItemDelegate = controller['$listItemDelegate']

        if not attrs.collection?
          # list-item-summary[collection] takes precedence
          scope.$watch '$listItemDelegate.collection()', (newV, oldV)->
            scope.collection = newV
            scope.$broadcast 'list-item-summary:changed'
            return

        controller.selected(null)
        scope.dbg = {
          'faceClick': (event, className)->
            event.stopImmediatePropagation()
            angular.element(
              document.querySelector('.list-item-detail')
            ).toggleClass(className)
            return
          'select' : controller.select
          'close' : (event)->
            event.stopImmediatePropagation()
            target = angular.element event.currentTarget
            $selectedElContainer = target.parent() # .list-item-wrap
            controller.selected(null)
            controller.layout('summary', $selectedElContainer)

        }
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
      <div name="list-detail-wrap" class="list-item-detail motion slide-under"
        ng-transclude-parent="parent" >
      </div>
      """
    scope: {}
    link:
      pre: (scope, element, attrs, controller, transclude) ->
        controller['$detailEl'] = element
        return
      post: (scope, element, attrs, controller, transclude) ->
        scope.$listItemDelegate = controller['$listItemDelegate']
        scope.dbg = {
          'click': (event)->
            event.stopImmediatePropagation()
            console.log ['ListDetailDirective.dbg.click', scope.$item.name]
          'close': controller.close
        }
        scope.$watch '$listItemDelegate.selected()', (newV, oldV)->
          scope.$item = newV
          # console.log [ "watch detail selected", newV]
        return
  }
ListDetailDirective.$inject = []




# see: https://github.com/angular/angular.js/issues/7874#issuecomment-53450394
NgTranscludeParent = ()->
  return {
    restrict: 'EAC'
    replace: true     # added mlin
    link: ( $scope, $element, $attrs, controller, $transclude )->

      if !$transclude
        return throw minErr('ngTransclude')(
          'orphan',
          'Illegal use of ngTransclude directive in the template! ' +
          'No parent directive that requires a transclusion found. ' +
          'Element: {0}',
          startingTag($element)
        )

      iScopeType = $attrs['ngTranscludeParent'] || 'sibling'
      switch iScopeType
        when 'sibling'
          # standard behavior,
          # inner scope == child scope of directive's parent
          # no access to directive scope
          $transclude ( clone )->
            $element.empty()
            $element.append( clone )
        when 'parent'
          # inner scope == directive scope
          $transclude $scope, ( clone )->
            $element.empty()
            $element.append( clone )
        when 'child'
          # inner scope == child scope of directive scope
          # access to ng-repeat $index
          iChildScope = $scope.$new()
          $transclude iChildScope, ( clone )->
            $element.empty()
            $element.append( clone )
            $element.on '$destroy', ()->
              iChildScope.$destroy()
      return

    }


NgTranscludeParent.$inject = ['$compile']

angular.module 'blocks.components'
  .directive 'ngTranscludeParent', NgTranscludeParent
  .directive 'listItemContainer', ListItemContainerDirective
  .directive 'listItemSummary', ListSummaryDirective
  .directive 'listItemDetail', ListDetailDirective
