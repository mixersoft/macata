#methods.coffee
'use strict'

Meteor.methods {
  getOpenGraph: (url)->
    # see: https://www.npmjs.com/package/suq
    resp = Async.runSync (done)->
      suq = Meteor.npmRequire('suq')
      suq url, (err, json, body)->
        return done(err) if err
        openGraphTags = json.opengraph
        # console.log(JSON.stringify(openGraphTags, null, 2))
        return done( null, openGraphTags)
    return resp.result
  }


# package simple:rest
Meteor.method 'get-open-graph'
  , (queryString)->
    console.log ['get-open-graph', queryString]
    # see: https://www.npmjs.com/package/suq
    resp = Async.runSync (done)->
      suq = Meteor.npmRequire('suq')
      suq queryString.url, (err, json, body)->
        return done(err) if err
        openGraphTags = json.opengraph
        # console.log(JSON.stringify(openGraphTags, null, 2))
        # console.log(JSON.stringify(json.microformat, null, 2))
        if not _.isEmpty json.microformat
          console.log("microformat: " + JSON.stringify(json.microformat, null, 2))
        return done( null, openGraphTags)
    return resp.result
  , {
    httpMethod: 'get'
    getArgsFromRequest: (request)->
      # console.log request.query
      return [request.query]
  }

# // Enable cross origin requests for all endpoints
JsonRoutes.setResponseHeaders({
  "Cache-Control": "no-store",
  "Pragma": "no-cache",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, PUT, POST, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Requested-With"
})


