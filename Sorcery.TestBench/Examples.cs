﻿using Mono.Unix;
using Xunit;

namespace Sorcery.TestBench
{
    public class Examples
    {
        [Fact]
        public void DetectsAUtf8File()
        {
            var maybeUtf8Encoding = Magic.Descrition(@".\examples\Octokit.rb.md");
            Assert.Contains("UTF-8", maybeUtf8Encoding);
            Assert.Contains("Unicode", maybeUtf8Encoding);
            Assert.Contains("with CRLF line terminators", maybeUtf8Encoding);
        }

        [Fact]
        public void DetectsADOSFile()
        {
            var mayBeBatchFile = Magic.Descrition(@".\examples\catalyst.bat");
            Assert.Contains("DOS", mayBeBatchFile);
        }

        [Fact]
        public void DetectsAnAnsiFile()
        {
            var mayBeAnsiEncoding = Magic.Descrition(@".\examples\CustomException.java");
            Assert.Contains("ISO-8859", mayBeAnsiEncoding);
            Assert.Contains("with CRLF line terminators", mayBeAnsiEncoding);
        }
    }
}
