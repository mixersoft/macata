(function() {
  // 'use strict';

  var IonicModule = angular.module('ionic'),
    extend = angular.extend,
    forEach = angular.forEach,
    isDefined = angular.isDefined,
    isNumber = angular.isNumber,
    isString = angular.isString,
    jqLite = angular.element,
    noop = angular.noop;



  IonicModule
  .controller('$searchRefresher', [
    '$scope',
    '$attrs',
    '$element',
    '$ionicBind',
    '$timeout',
    function($scope, $attrs, $element, $ionicBind, $timeout) {
      var self = this,
          isDragging = false,
          isOverscrolling = false,
          dragOffset = 0,
          lastOverscroll = 0,
          // ptrThreshold = 60,
          ptrThreshold = 60,
          activated = false,
          scrollTime = 500,
          startY = null,
          deltaY = null,
          canOverscroll = true,
          scrollParent,
          scrollChild;

      if (!isDefined($attrs.pullingIcon)) {
        $attrs.$set('pullingIcon', 'ion-android-arrow-down');
      }

      $scope.showSpinner = !isDefined($attrs.refreshingIcon) && $attrs.spinner != 'none';

      $scope.showIcon = isDefined($attrs.refreshingIcon);

      $ionicBind($scope, $attrs, {
        // pullingIcon: '@',
        // pullingText: '@',
        // refreshingIcon: '@',
        // refreshingText: '@',
        // spinner: '@',
        // disablePullingRotation: '@',
        $onRefresh: '&onRefresh',
        $onPulling: '&onPulling'
      });

      function handleMousedown(e) {
        e.touches = e.touches || [{
          screenX: e.screenX,
          screenY: e.screenY
        }];
        // Mouse needs this
        startY = Math.floor(e.touches[0].screenY);
      }

      function handleTouchstart(e) {
        e.touches = e.touches || [{
          screenX: e.screenX,
          screenY: e.screenY
        }];

        startY = e.touches[0].screenY;
      }

      function handleTouchend(e) {
        // reset Y
        startY = null;
        // if this wasn't an overscroll, get out immediately
        if (!canOverscroll && !isDragging) {
          return;
        }

        // prevent ng-click in browser
        if (ionic.Platform.isWebView() === false) {
          e.stopImmediatePropagation();
        }

        // the user has overscrolled but went back to native scrolling
        if (!isDragging) {
          dragOffset = 0;
          isOverscrolling = false;
          setScrollLock(false);
        } else {
          isDragging = false;
          dragOffset = 0;

          // the user has scroll far enough to trigger a refresh
          if (lastOverscroll > ptrThreshold) {
            start();
            var h = $element.prop('clientHeight')
            scrollTo(h, scrollTime);
            done();


          // the user has overscrolled but not far enough to trigger a refresh
          } else {
            scrollTo(0, scrollTime, deactivate);
            isOverscrolling = false;
          }
        }
      }

      function handleTouchmove(e) {

        e.touches = e.touches || [{
          screenX: e.screenX,
          screenY: e.screenY
        }];

        // Force mouse events to have had a down event first
        if (!startY && e.type == 'mousemove') {
          return;
        }

        // if multitouch or regular scroll event, get out immediately
        if (!canOverscroll || e.touches.length > 1) {
          return;
        }
        //if this is a new drag, keep track of where we start
        if (startY === null) {
          startY = e.touches[0].screenY;
        }

        deltaY = e.touches[0].screenY - startY;

        // how far have we dragged so far?
        // kitkat fix for touchcancel events http://updates.html5rocks.com/2014/05/A-More-Compatible-Smoother-Touch
        // Only do this if we're not on crosswalk
        if (ionic.Platform.isAndroid() && ionic.Platform.version() === 4.4 && !ionic.Platform.isCrosswalk() && scrollParent.scrollTop === 0 && deltaY > 0) {
          isDragging = true;
          e.preventDefault();
        }


        // if we've dragged up and back down in to native scroll territory
        if (deltaY - dragOffset <= 0 || scrollParent.scrollTop !== 0) {

          if (isOverscrolling) {
            isOverscrolling = false;
            setScrollLock(false);
          }

          if (isDragging) {
            nativescroll(scrollParent, deltaY - dragOffset * -1);
          }

          // if we're not at overscroll 0 yet, 0 out
          if (lastOverscroll !== 0) {
            overscroll(0);
          }
          return;

        } else if (deltaY > 0 && scrollParent.scrollTop === 0 && !isOverscrolling) {
          // starting overscroll, but drag started below scrollTop 0, so we need to offset the position
          dragOffset = deltaY;
        }

        // prevent native scroll events while overscrolling
        e.preventDefault();


        // if not overscrolling yet, initiate overscrolling
        if (!isOverscrolling) {
          isOverscrolling = true;
          setScrollLock(true);
        }

        isDragging = true;
        // overscroll according to the user's drag so far
        overscroll((deltaY - dragOffset) / 3);

        // update the icon accordingly
        if (!activated && lastOverscroll > ptrThreshold) {
          activated = true;
          ionic.requestAnimationFrame(activate);

        } else if (activated && lastOverscroll < ptrThreshold) {
          activated = false;
          // ionic.requestAnimationFrame(deactivate);
        }
      }

      function handleScroll(e) {
        // canOverscrol is used to greatly simplify the drag handler during normal scrolling
        canOverscroll = (e.target.scrollTop === 0) || isDragging;
      }

      function overscroll(val) {
        scrollChild.style[ionic.CSS.TRANSFORM] = 'translateY(' + val + 'px)';
        lastOverscroll = val;
      }

      function nativescroll(target, newScrollTop) {
        // creates a scroll event that bubbles, can be cancelled, and with its view
        // and detail property initialized to window and 1, respectively
        target.scrollTop = newScrollTop;
        var e = document.createEvent("UIEvents");
        e.initUIEvent("scroll", true, true, window, 1);
        target.dispatchEvent(e);
      }

      function setScrollLock(enabled) {
        // set the scrollbar to be position:fixed in preparation to overscroll
        // or remove it so the app can be natively scrolled
        if (enabled) {
          ionic.requestAnimationFrame(function() {
            scrollChild.classList.add('overscroll');
            show();
          });

        } else {
          ionic.requestAnimationFrame(function() {
            scrollChild.classList.remove('overscroll');
            hide();
            deactivate();
          });
        }
      }

      $scope.$on('scroll.refreshComplete', function() {
        // prevent the complete from firing before the scroll has started
        $timeout(function() {

          // ionic.requestAnimationFrame(tail);

          // scroll back to home during tail animation
          // scrollTo(0, scrollTime, deactivate);

          // return to native scrolling after tail animation has time to finish
          $timeout(function() {

            if (isOverscrolling) {
              isOverscrolling = false;
              setScrollLock(false);
            }

          }, scrollTime);

        }, scrollTime);
      });

      function scrollTo(Y, duration, callback) {
        // scroll animation loop w/ easing
        // credit https://gist.github.com/dezinezync/5487119
        var start = Date.now(),
            from = lastOverscroll;

        if (from === Y) {
          callback();
          return; /* Prevent scrolling to the Y point if already there */
        }

        // decelerating to zero velocity
        function easeOutCubic(t) {
          return (--t) * t * t + 1;
        }

        // scroll loop
        function scroll() {
          var currentTime = Date.now(),
            time = Math.min(1, ((currentTime - start) / duration)),
            // where .5 would be 50% of time on a linear scale easedT gives a
            // fraction based on the easing method
            easedT = easeOutCubic(time);

          overscroll(Math.floor((easedT * (Y - from)) + from));

          if (time < 1) {
            ionic.requestAnimationFrame(scroll);

          } else {

            if (Y < 5 && Y > -5) {
              isOverscrolling = false;
              setScrollLock(false);
            }

            callback && callback();
          }
        }

        // start scroll loop
        ionic.requestAnimationFrame(scroll);
      }


      var touchStartEvent, touchMoveEvent, touchEndEvent;
      if (window.navigator.pointerEnabled) {
        touchStartEvent = 'pointerdown';
        touchMoveEvent = 'pointermove';
        touchEndEvent = 'pointerup';
      } else if (window.navigator.msPointerEnabled) {
        touchStartEvent = 'MSPointerDown';
        touchMoveEvent = 'MSPointerMove';
        touchEndEvent = 'MSPointerUp';
      } else {
        touchStartEvent = 'touchstart';
        touchMoveEvent = 'touchmove';
        touchEndEvent = 'touchend';
      }

      self.init = function() {
        scrollParent = $element.parent().parent()[0];
        scrollChild = $element.parent()[0];

        if (!scrollParent || !scrollParent.classList.contains('ionic-scroll') ||
          !scrollChild || !scrollChild.classList.contains('scroll')) {
          throw new Error('Refresher must be immediate child of ion-content or ion-scroll');
        }


        ionic.on(touchStartEvent, handleTouchstart, scrollChild);
        ionic.on(touchMoveEvent, handleTouchmove, scrollChild);
        ionic.on(touchEndEvent, handleTouchend, scrollChild);
        ionic.on('mousedown', handleMousedown, scrollChild);
        ionic.on('mousemove', handleTouchmove, scrollChild);
        ionic.on('mouseup', handleTouchend, scrollChild);
        ionic.on('scroll', handleScroll, scrollParent);

        // cleanup when done
        $scope.$on('$destroy', destroy);
      };

      function destroy() {
        ionic.off(touchStartEvent, handleTouchstart, scrollChild);
        ionic.off(touchMoveEvent, handleTouchmove, scrollChild);
        ionic.off(touchEndEvent, handleTouchend, scrollChild);
        ionic.off('mousedown', handleMousedown, scrollChild);
        ionic.off('mousemove', handleTouchmove, scrollChild);
        ionic.off('mouseup', handleTouchend, scrollChild);
        ionic.off('scroll', handleScroll, scrollParent);
        scrollParent = null;
        scrollChild = null;
      }

      // DOM manipulation and broadcast methods shared by JS and Native Scrolling
      // getter used by JS Scrolling
      self.getRefresherDomMethods = function() {
        return {
          activate: activate,
          deactivate: deactivate,
          start: start,
          show: show,
          hide: hide,
          tail: tail
        };
      };

      function activate() {
        $element[0].classList.add('active');
        $scope.$onPulling();
      }

      function deactivate() {
        // give tail 150ms to finish
        $timeout(function() {
          // deactivateCallback
          $element.removeClass('active refreshing refreshing-tail');
          if (activated) activated = false;
        }, 150);
      }

      function start() {
        // startCallback
        $element[0].classList.add('refreshing');
        var q = $scope.$onRefresh();

        if (q && q.then) {
          q['finally'](function() {
            $scope.$broadcast('scroll.refreshComplete');
          });
        }
      }

      function show() {
        // showCallback
        $element[0].classList.remove('invisible');
      }

      function hide() {
        // showCallback
        // $element[0].classList.add('invisible');
      }

      function done() {
        $timeout(function() {
          // // disable scrollChild listeners once the searchRefresher is revealed
          ionic.off(touchStartEvent, handleTouchstart, scrollChild);
          ionic.off(touchMoveEvent, handleTouchmove, scrollChild);
          ionic.off(touchEndEvent, handleTouchend, scrollChild);
          ionic.off('mousedown', handleMousedown, scrollChild);
          ionic.off('mousemove', handleTouchmove, scrollChild);
          ionic.off('mouseup', handleTouchend, scrollChild);
          // ionic.off('scroll', handleScroll, scrollParent);
        });
      }

      function tail() {
        // tailCallback
        $element[0].classList.add('refreshing-tail');
      }

      // for testing
      self.__handleTouchmove = handleTouchmove;
      self.__getScrollChild = function() { return scrollChild; };
      self.__getScrollParent = function() { return scrollParent; };
    }
  ]);




  /**
   * @ngdoc directive
   * @name searchRefresher
   * @module ionic
   * @restrict E
   * @parent ionic.directive:ionContent, ionic.directive:ionScroll
   * @description
   * Allows you to add pull-to-refresh to reveal a search tile.
   * Modified from ionic.directive:ionRefresher
   *
   * Place it as the first child of your {@link ionic.directive:ionContent} or
   * {@link ionic.directive:ionScroll} element.
   *
   * When the reveal is complete the search tile remains visible
   *
   * @usage
   *
   * ```html
   * <ion-content ng-controller="MyController">
   *   <search-refresher>
   *   	<search-tile></search-tile>
   *   </search-refresher>
   *   <ion-list>
   *     <ion-item ng-repeat="item in items"></ion-item>
   *   </ion-list>
   * </ion-content>
   * ```
   * ```js
   * angular.module('testApp', ['ionic'])
   * .controller('MyController', function($scope, $http) {
   *   $scope.items = [1,2,3];
   *   $scope.doRefresh = function() {
   *     $http.get('/new-items')
   *      .success(function(newItems) {
   *        $scope.items = newItems;
   *      })
   *      .finally(function() {
   *        // Stop the ion-refresher from spinning
   *        $scope.$broadcast('scroll.refreshComplete');
   *      });
   *   };
   * });
   * ```
   *
   * @param {expression=} on-refresh Called when the user pulls down enough and lets go
   * of the refresher.
   * @param {expression=} on-pulling Called when the user starts to pull down
   * on the refresher.
   *
   */
  IonicModule
  .directive('searchRefresher', ['$compile', function($compile) {
    return {
      restrict: 'E',
      replace: true,
      transclude: true,
      require: ['?^$ionicScroll', 'searchRefresher'],
      controller: '$searchRefresher',
      template:
      '<div class="scroll-refresher invisible" collection-repeat-ignore></div>',
      link: function($scope, $element, $attrs, ctrls, $transclude) {

        // transclude .search-refresher and add properties
        $element.append($transclude())
        $compile($element)($scope);
        $element[0].classList.add('search-refresher');
        $element[0].classList.remove('invisible');
        var h = $element.prop('clientHeight');
        $element.css('top', -1 * (h+1) + 'px')

        // JS Scrolling uses the scroll controller
        var scrollCtrl = ctrls[0],
            refresherCtrl = ctrls[1];
        if (!scrollCtrl || scrollCtrl.isNative()) {
          // Kick off native scrolling
          refresherCtrl.init();
        } else {
          $element[0].classList.add('js-scrolling');
          scrollCtrl._setRefresher(
            $scope,
            $element[0],
            refresherCtrl.getRefresherDomMethods()
          );

          $scope.$on('scroll.refreshComplete', function() {
            $scope.$evalAsync(function() {
              scrollCtrl.scrollView.finishPullToRefresh();
            });
          });
        }

      }
    };
  }]);

}).call(this);
