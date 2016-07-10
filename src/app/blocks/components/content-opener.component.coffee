ContentOpener = {
  bindings:
    href:     "<"
    disabled: "<"
  template: """<a ng-href="{{$ctrl.target()}}"
  ng-click="$ctrl.target($event)"
  target="_blank" ng-transclude></a>
  """
  transclude: true
  # require:
  controller: [
    '$scope', '$cordovaInAppBrowser'
    ($scope, $cordovaInAppBrowser)->
      $ctrl = this

      # $ctrl.$onInit = ()=>
      # $ctrl.$onChanges = (changes)=>

      $ctrl.target = ( ev )->
        url = $ctrl.href
        return if !url

        if $ctrl.disabled
          ev?.preventDefault()
          return 'javacript:void(0)'

        # use HTML target="_blank" for browsers
        if ionic.Platform.isWebView() == false
          return url

        return 'javacript:void(0)' if !ev
        # $cordovaInAppBrowser.open for devices
        ev.stopImmediatePropagation()
        options = {
          location: 'yes'
          clearcache: 'yes'
          toolbar: 'no'
        }
        $cordovaInAppBrowser.open(url, '_system', options)
        return false

      return $ctrl
  ]
}


angular.module('blocks.components')
  .component 'contentOpener', ContentOpener
