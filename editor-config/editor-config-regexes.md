# EditorConfig Regexes

## Finding parts in `.editorconfig` files

```
([\w\.]*)\s?=\s?([\w:_-]*)\s?(#(.*))?)
```

```
([\w\.])+\s=\s?(\w[\w,\s\+\-\(\):\*\d]+)?
```

```
([\w\.])+\s=\s?([\w\-\s\+,\(\):]+)?(#([\s\w'-\(\)-\.\[\]]+))?
```

```
(([\w\.]+)\s=\s?([\w\-\s\+,\(\):]+)?(#([\s\w'-\(\)-\.\[\]]+))?)
```
Groups:

- Property name: `([\w\.]*)`
- Property value: `([\w:-]*)`