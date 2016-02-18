# listSummaryDetail.direcctive.coffee
'use strict'

ListItemContainerDirective = (ngRepeatGridSvc)->
  return {
    restrict: 'E'
    scope: {
      collection:"="
      filter:"="
      itemHeight:"="
      summaryMinWidth: "="
      detailMaxWidth: "="
      showDetailInline: "="
      scrollHandle: "@"
      detailByReference: "@"
      onSelect: '&'
    }
    controllerAs: '$listItemDelegate'
    controller: [
      '$compile', '$scope', '$window', '$ionicScrollDelegate', '$timeout'
      ($compile, $scope, $window, $ionicScrollDelegate, $timeout)->

        _styleEl = """
          <style class="item-style">
            \#{id}.list-item-summary .list-item-wrap > .item {
            min-height: 160px; }
        </style>
        """

        vm = this
        vm.collection = $scope.collection
        vm.itemHeight ?= 160
        vm._selected = {}
        vm.scrollPos = {}     # set in vm.layout()
        vm.$summaryEl = null  # set in postLink
        vm.$detailEl = null   # set in postLink
        vm.selected = (item, $el)->
          if item?
            # console.log ["$listItemDelegate.setSelected()", item.id || item.name || item.title]
            vm._selected =
              if $scope.detailByReference
              then item
              else angular.copy item
            if $el?
              vm._selected['$el'] = $el
          return vm._selected

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

              ngRepeatGridSvc.clearColSpec(vm.$detailEl)
                  .addClass('slide-under')
              unSelect = vm.getAllSelected vm.$summaryEl
              unSelect.removeClass('selected')
              vm.$summaryEl
                .removeClass('detail-view-active')

              $timeout ()->
                # clearColSpec after .slide-under animation
                ngRepeatGridSvc.clearColSpec( unSelect )
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

              # $compile(vm.$detailEl.children())($scope)

              ngRepeatGridSvc.clearColSpec($selectedElContainer)
                .removeClass('hide')
                .addClass('selected')
                .addClass(ngRepeatGridSvc.calcColWidth(null, $scope.detailMaxWidth))
                # append $detailEl to $selectedElContainer
                .append(vm.$detailEl)


              unSelectSummaryEl = vm.getAllSelected vm.$summaryEl, $selectedElContainer
              ngRepeatGridSvc.clearColSpec( unSelectSummaryEl )
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
                # NOTE: $ionicScrollDelegate normally does not work with <ion-modal-view>
                # because $$filterFn = ()-> $ionicHistory.isActiveScope($scope)
                #
                isModalView = ionic.DomUtil.getParentWithClass( vm.$summaryEl[0], 'modal')
                if isModalView
                  _ionScroll._instances.forEach (instance)->
                    console.warn "HACK: $ionScroll.scrollTo() inside <ion-modal-view>"
                    if _ionScroll.handle == instance.$$delegateHandle
                      return instance['scrollTo']
                        .call(instance, vm.scrollPos.left, vm.scrollPos.top, true)
                    return
                else
                  _ionScroll.scrollTo(vm.scrollPos.left, vm.scrollPos.top, true)

                return
              , 300
          return


        ##
        ## layout methods
        ##
        vm.setItemHeight = ($container, h)->
          return if !vm.$summaryEl
          h ?= vm.itemHeight
          styleEl = $container[0].querySelector('style')
          if !styleEl
            $container.prepend( _styleEl.replace(/{id}/g, vm.$summaryEl.attr('id')) )
            styleEl = $container[0].querySelector('style')
          styleEl.innerHTML = styleEl.innerHTML
            .replace(/(min-height:.)(\d+)(px)/, "$1"+h+"$3").trim()
          return

        vm.getColWidth = ()->
          return ngRepeatGridSvc.getColWidth($scope.summaryMinWidth)

        # restore _ionScroll position, as necessary
        _ionScroll = $ionicScrollDelegate.$getByHandle($scope.scrollHandle)

        $scope.$watch 'summaryMinWidth', (newV)->
          ngRepeatGridSvc.resetColWidth($scope.summaryMinWidth)
          return


        # these methods are available to transclude nodes
        vm.$listItemDelegate = {
          'collection': ()->
            return $scope.collection
          'selected' : ()->
            #note: $item should already be visible in scope of transclude nodes
            $item = vm.selected()
            return $item
          ###
          # @description select a summaryEl
          # @param event or null, if event? then use event.currentTarget to find selected El
          #     if null, then use $index
          # @param silent, do NOT $emit '$listItemDelegate:selected' event
          ###
          'select' : (event, $item, $index, silent)->
            if not $item
              return vm.$listItemDelegate.closeDetail(event)

            if event
              event.stopImmediatePropagation()
              target = ionic.DomUtil.getParentOrSelfWithClass(event.currentTarget, 'list-item-wrap')
              throw new Error ["warning: cant find .list-item-wrap", event.currentTarget] if !target
              $selectedElContainer =  angular.element target # .list-item-wrap
            else
              target = vm.$summaryEl[0].querySelectorAll('.list-item-wrap')[$index]
              $selectedElContainer =  angular.element target # .list-item-wrap

            # console.log $selectedElContainer
            return if _.isEmpty $selectedElContainer


            # event=null if vm.listItemDelegate.select() on activate()
            return if not event instanceof MouseEvent

            if $selectedElContainer.hasClass('selected')
              # unSelect
              vm.selected( null )
              vm.layout('summary', $selectedElContainer)
              $scope.onSelect?({
                $item: null
                $index: null
                silent: silent
              })
            else
              vm.selected( $item, $selectedElContainer )
              vm.layout('detail', $selectedElContainer)
              $scope.onSelect?({
                $item: $item
                $index: $index
                silent: silent
              })
            return if silent
            $scope.$emit '$listItemDelegate:selected', {
              $item: $item,
              $index: $index
              $listItemDelegate: vm.$listItemDelegate
            }
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
          'filter': $scope.filter
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
        scope.$parent.$listItemDelegate = vm['$listItemDelegate']
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
ListItemContainerDirective.$inject = ['ngRepeatGridSvc']




ListSummaryDirective = ($filter, $window, $controller, $ionicScrollDelegate)->
  return {
    restrict: 'E'
    require: '^listItemContainer'
    transclude: true
    replace: true
    template: """
      <div name="list-summary-wrap" class="list-item-summary row ng-repeat-grid">
        <div class="list-item-wrap col"
          ng-class="$listItemDelegate.getColWidth()"
          ng-repeat="$item in collection"
          ng-transclude-parent="parent">
        </div>
      </div>
    """
    scope: {
      collection:"="
    }
    compile: (tElement, tAttrs, transclude)->
      link = {
        pre: (scope, element, attrs, controller, transclude) ->
          controller['$summaryEl'] = element
          controller['$summaryEl'].attr('id', 'list-item-container-'+element.scope().$id)
          return
        post: (scope, element, attrs, controller, transclude) ->
          scope.$listItemDelegate = controller['$listItemDelegate']

          if not attrs.collection?
            # list-item-summary[collection] takes precedence
            scope.$watch '$listItemDelegate.collection()', (newV, oldV)->

              filter = scope.$listItemDelegate.filter?.split(':')
              if filter
                scope.collection = $filter(filter.shift()).apply(this, [newV].concat(filter))
              else
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
      return link
  }

ListSummaryDirective.$inject = ['$filter', '$window', '$controller', '$ionicScrollDelegate']





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
        scope.$item = {}
        controller['$detailEl'] = element
        return
      post: (scope, element, attrs, controller, transclude) ->
        scope.$listItemDelegate = controller['$listItemDelegate']
        scope.$watch '$listItemDelegate.selected()', (newV, oldV)->
          scope.$item = newV
          # console.log [ "watch detail selected", newV]
        return
  }
ListDetailDirective.$inject = []

ListItemDelegate = ()->
  this.getByHandle = (handle, parentScope)->
    parents = document.getElementsByTagName('LIST-ITEM-CONTAINER')
    found = _.find parents, (parentEl)->
      foundHandle = parentEl.getAttribute('handle') == handle ||
        parentEl.getAttribute('scroll-handle') == handle
      if foundHandle
        return parentEl if !parentScope
        # $ionicView caching will create multiple ion-scroll parents with same handle
        # check that the <list-item-container> is a child of the given parentScope
        checkScope = angular.element(parentEl).scope()
        done = !checkScope || checkScope == parentScope
        while not done
          checkScope = checkScope.$parent
          done = !checkScope || checkScope == parentScope

        return parentEl if checkScope
        # console.warn ["ListItemDelegate.getByHandle() WRONG handle from cached $ionicView"
        #   parentScope.$id
        #   angular.element(parentEl).scope().$id
        # ]
        return
      return
    return angular.element(found).scope?().$listItemDelegate
  this.getByChildEl = (child)->
    parents = document.getElementsByTagName('LIST-ITEM-CONTAINER')
    child = child[0] if child.scope?
    found = _.find parents, (parentEl)->
      return parentEl if parentEl.contains child
    return angular.element(found).scope?().$listItemDelegate
  return
ListItemDelegate.$inject = []


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
  .service '$listItemDelegate', ListItemDelegate
