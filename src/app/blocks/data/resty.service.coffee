'use strict'

Resty = ($q) ->

  RestyClass = (@_data = {}, className) ->
    # alias to mimic ngResource
    @className = className
    @get = RestyClass::get
    @query = (filter)->
      RestyClass::get.call(this, 'all')
      .then (rows)->
        return rows if !filter
        return _.filter rows, filter

    @save = RestyClass::post
    @update = RestyClass::put
    @remove = RestyClass::delete
    return


  RestyClass::get = (id) ->
    className = @className
    if id=='all' || `id==null`
      result = _.chain( @_data )
      .each (v,k)->
        v.id = k
        v.className = className
        return
      .value()
      return $q.when _.values result

    if _.isArray id
      promises = []
      self = this
      _.each id, (i)->
        promises.push RestyClass::get.call(self, i).catch (err)->
          return $q.when null
        return
      return $q.all( promises).then (o)->
        return _.compact o

    result = @_data[id]
    if result?
      result.id = id
      return $q.when angular.copy result
    return $q.reject false

  RestyClass::post = (o, id)->
    return $q.reject false if `o==null`
    id = id || _.keys( @_data ).length
    o.id = id
    return $q.when @_data[id] = o

  RestyClass::put = (id, o, update) ->
    return $q.reject false if `o==null`
    if @_data[id]?
      o.id = id
      if update
        return $q.when angular.extend @_data[id], o
      else  # replace
        return $q.when @_data[id] = o
    return $q.reject false

  RestyClass::delete = (id)->
    return $q.reject false if `id==null` || !@_data[id]
    delete @_data[id]
    return $q.when true



  # static methods
  RestyClass.lorempixel = (w,h,cat)->
    # [abstract animals business cats city food nightlife fashion people nature sports technics transport]
    src = "http://lorempixel.com/"
    if w?
      if h1?
        src += w + '/' + h + '/'
      else
        src += w + '/' + w + '/' # degrade to square
    if cat?
      src += cat + '/'
    return src

  return RestyClass

Resty.$inject = ['$q']

angular.module 'blocks.data'
  .factory 'Resty', Resty
