argv        = require('yargs').alias('p', 'production').argv
bower       = require 'bower'
browserSync = require('browser-sync').create()
cache       = require 'gulp-cached'
coffee      = require 'gulp-coffee'
coffeelint  = require 'gulp-coffeelint'
coffeStylish= require 'coffeelint-stylish'
del         = require 'del'
gulp        = require 'gulp'
gutil       = require 'gulp-util'
inject      = require 'gulp-inject'
jade        = require 'gulp-jade'
# minifyCss   = require 'gulp-minify-css'
cssnano     = require 'gulp-cssnano'
path        = require 'path'
runSequence = require 'run-sequence'
sass        = require 'gulp-sass'
scssLint    = require 'gulp-scss-lint'
scssStylish = require 'gulp-scss-lint-stylish'
series      = require 'stream-series'
uglify      = require 'gulp-uglify'
concat      = require 'gulp-concat'
rename      = require 'gulp-rename'
filter      = require 'gulp-filter'
templates   = require 'gulp-angular-templatecache'
vendor      = require './vendor.json'

paths =
  sass: ['src/app/**/*.scss']
  jade: ['src/app/**/*.jade']
  coffee: ['src/app/**/*.coffee', 'src/both/**/*.coffee']
  img: './src/app/img/**/*.*'
  dest: './www/'
  vendor: './www/lib/'
  index: './www/index.html'
  styles: ['./www/**/*.css']
  sources: [ './www/**/*.js', '!templates.js', '!./www/**/*.module.js', '!./www/blocks/router/*', '!./www/core/*', '!./www/layout/*', '!./www/lib/**/*.js']
  modules: ['./www/**/*.module.js', '!./www/blocks/router/*', '!./www/core/*', '!./www/layout/*']
  meteor_coffee: ['src/**/*.coffee', '!src/app/**/*.coffee']
  meteor_dest: './meteor/'

# Add your bower_components vendors to vendor.js
vendorPaths =
  if argv.production then vendor.production
  else vendor.dev

gulp.task 'vendor', ->
  # just copy these files, do NOT inject
  copyPaths = vendor.loadFirst.map (p) -> path.resolve("./bower_components", p)
  absolutePaths = vendorPaths.map (p) -> path.resolve("./bower_components", p)
  gulp.src absolutePaths.concat(copyPaths), base: './bower_components'
    .pipe gulp.dest paths.vendor

gulp.task 'images', ->
  gulp.src paths.img
    .pipe gulp.dest path.join paths.dest, 'img'

gulp.task 'sass', ->
  gulp.src paths.sass
    .pipe cache 'sass'
    # .pipe scssLint customReport: scssStylish
    .pipe sass errLogToConsole: true
    # .pipe if argv.production then minifyCss() else gutil.noop()
    .pipe if argv.production then cssnano() else gutil.noop()
    .pipe gulp.dest(paths.dest)

gulp.task 'jade', ->
  if !argv.production
    gutil.log('task jade/DEV')
    gulp.src paths.jade
      .pipe cache 'jade'
      .pipe jade if argv.production then gutil.noop() else pretty: true
      .pipe gulp.dest(paths.dest)
  else
    gutil.log('task jade/PRODUCTION')
    gulp.src paths.jade
      .pipe filter ['**/index.*']
      .pipe cache 'jade'
      .pipe jade gutil.noop()
      .pipe gulp.dest(paths.dest)

    gulp.src paths.jade
      .pipe filter ['**/*.*','!**/index.*']
      .pipe cache 'jade'
      .pipe jade gutil.noop()
      .pipe templates( 'templates/templates.js' )
      .pipe gulp.dest(paths.dest)
      
gulp.task 'coffee', ->
  gulp.src paths.coffee
    .pipe cache 'coffee'
    .pipe coffeelint()
    .pipe coffeelint.reporter coffeStylish
    .pipe coffee().on('error', gutil.log)
    .pipe if argv.production then uglify() else gutil.noop()
    .pipe gulp.dest(paths.dest)

gulp.task 'meteor_coffee', ->
  gulp.src paths.meteor_coffee
    .pipe cache 'meteor'
    .pipe coffeelint()
    .pipe coffeelint.reporter coffeStylish
    .pipe coffee().on('error', gutil.log)
    .pipe if argv.production then uglify() else gutil.noop()
    .pipe gulp.dest(paths.meteor_dest)

gulp.task 'index', ->
  # Inject in the correct order to startup app
  vendor0_paths =  vendor.loadFirst.map (p) ->
    # manual load: ionic.bundle.js, ionic.io.bundle.js, ng-cordova.js
    return "!**/"+p if /ionic.bundle|ionic.io.bundle|ng-cordova/.test p 
    return paths.vendor+"**/"+p
  vendor1_paths = [paths.vendor+'**/*.js','!**/lib/ionic/**']
    .concat vendor.loadFirst.map (p) -> "!**/"+p
  gutil.log(["inject first:"].concat(vendor0_paths))
  gutil.log(["inject second:"].concat(vendor1_paths))

  # no concat()
  blocks = gulp.src ['./www/blocks/router/*.module.js', './www/blocks/router/*.js'], read: false
  layout = gulp.src ['./www/layout/layout.module.js', './www/layout/layout.route.js'], read: false

  if argv.production
    # concat for production
    vendor0 = gulp.src vendor0_paths
      .pipe( concat('vendor.0.js') )
      .pipe gulp.dest paths.dest 
    vendor1 = gulp.src vendor1_paths
      .pipe( concat('vendor.1.js') )
      .pipe gulp.dest paths.dest
    core = gulp.src ['./www/core/core.module.js', './www/core/core.*.js']
      .pipe( concat('core.js') ).pipe gulp.dest paths.dest
    modules = gulp.src paths.modules
      .pipe( concat('modules.js') ).pipe gulp.dest paths.dest
    sources = gulp.src( paths.sources )
      .pipe( concat('application.js') ).pipe gulp.dest paths.dest
    styles = gulp.src paths.styles
      .pipe( concat('app.css') ).pipe gulp.dest( paths.dest + 'scss/')
  else
    # no concat() for dev
    vendor0 = gulp.src vendor0_paths, read: false
    vendor1 = gulp.src vendor1_paths, read: false
    core = gulp.src ['./www/core/core.module.js', './www/core/core.*.js'], read: false
    modules = gulp.src paths.modules, read: false
    styles = gulp.src paths.styles, read: false
    sources = gulp.src paths.sources, read: false

  target = gulp.src paths.index
  target.pipe inject series(vendor0, vendor1, blocks, core, layout, modules, styles, sources), relative: true
    .pipe gulp.dest paths.dest

gulp.task 'clean', (done) ->
  cache.caches = {}
  del [paths.dest], done

gulp.task 'sass-watch', ['sass'], -> browserSync.reload()
gulp.task 'jade-watch', ['jade'], -> browserSync.reload()
gulp.task 'coffee-watch', ['coffee', 'meteor_coffee']

gulp.task 'serve', ->
  browserSync.init
    server:
      baseDir: 'www'
    ghostMode: false

  gulp.watch paths.sass, ['sass-watch']
  gulp.watch paths.jade, ['jade-watch']
  gulp.watch paths.coffee, (event) ->
    if event.type is 'added' or event.type is 'deleted'
      runSequence 'coffee-watch', 'index'
    else runSequence 'coffee-watch'
    browserSync.reload()

gulp.task 'bowerInstall',  ->
  bower.commands.install()
  .on 'log', (data) ->
    gutil.log 'bower', gutil.colors.cyan(data.id), data.message

gulp.task 'dev', (done) ->
  runSequence 'build', 'serve', done

gulp.task 'build', (done) ->
  runSequence 'clean', 'bowerInstall', 'vendor', ['sass', 'jade', 'coffee', 'meteor_coffee', 'images'], 'index', done

# Default task: development build
gulp.task 'default', ['build']
