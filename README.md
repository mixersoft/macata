# grid
An app for elevating community meals around the world.

## installation
```
git clone https://github.com/mixersoft/openmaca.git [folder]
cd [folder]
mkdir www
ionic lib update
bower install
npm install
# if you need to run as administrator, use `sudo npm install`

# To continue dev in a new git repo
git remote rename origin seed
git remote add origin [github repo]
git push -u origin master


# add Cordova platforms
# note: this project has only been tested on iOS
ionic platform add ios
gulp build
ionic build ios

# install Cordova plugins from web
ionic plugin add cordova-plugin-console
ionic plugin add com.ionic.keyboard
ionic plugin add cordova-plugin-device
ionic plugin add cordova-plugin-splashscreen
ionic plugin add cordova-plugin-geolocation

# set bower_components/meteor-client-side:
__meteor_runtime_config__.DDP_DEFAULT_CONNECTION_URL = 'http://localhost:3333';

```



# Based on ionic-tabs-starter-sass-jade-coffee

Ionic tabbed view starter project implemented with Sass, Jade and CoffeeScript.

The original project in JavaScript was done by [benevolentprof](https://github.com/benevolentprof "benevolentprof") @ [ionic-tabs-starter-angular-style](https://github.com/benevolentprof/ionic-tabs-starter-angular-style "ionic-tabs-starter-angular-style"),
an Ionic tabbed view starter project refactored according to the Angular Style Guide.
