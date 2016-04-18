# auto-input.directive.coffee
'use strict'

# The directive
#   - exposes the focus and blur events
#   - adds button i.icon.ion-close-circle to clear the input field
#   - and calls blur() on keydown [enter]
InputDirective = ($compile, $timeout)->
  directive = {
    restrict: 'EA'
    require: 'ngModel'
    scope: {
      'returnClose': '='
      'onReturn': '&'
      'onFocus': '&'
      'onBlur': '&'
      'onKeydown': '&'
    },
    link:
      pre: (scope, element, attrs, ngModel) ->
        inputTypes = /text|search|tel|url|email|password/i
        if  not ~['INPUT','TEXTAREA'].indexOf(element[0].nodeName)
          throw new Error "directive auto-input is limited to input elements"
        if attrs.type && not inputTypes.test(attrs.type)
          throw new Error "Invalid input type for directive auto-input" + attrs.type


        btnTemplate = """
        <i ng-show="enabled" ng-click="clear($event)" style="color:#666;" class="auto-input icon ion-close-circled"></i>
        """
        template = $compile( btnTemplate )(scope)
        if element[0].nodeName == 'TEXTAREA'
          top = 7
          top +=17 if element.parent().hasClass('item-stacked-label')
          template.css('top', top+'px')

        element.after(template)

        scope.clear = (ev)->
          ev.stopImmediatePropagation()
          ngModel.$setViewValue()
          ngModel.$render()
          scope.enabled = false
          $timeout ()->
            return element[0].focus()
          ,150

        element.bind 'focus', (e)->
          scope.enabled = !ngModel.$isEmpty element.val()
          scope.$apply()
          if scope.onFocus
            $timeout ()-> scope.onFocus()
          if scope.onKeydown
            $timeout ()-> scope.onKeydown({$event:e, value: element.val()})
          return

        element.bind 'blur', (e)->
          $timeout(200)
          .then ()->
            # wrap in $timeout(200) because blur event occurs
            # before clear event, give time to clear
            return if ngModel.$isEmpty element.val()
            if scope.onBlur
              # console.log ['autoInput blur', element.val()]
              scope.onBlur({$event: e, value: element.val()})
            return

        element.bind 'keydown', (e)->
          if e.which == 13
            if scope.returnClose
              element[0].blur()
            if scope.onReturn
              $timeout ()-> scope.onReturn()
            return
          scope.enabled = !ngModel.$isEmpty element.val()
          scope.$apply()
          if scope.onKeydown
            $timeout ()-> scope.onKeydown({$event:e, value: element.val()})
          return



  }
  return directive


InputDirective.$inject = ['$compile', '$timeout']


angular.module('blocks.components')
  .directive 'autoInput', InputDirective
