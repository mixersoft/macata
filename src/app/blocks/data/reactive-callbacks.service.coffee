'use strict'

ReactiveTransformSvc = ($q)->

  ReactiveTransformClass = (@context, @callbacks = {}) ->
    @onLoadPromise = null  # promise
    @isChanging = false

    @onLoad = (o, silent) ->
      return $q.reject('wait') if @isChanging && not silent
      return @onLoadPromise if @onLoadPromise
      return $q.reject('not-ready') if _.isEmpty o
      @isChanging = true if not silent
      self = @
      return @onLoadPromise = $q.when(o)
        .then (o)->
          return o if not self.callbacks['onLoad']?
          return self.callbacks['onLoad'].call(self, o, self)
        .finally (o)->
          self.isChanging = false if not silent

    @onChange = (o)->
      return $q.reject('wait') if @isChanging
      self = @
      self.isChanging = true
      return @onLoad(o, 'silent')
        .then ()->
          return o if not self.callbacks['onChange']?
          return self.callbacks['onChange'].call(self, o, self)
        .finally ()->
          self.isChanging = false

    return

  return ReactiveTransformClass

ReactiveTransformSvc.$inject = ['$q']

angular.module 'blocks.data'
  .factory 'ReactiveTransformSvc', ReactiveTransformSvc
