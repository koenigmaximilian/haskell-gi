### 2.0.15

+ Remove enable-overloading flags, and use instead explicit CPP checks for 'haskell-gi-overloading-1.0', see [how to disable overloading](https://github.com/haskell-gi/haskell-gi/wiki/Overloading\#disabling-overloading).

### 2.0.15

+ Fix introspection info for [pixbufNew](https://hackage.haskell.org/package/gi-gdkpixbuf/docs/GI-GdkPixbuf-Objects-Pixbuf.html#v:pixbufNew), [pixbufCopy](https://hackage.haskell.org/package/gi-gdkpixbuf/docs/GI-GdkPixbuf-Objects-Pixbuf.html#v:pixbufCopy), [pixbufCompositeColorSimple](https://hackage.haskell.org/package/gi-gdkpixbuf/docs/GI-GdkPixbuf-Objects-Pixbuf.html#v:pixbufCompositeColorSimple) and [pixbufScaleSimple](https://hackage.haskell.org/package/gi-gdkpixbuf/docs/GI-GdkPixbuf-Objects-Pixbuf.html#v:pixbufScaleSimple). The return values in all these cases can be null, but were not marked as such. See https://github.com/haskell-gi/haskell-gi/issues/127.
