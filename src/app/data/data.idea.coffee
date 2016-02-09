'use strict'

IdeasResource = (Resty, $q, openGraphSvc) ->
  className = 'Recipe'

  # coffeelint: disable=max_line_length
  sampleData = {
    idea: [
      {"fb:admins":"202900140,632263878,500721039,521616638,553471374,3417349,678870357,506741635","fb:app_id":"54208124338","og:type":"yummlyfood:recipe","og:site_name":"Yummly","og:url":"http://www.yummly.com/recipe/Thomas-Keller_s-Roast-Chicken-1286231","og:title":"Thomas Keller's Roast Chicken Recipe","og:image":"http://lh3.googleusercontent.com/h9IttHblN8tuFyHG-A4cDhqzYPNB-yM4jyT2fIgLFxg6lcxKdKCSqPyCz_c5pk0eCS3JLUPXjo2M7CU4pVsWog=s730-e365","yummlyfood:course":"Main Dishes","yummlyfood:ingredients":"butter","yummlyfood:time":"1 hr 30 min","yummlyfood:source":"TLC","og:description":"Thomas Keller's Roast Chicken Recipe Main Dishes with chicken, ground black pepper, salt, orange, lemon, carrots, onions, celery ribs, shallots, bay leaves, thyme sprigs, butter"}
      {"fb:admins":"202900140,632263878,500721039,521616638,553471374,3417349,678870357,506741635","fb:app_id":"54208124338","og:type":"yummlyfood:recipe","og:site_name":"Yummly","og:url":"http://www.yummly.com/recipe/Spice-Crusted-Carrots-with-Harissa-Yogurt-1054422","og:title":"Spice-Crusted Carrots with Harissa Yogurt Recipe","og:image":"http://lh3.googleusercontent.com/Psf5ZDTw2hgQNDOjI0ZtwYqiDWHbeXzMrJALdVSMNhdtedpq5IfQvy_sVZLLuN3tuQIUVkBqkl8LS4I6gDgsm_o=s730-e365","yummlyfood:ingredients":"lemon wedge","yummlyfood:time":"45 min","yummlyfood:source":"Bon Appétit","og:description":"Spice-Crusted Carrots with Harissa Yogurt Recipe with carrots, kosher salt, sugar, mustard powder, spanish paprika, ground cumin, ground coriander, vegetable oil, ground black pepper, plain greek yogurt, harissa paste, chopped fresh thyme, grated lemon zest, lemon wedge"}
      {"og:title":"How Betony Makes Their Short Ribs","og:description":"It's rare that a restaurant opening in Midtown causes much of a stir, but with Chef Bryce Shuman—the former executive Sous Chef of Eleven Madison Park—at the helm, it's no surprise that Betony is making waves. This short rib dish is one of those wave-makers.","og:image":"http://newyork.seriouseats.com/assets_c/2013/08/20130826-264197-behind-the-scenes-betony-short-ribs-29-thumb-625xauto-348442.jpg","og:url":"http://newyork.seriouseats.com/2013/09/how-betony-makes-their-short-ribs.html"}
      {"og:locale":"en_US","og:type":"recipe","og:title":"Red Wine-Braised Short Ribs Recipe - Bon Appétit","og:description":"These Red Wine-Braised Short Ribs are even better when they're allowed to sit overnight.","og:url":"http://www.bonappetit.com/recipe/red-wine-braised-short-ribs","og:site_name":"Bon Appétit","article:publisher":"https://www.facebook.com/bonappetitmag","article:tag":"Beef,Dinner,Meat,Ribs","article:section":"Recipes","og:image":"http://www.bonappetit.com/wp-content/uploads/2011/08/red-wine-braised-short-ribs-940x560.jpg","type":"recipe"}
      {"fb:admins":"202900140,632263878,500721039,521616638,553471374,3417349,678870357,506741635","fb:app_id":"54208124338","og:type":"yummlyfood:recipe","og:site_name":"Yummly","og:url":"http://www.yummly.com/recipe/My-classic-caesar-318835","og:title":"My Classic Caesar Recipe","og:image":"http://lh3.ggpht.com/J8bTX6MuGC-8y87DHlxxagqShmJLlPjXff28hN8gksOpLp3fZJ5XaLCGrkZLYMer3YlNAEoOfl6FyrSsl9uGcw=s730-e365","yummlyfood:course":"Salads","yummlyfood:ingredients":"anchovies","yummlyfood:time":"40 min","yummlyfood:source":"Food52","og:description":"My Classic Caesar Recipe Salads with garlic, anchovy filets, sea salt flakes, egg yolks, lemon, extra-virgin olive oil, country bread, garlic, extra-virgin olive oil, sea salt, romaine lettuce, caesar salad dressing, parmagiano reggiano, ground black pepper, anchovies"}
      {"fb:admins":"202900140,632263878,500721039,521616638,553471374,3417349,678870357,506741635","fb:app_id":"54208124338","og:type":"yummlyfood:recipe","og:site_name":"Yummly","og:url":"http://www.yummly.com/recipe/Pan-roasted-brussel-sprouts-316203","og:title":"Pan Roasted Brussel Sprouts Recipe","og:image":"http://lh3.ggpht.com/__CrxYT6M2LxtItnVSkYQ7u2k-p59E8zryHmLFioy4d5oZj04pkSc88aVpLcjey19YaWUwnnM-TfhtoK4U3jXFQ=s730-e365","yummlyfood:course":"Side Dishes","yummlyfood:ingredients":"extra-virgin olive oil","yummlyfood:time":"35 min","yummlyfood:source":"Food52","og:description":"Pan Roasted Brussel Sprouts Recipe Side Dishes with brussels sprouts, olive oil, garlic cloves, white wine, cracked black pepper, sea salt, extra-virgin olive oil"}
      {"url":"http://whitestorkco.com/","title":"White Stork","image":"https://pbs.twimg.com/profile_images/691694111468945408/H8VRdkNg.jpg","description":"At White Stork, we are passionate about taste and the need to have more good beer in Bulgaria. After extensive research, testing, tasting, tweaking and experimentation since 2011, we hatched our first Pale Ale in December 2013 and wanted to show you the wonders of the Citra hop in our Summer Pale Ale in July 2014. Although our beers are currently made by our amazing master brewer in Belgium, we are building our brewery in Sofia which will hopefully be operational soon."}
    ]
    location: [
      {"lat":42.6700528,"lon":23.314167099999963},
      {"lat":42.6737483,"lon":23.325192799999968},
      {"lat":42.6977082,"lon":23.321867500000053},
      {"lat":42.6599319,"lon":23.31657610000002},
      {"lat":42.6743583,"lon":23.32824210000001},
      {"lat":42.680284,"lon": 23.325271}
      {"lat":42.6945039,"lon":23.340166}
      {"lat":42.7570109,"lon":23.45046830000001},
      {"lat":42.733883,"lon":25.485829999999964}
    ]
  }
  # coffeelint: enable=max_line_length
  # add location to recipes
  data = {}
  _.each sampleData.idea, (o,i)->
    idea = openGraphSvc.normalize o
    idea.id = i + ''
    idea.location = sampleData.location[i]
    data[idea.id] = idea
    return

  service = new Resty(data, className)

  return service


IdeasResource.$inject = ['Resty', '$q', 'openGraphSvc']

angular.module 'starter.data'
  .factory 'IdeasResource', IdeasResource
