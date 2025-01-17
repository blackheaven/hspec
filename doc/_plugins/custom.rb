require 'digest'
require "jekyll-less"

module Hspec
  module CustomFilters
    def runhaskell(args)
      cmd = "runhaskell -Wall -Werror #{args}"
      cache  = "_cache/runhaskell"
      system "mkdir -p #{cache}"

      source = args.split.select {|i| i[/\.hs$/] }.first
      digest = Digest::MD5.hexdigest(cmd + File.read(source))
      file   = File.join cache, digest

      if File.exists? file
        File.read file
      else
        puts "#{cmd}"
        r = `#{cmd}`
          .gsub(/Finished in \S+ seconds/, 'Finished in 0.0005 seconds')
          .gsub(/_includes\/introduction\/MathSpec.hs:/, 'MathSpec.hs:')
          .gsub(/_includes\/introduction\/step2\/Math.hs:/, 'Math.hs:')
          .gsub(/_includes\/[a-zA-Z]+\.hs:/, 'Spec.hs:')
        File.write file, r
        puts "  created cache file #{file}"
        r
      end
    end

    def id(name)
      haskell_identifiers = {
        'property'              => 'https://hackage.haskell.org/package/QuickCheck/docs/Test-QuickCheck.html#v:property',
        'Property'              => 'https://hackage.haskell.org/package/QuickCheck/docs/Test-QuickCheck.html#t:Property',
        'Testable'              => 'https://hackage.haskell.org/package/QuickCheck/docs/Test-QuickCheck.html#t:Testable',

        '@?='                   => 'https://hackage.haskell.org/package/HUnit/docs/Test-HUnit-Base.html#v:-64--63--61-',

        'Spec'                  => 'https://hackage.haskell.org/package/hspec/docs/Test-Hspec.html#t:Spec',
        'hspec'                 => 'https://hackage.haskell.org/package/hspec/docs/Test-Hspec.html#v:hspec',

        'Test.Hspec.QuickCheck' => 'https://hackage.haskell.org/package/hspec/docs/Test-Hspec-QuickCheck.html',
        'prop'                  => 'https://hackage.haskell.org/package/hspec/docs/Test-Hspec-QuickCheck.html#v:prop',

        'fromHUnitTest'         => 'https://hackage.haskell.org/package/hspec-contrib/docs/Test-Hspec-Contrib-HUnit.html#v:fromHUnitTest',

        'Selector'              => 'https://hackage.haskell.org/package/hspec-expectations/docs/Test-Hspec-Expectations.html#t:Selector',
        'shouldThrow'           => 'https://hackage.haskell.org/package/hspec-expectations/docs/Test-Hspec-Expectations.html#v:shouldThrow',
        'errorCall'             => 'https://hackage.haskell.org/package/hspec-expectations/docs/Test-Hspec-Expectations.html#v:errorCall',

        'isPermissionError'     => 'https://hackage.haskell.org/package/base/docs/System-IO-Error.html#v:isPermissionError',
        'evaluate'              => 'https://hackage.haskell.org/package/base/docs/Control-Exception.html#v:evaluate',
        'ErrorCall'             => 'https://hackage.haskell.org/package/base/docs/Control-Exception.html#t:ErrorCall',

        'force'                 => 'https://hackage.haskell.org/package/deepseq/docs/Control-DeepSeq.html#v:force',
      }
      url = haskell_identifiers[name]
      if url
        "[`#{name}`](#{url})"
      else
        puts "WARNING: No link destination for #{name}!"
        "`#{name}`"
      end
    end
  end
end

Liquid::Template.register_filter(Hspec::CustomFilters)

module Hspec
  class NoteTag < Liquid::Tag
    def initialize(tag_name, note, tokens)
      super
      @note = note.strip
    end

    def render(context)
      renderer = Redcarpet::Render::HTML.new
      note = Redcarpet::Markdown.new(renderer).render("**Note:** " + @note)
      "<div class=\"note\">#{note}</div>"
    end
  end

  class RequireTag < NoteTag
    def initialize(tag_name, version, tokens)
      super(tag_name, "This section assumes that you are using `hspec-#{version.strip}` or later.", tokens)
    end
  end
end

Liquid::Template.register_tag('require', Hspec::RequireTag)
Liquid::Template.register_tag('note', Hspec::NoteTag)

module Hspec
  class ExampleTag < Liquid::Tag
    def initialize(tag_name, file, tokens)
      super
      @file = file.strip
    end

    def render(context)
      file = File.join '_includes', @file
      partial = Liquid::Template.parse(add_wrapping file)
      context.stack do
        partial.render(context)
      end
    end

    def add_wrapping(file)
      source = File.read(file)
<<-HTML
{% highlight hspec %}
-- file Spec.hs
#{source}
{% endhighlight %}
<pre><kbd class="shell-input">runhaskell Spec.hs</kbd>
<samp>{{ "#{file} --html --seed 921447365 --ignore-dot-hspec" | runhaskell }}</samp></pre>
HTML
    end
  end
end

module Hspec
  class FoldableExampleTag < ExampleTag
    def add_wrapping(*)
      source = super
      # It is crucial to indent nested HTML tags, otherwise a bug in sundowns
      # parser is triggered, which leads to invalid HTML!  See
      # https://github.com/vmg/sundown/issues/139.
<<-HTML
<div>
  <h5 class="foldable">Example code:</h5>
  <div>
#{source}
  </div>
</div>
HTML
    end
  end
end

Liquid::Template.register_tag('inline_example', Hspec::ExampleTag)
Liquid::Template.register_tag('example', Hspec::FoldableExampleTag)
