'use strict'

UsersResource = (Resty, $q, unsplashItSvc) ->
  className = 'Users'
  data = {
    0:
      firstname  : 'Masie'
      lastname   : 'May'
      username   : 'maymay'
      displayName: 'maymay'
      face       : Resty.lorempixel 200, 200, 'people'
    1:
      firstname  : 'Marky'
      lastname   : 'Mark'
      username   : 'marky'
      displayName: 'marky'
      face       : Resty.lorempixel 200, 200, 'people'
    2:
      firstname  : 'Lucy'
      lastname   : 'Lu'
      username   : 'lulu'
      displayName: 'lulu'
      face       : Resty.lorempixel 200, 200, 'people'
    3:
      firstname  : 'Chucky'
      lastname   : 'Chu'
      username   : 'chuchu'
      displayName: 'chuchu'
      face       : Resty.lorempixel 200, 200, 'people'
    4:
      firstname  : 'Daisy'
      lastname   : 'Duke'
      username   : 'dudu'
      displayName: 'dudu'
      face       : Resty.lorempixel 200, 200, 'people'
    5:
      firstname  : 'Bobby'
      lastname   : 'Boo'
      username   : 'booboo'
      displayName: 'booboo'
      face       : Resty.lorempixel 200, 200, 'people'

  }
  # add id to lorempixel urls
  _.each data, (v,k)->
    v.face += k
    return


  service = new Resty(data, className)


  # API_ENDPOINT = {
  #   uifaces:
  #     getOne: 'http://uifaces.com/api/v1/random'
  #     getByName: 'http://uifaces.com/api/v1/user/'
  # }
  # fetchUiFaces = (user, name)->
  #   url =
  #     if name
  #     then API_ENDPOINT.uifaces.getByName + name
  #     else API_ENDPOINT.uifaces.getOne
  #   return unsplashItSvc.get(url)
  #
  #
  # service.query()
  # .then (users)->
  #   promises =  _.map users, (user)->
  #     return fetchUiFaces(user)
  #     .then (resp)->
  #       return $q.reject(resp) if resp.statusText != 'OK'
  #       result = resp.data
  #       user.username = result.username
  #       user.face = result.image_urls.epic
  #       return user

  
  promises = []
  promises.push service.query()
  promises.push unsplashItSvc.ready
  $q.all(promises).then (result)->
    [users, list] = result
    _.each users, (user)->
      user.face = unsplashItSvc.getImgSrc(user.id, 'people', {face:true} )
    return users


  return service


UsersResource.$inject = ['Resty', '$q', 'unsplashItSvc']

angular.module 'starter.core'
  .factory 'UsersResource', UsersResource
