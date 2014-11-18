# [atom-beautify](https://github.com/donaldpipowitch/atom-beautify)

[![Gitter chat](https://badges.gitter.im/Glavin001/atom-beautify.png)](https://gitter.im/Glavin001/atom-beautify)
[![Issue Stats](http://issuestats.com/github/glavin001/atom-beautify/badge/pr?style=flat)](http://issuestats.com/github/glavin001/atom-beautify)
[![Issue Stats](http://issuestats.com/github/glavin001/atom-beautify/badge/issue?style=flat)](http://issuestats.com/github/glavin001/atom-beautify)

> [Beautify](https://github.com/einars/js-beautify)
HTML (including [Handlebars](http://handlebarsjs.com/)),
CSS (including [Sass](http://sass-lang.com/) and [LESS](http://lesscss.org/)),
JavaScript, and much more in Atom.

Atom Package: https://atom.io/packages/atom-beautify

```bash
apm install atom-beautify
```

Or Settings/Preferences ➔ Packages ➔ Search for `atom-beautify`


## Language Support

- [x] JavaScript and JSON
- [x] HTML, including
  - [x] [Handlebars](http://handlebarsjs.com/)
  - [x] [Mustache](http://mustache.github.io)
  - [x] [Embedded Ruby (ERB)](https://github.com/Glavin001/atom-beautify/issues/80)
    - Requires [htmlbeautifier](https://github.com/threedaymonk/htmlbeautifier)
  - [x] XML
- [x] CSS, including
  - [Sass](http://sass-lang.com/)
  - [LESS](http://lesscss.org/)
- [x] [SQL](https://github.com/Glavin001/atom-beautify/pull/67)
  - Requires [python-sqlparse](https://github.com/andialbrecht/sqlparse)
- [x] [Markdown](https://github.com/Glavin001/atom-beautify/issues/93#issuecomment-55642483)
  - Requires [Pandoc](http://johnmacfarlane.net/pandoc/) to be already installed
- [X] [Perl](https://github.com/Glavin001/atom-beautify/issues/33)
- [x] [PHP](https://github.com/donaldpipowitch/atom-beautify/issues/26)  
  - Requires [PHP_Beautifier](http://pear.php.net/package/PHP_Beautifier) to be already installed.
- [x] [Python](https://github.com/donaldpipowitch/atom-beautify/issues/24)
  - Requires [autopep8](https://github.com/hhatto/autopep8) to be already installed.
  - Beautifies to [PEP 8](http://legacy.python.org/dev/peps/pep-0008/).
- [x] [Ruby](https://github.com/donaldpipowitch/atom-beautify/issues/25)
  - Requires [RBeautify](https://github.com/erniebrodeur/ruby-beautify)
- [x] [CoffeeScript](https://github.com/donaldpipowitch/atom-beautify/issues/31)
- [x] [Java](https://github.com/Glavin001/atom-beautify/issues/45)
  - Requires [Uncrustify](http://sourceforge.net/projects/uncrustify/)
- [x] [C](https://github.com/Glavin001/atom-beautify/issues/57)
  - Requires [Uncrustify](http://sourceforge.net/projects/uncrustify/)
- [x] [C++](https://github.com/Glavin001/atom-beautify/issues/57)
  - Requires [Uncrustify](http://sourceforge.net/projects/uncrustify/)
- [x] [C#](https://github.com/Glavin001/atom-beautify/issues/57)
  - Requires [Uncrustify](http://sourceforge.net/projects/uncrustify/)
- [x] [Objective-C](https://github.com/Glavin001/atom-beautify/issues/57)
  - Requires [Uncrustify](http://sourceforge.net/projects/uncrustify/)
- [x] [D](https://github.com/Glavin001/atom-beautify/issues/57)
  - Requires [Uncrustify](http://sourceforge.net/projects/uncrustify/)
- [x] [Pawn](https://github.com/Glavin001/atom-beautify/issues/57)
  - Requires [Uncrustify](http://sourceforge.net/projects/uncrustify/)
- [x] [Vala](https://github.com/Glavin001/atom-beautify/issues/57)
  - Requires [Uncrustify](http://sourceforge.net/projects/uncrustify/)
- [x] [TypeScript](https://github.com/Glavin001/atom-beautify/issues/49)

## Usage

Open the [Command Palette](https://github.com/atom/command-palette), and type `Beautify`.

It will only beautify selected text, if a selection is found - if not, the whole file will be beautified.

### Shortcut

You can also type `ctrl-alt-b` as a shortcut or click `Packages > Beautify` in the menu.

#### Custom Keyboard Shortcuts

See [Keymaps In-Depth](https://atom.io/docs/latest/advanced/keymaps) for more details.

For example:

```coffeescript
'.editor': # Available from Editor only
  'ctrl-alt-b': 'beautify'
```

### Package Options

- `beautifyOnSave`  (Default *false*)
You can also choose to beautify on every file save.

- `beautifyEntireFileOnSave` (Default *true*)
Beautification will normally only beautify your selected text.
However, when beautification occurs on save then it will
be forced to beautify the entire file's contents,
not just selected text.

- `disabledLanguages` (Default *empty array*)
An array of Grammar names to disable beautification for.
Note: If using the Atom's Package Settings then an array is
represented as comma-separated string.

- `muteUnsupportedLanguageErrors` (Default *false*)
Mute only *unsupported language* errors.

- `muteAllErrors` (Default *false*)
Do not show the *Atom Beautify Error Messages* panel
for any of the errors occurring while beautifying.

- `analytics`  (Default *true*)
There is [Segment.io](https://segment.io/),
which forwards the data to [Google Analytics](http://www.google.com/analytics/),
to track what languages
are being used the most and other stats.
Everything is anonymized and no personal information,
such as source code, is sent.
See https://github.com/Glavin001/atom-beautify/issues/47
for more details.

## Configuration

Edit your `.jsbeautifyrc` file in any of the following locations:

- Atom Package Settings  
  `Atom` ➔ `Preferences` ➔ Search for `atom-beautify`
- Same directory as current file
- Project root  
`atom-beautify` will recursively look up from the current file's directory to find `.jsbeautifyrc`.
- Your User's Home directory

**Note**: *Comments are supported in `.jsbeautifyrc` thanks to [strip-json-comments](https://github.com/sindresorhus/strip-json-comments).*

See examples of both way inside [`examples/`](https://github.com/donaldpipowitch/atom-beautify/tree/master/examples)

Option table is available at the [js-beautify repo](https://github.com/beautify-web/js-beautify#options).

### Simple

See [examples/simple-jsbeautifyrc/.jsbeautifyrc](https://github.com/donaldpipowitch/atom-beautify/blob/master/examples/simple-jsbeautifyrc/.jsbeautifyrc).

```json
{
  "indent_size": 2,
  "indent_char": " ",
  "other": " ",
  "indent_level": 0,
  "indent_with_tabs": false,
  "preserve_newlines": true,
  "max_preserve_newlines": 2,
  "jslint_happy": true,
  "indent_handlebars": true
}
```

### Nested

See [examples/nested-jsbeautifyrc/.jsbeautifyrc](https://github.com/donaldpipowitch/atom-beautify/blob/master/examples/nested-jsbeautifyrc/.jsbeautifyrc).

```json
{
  "html": {
    "brace_style": "collapse",
    "indent_char": " ",
    "indent_scripts": "normal",
    "indent_size": 6,
    "max_preserve_newlines": 1,
    "preserve_newlines": true,
    "unformatted": ["a", "sub", "sup", "b", "i", "u"],
    "wrap_line_length": 0
  },
  "css": {
    "indent_char": " ",
    "indent_size": 4
  },
  "js": {
    "indent_size": 2,
    "indent_char": " ",
    "indent_level": 0,
    "indent_with_tabs": false,
    "preserve_newlines": true,
    "max_preserve_newlines": 2,
    "jslint_happy": true
  },
  "sql": {
    "indent_size": 4,
    "indent_char": " ",
    "indent_level": 0,
    "indent_with_tabs": false
  }
}
```

## Advanced Language Setup

### PHP

To use with PHP we require [PHP_Beautifier](http://pear.php.net/package/PHP_Beautifier)
and that you set the `Php beautifier path` in the package settings.

#### Retrieve the path on Mac & Linux

Run `which php_beautifier` in your Terminal.

### Python

To use with Python we require [autopep8](https://github.com/hhatto/autopep8)
and that you set the `Python autopep8 path` in the package settings.

#### Retrieve the path on Mac & Linux

Run `which autopep8` in your Terminal.

### Markdown

To use with Markdown we require [pandoc](http://johnmacfarlane.net/pandoc/)
and you set the `Markdown Pandoc path` in the package settings.


## Contributing

[See all contributors on GitHub](https://github.com/donaldpipowitch/atom-beautify/graphs/contributors).

Please update the [CHANGELOG.md](https://github.com/donaldpipowitch/atom-beautify/blob/master/CHANGELOG.md),
add yourself as a contributor to the [package.json](https://github.com/donaldpipowitch/atom-beautify/blob/master/package.json),
and submit a [Pull Request on GitHub](https://help.github.com/articles/using-pull-requests).

## License

[MIT](https://github.com/donaldpipowitch/atom-beautify/blob/master/LICENSE.md) © [Donald Pipowitch](https://github.com/donaldpipowitch)
