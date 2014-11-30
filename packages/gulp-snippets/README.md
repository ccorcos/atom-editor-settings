---
# Coffeescript & Javascript Gulp snippets for [Atom](http://atom.io)
[![Build Status](https://travis-ci.org/manolenso/atom-gulp-snippets.svg?branch=master)](https://travis-ci.org/manolenso/atom-gulp-snippets)

---

### Install with `apm install gulp-snippets`

## Development
```sh
$ cd ~/.atom/packages
$ git clone https://github.com/manolenso/atom-gulp-snippets
$ cd atom-gulp-snippets
$ apm install
$ apm link
```

# `Gulp JavaScript:`

### start gulp project, 2 to 5 plugin & npm init for package
This is for starting gulp project, 2 to 5 plugins require,
CTRL+x and paste in terminal create: README.md, package.json
and install Gulp plugins.

### [gust2] to [gust5] Gulp Start project


```javascript
var gulp = require(gulp),
${1:plugin} = require('gulp-${2:plugin_name}'),
${3:plugin} = require('gulp-${4:plugin_name}'),
${5:plugin} = require('gulp-${6:plugin_name}'),
${7:plugin} = require('gulp-${8:plugin_name}'),
${9:plugin} = require('gulp-${10:plugin_name}');
```
```bash
//Ctrl-x and Paste in terminal
${11:touch README.md &&
npm init &&
npm install --save-dev gulp &&
npm install --save-dev gulp-${2:plugin_name} &&
npm install --save-dev gulp-${4:plugin_name} &&
npm install --save-dev gulp-${6:plugin_name} &&
npm install --save-dev gulp-${8:plugin_name} &&
npm install --save-dev gulp-${10:plugin_name}}
```


### [guv] Gulp plugin require

```javascript
var ${1:plugin-variable} = require('gulp-${2:plugin-name}');$3
```
### [gupth] Gulp Paths

```javascript
var ${1:varPath} = [
  '${2:Path/to/folders/files}'$3
];
```
### [gus] Gulp Task Source

```javascript
gulp.task('${1:Task}', function () {
  return gulp.src('${2:Source}')
  .pipe(${3:plugin}($4))$5
  $6
});
```
### [guw] Gulp Task Watch

```javascript
gulp.task('watch', function () {
  gulp.watch('$1', ['$2']);$3
});
```

### [gup] Gulp Pipe

```javascript
.pipe(${1:plugin}($2))
$3
```
### [guw2] to [guw5] Gulp Task Watch, 2 to 5 tasks as default

```javascript
gulp.task('watch', function () {
  gulp.watch('${5:sources}', ['$1']);
  gulp.watch('${6:sources}', ['$2']);
  gulp.watch('${7:sources}', ['$3']);
  gulp.watch('${8:sources}', ['$4']);
});

gulp.task('default', ['$1', '$2', '$3', '$4', 'watch']);$9
```


----
# `Gulp CoffeeScript:`

### start gulp project, 2 to 5 plugin & npm init for package
This is for starting gulp project, 2 to 5 plugins require,
CTRL+x and paste in terminal create: README.md, package.json
and install Gulp plugins.


### [cgust2] to [cgust5] Coffee Gulp Start project

```coffeescript
var gulp = require(gulp),
${1:plugin} = require('gulp-${2:plugin_name}'),
${3:plugin} = require('gulp-${4:plugin_name}'),
${5:plugin} = require('gulp-${6:plugin_name}'),
${7:plugin} = require('gulp-${8:plugin_name}'),
${9:plugin} = require('gulp-${10:plugin_name}');
```
```bash
//Ctrl-x and Paste in terminal
${11:touch README.md &&
npm init &&
npm install --save-dev gulp &&
npm install --save-dev coffee-script &&
npm install --save-dev gulp-${2:plugin_name} &&
npm install --save-dev gulp-${4:plugin_name} &&
npm install --save-dev gulp-${6:plugin_name} &&
npm install --save-dev gulp-${8:plugin_name} &&
npm install --save-dev gulp-${10:plugin_name}}
```

### [cguv] Coffee Require variable

```coffeescript
${1:plugin} = require 'gulp-${2:plugin_name}'
$3
```
### [cgupth] Coffee Gulp Paths

```javascript
${1:varPath} = [
  '${2:Path/to/folders/files}'$3
]
```
### [cgus] Coffee Gulp Task Source

```coffeescript
gulp.task '${1:name}', ->
  gulp.src '${2:sources}'
    .pipe ${3:plugin}($4)
    $5
```

### [cguw] Coffee Task Watch

```coffeescript
gulp.task 'watch', ->
  gulp.watch '$1', ['$2']
  $3
```

### [cgup] Coffee Gulp Pipe

```coffeescript
.pipe ${1:plugin}($2)
$3
```

### [cguw2] to [cguw5] Gulp Task Watch, 2 to 5 tasks as default

```coffeescript
gulp.task 'watch', ->
  gulp.watch '${5:sources}', ['$1']
  gulp.watch '${6:sources}', ['$2']
  gulp.watch '${7:sources}', ['$3']
  gulp.watch '${8:sources}', ['$4']

gulp.task 'default', ['$1', '$2', '$3', '$4', 'watch']$9
```

## License
[MIT Licence](LICENCE.md)©Laurent Remy
