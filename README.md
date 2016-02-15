# sorcery

#### a sane wrapper around libmagic for guessing the encoding of files

This is a proof-of-concept for running `libmagic` on Windows.

## What's `libmagic`?

[libmagic](http://linux.die.net/man/3/libmagic) is a Unix library for
interrogating the contents of a file or buffer to understand what the
encoding of the file might be. It's an imperfect process, but it has
a large database of formats to work with.

## What does this do?

This demo makes `libmagic` consumable from .NET code via P/Invoke. That's
it.

You can invoke it by specifying the relative or absolute path to
the file:

```csharp
var maybeUtf8Encoding = Magic.Description(@".\examples\Octokit.rb.md");
Console.WriteLine("Found: '{0}'" + maybeUtf8Encoding);
// Found: 'UTF-8 Unicode English text, with very long lines, with CRLF line terminators'
```

## Status

At this point I'm not sure how far this will go, but given I had to
construct this from various incomplete samples and troubleshoot a bunch
of silly P/Invoke stuff, perhaps someone else will be interested in this.



