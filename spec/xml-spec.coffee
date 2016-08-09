buildTokenList = (list) ->
  result = list.split /\n+/g
  result.map (line) ->
    [match, value, scopes] = line.match /^\s*(\S.*?)\x20{2,}(.+)$/
    scopes = scopes.trim().split /\s+/g
    {value, scopes}

isString = (input) ->
  "[object String]" is Object::toString.call input

expandScopes = (input) ->
  return input unless input
  if Array.isArray input
    input.map (i) -> expandScopes i
  else if isString(input)
    input.split /\s+/g
  else if typeof input is "object" and input.scopes?
    input.scopes = expandScopes input.scopes
    input
  else
    input


describe "XML grammar", ->
  grammar = null

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage("language-xml")

    runs ->
      grammar = atom.grammars.grammarForScopeName("text.xml")

  it "parses the grammar", ->
    expect(grammar).toBeTruthy()
    expect(grammar.scopeName).toBe "text.xml"

  it "tokenizes comments in internal subsets correctly", ->
    lines = grammar.tokenizeLines """
      <!DOCTYPE root [
      <a> <!-- [] -->
      <b> <!-- [] -->
      <c> <!-- [] -->
      ]>
    """

    scopes = expandScopes "text.xml meta.tag.sgml.doctype.xml meta.internalsubset.xml comment.block.xml punctuation.definition.comment.xml"
    expect(lines[1][1]).toEqual {value: '<!--', scopes}
    expect(lines[2][1]).toEqual {value: '<!--', scopes}
    expect(lines[3][1]).toEqual {value: '<!--', scopes}

  it "tokenizes empty element meta.tag.no-content.xml", ->
    {tokens} = grammar.tokenizeLine('<n></n>')
    expected = buildTokenList """
      <      text.xml meta.tag.no-content.xml punctuation.definition.tag.xml
      n      text.xml meta.tag.no-content.xml entity.name.tag.xml entity.name.tag.localname.xml
      >      text.xml meta.tag.no-content.xml punctuation.definition.tag.xml
      </     text.xml meta.tag.no-content.xml punctuation.definition.tag.xml
      n      text.xml meta.tag.no-content.xml entity.name.tag.xml entity.name.tag.localname.xml
      >      text.xml meta.tag.no-content.xml punctuation.definition.tag.xml
    """
    expect(tokens).toEqual expected

  describe "SVG handling", ->
    it "recognises SVG tags", ->
      {tokens} = grammar.tokenizeLine "<svg><g></g></svg>"
      expected = buildTokenList """
        <      text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml
        svg    text.xml meta.svg.xml meta.tag.xml entity.name.tag.localname.xml
        >      text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml
        <      text.xml meta.svg.xml meta.tag.no-content.xml punctuation.definition.tag.xml
        g      text.xml meta.svg.xml meta.tag.no-content.xml entity.name.tag.xml entity.name.tag.localname.xml
        >      text.xml meta.svg.xml meta.tag.no-content.xml punctuation.definition.tag.xml
        </     text.xml meta.svg.xml meta.tag.no-content.xml punctuation.definition.tag.xml
        g      text.xml meta.svg.xml meta.tag.no-content.xml entity.name.tag.xml entity.name.tag.localname.xml
        >      text.xml meta.svg.xml meta.tag.no-content.xml punctuation.definition.tag.xml
        </     text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml
        svg    text.xml meta.svg.xml meta.tag.xml entity.name.tag.localname.xml
        >      text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml
      """
      expect(tokens).toEqual expected

    describe "when <script> tags are found inside SVG", ->
      it "recognises embedded JavaScript", ->
        lines = grammar.tokenizeLines """
          <svg>
            <script type="application/javascript">
              "use strict";
              document.addEventListener("DOMContentLoaded", e => {
                console.log("Ready");
              });
            </script>
          </svg>
        """
        jsScopes = "text.xml meta.svg.xml source.js.embedded.xml"
        expect(lines).toEqual expandScopes [
          [
            {value: "<",      scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
            {value: "svg",    scopes: "text.xml meta.svg.xml meta.tag.xml entity.name.tag.localname.xml"}
            {value: ">",      scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
          ]
          [
            {value: "  ",     scopes: "text.xml meta.svg.xml"}
            {value: "<",      scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
            {value: "script", scopes: "text.xml meta.svg.xml meta.tag.xml entity.name.tag.localname.xml"}
            {value: " ",      scopes: "text.xml meta.svg.xml meta.tag.xml"}
            {value: "type",   scopes: "text.xml meta.svg.xml meta.tag.xml entity.other.attribute-name.localname.xml"}
            {value: "=",      scopes: "text.xml meta.svg.xml meta.tag.xml"}
            {value: '"',      scopes: "text.xml meta.svg.xml meta.tag.xml string.quoted.double.xml punctuation.definition.string.begin.xml"}
            {value: "application/javascript", scopes: "text.xml meta.svg.xml meta.tag.xml string.quoted.double.xml"}
            {value: '"',      scopes: "text.xml meta.svg.xml meta.tag.xml string.quoted.double.xml punctuation.definition.string.end.xml"}
            {value: ">",      scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
          ]
          [ scopes: jsScopes, value: '    "use strict";']
          [ scopes: jsScopes, value: '    document.addEventListener("DOMContentLoaded", e => {']
          [ scopes: jsScopes, value: '      console.log("Ready");']
          [ scopes: jsScopes, value: '    });']
          [
            {value: "  ",     scopes: jsScopes}
            {value: "</",     scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
            {value: "script", scopes: "text.xml meta.svg.xml meta.tag.xml entity.name.tag.localname.xml"}
            {value: ">",      scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
          ]
          [
            {value: "</",     scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
            {value: "svg",    scopes: "text.xml meta.svg.xml meta.tag.xml entity.name.tag.localname.xml"}
            {value: ">",      scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
          ]
        ]

      it "doesn't highlight JavaScript in plain XML", ->
        lines = grammar.tokenizeLines """
          <not-svg>
            <script type="application/javascript">
              console.log(function(string){
                return string.toUpperCase();
              }("Shouldn't be highlighted"));
            </script>
          </not-svg>
        """
        expect(lines).toEqual expandScopes [
          [
            {value: "<",       scopes: "text.xml meta.tag.xml punctuation.definition.tag.xml"}
            {value: "not-svg", scopes: "text.xml meta.tag.xml entity.name.tag.localname.xml"}
            {value: ">",       scopes: "text.xml meta.tag.xml punctuation.definition.tag.xml"}
          ]
          [
            {value: "  ",      scopes: "text.xml"}
            {value: "<",       scopes: "text.xml meta.tag.xml punctuation.definition.tag.xml"}
            {value: "script",  scopes: "text.xml meta.tag.xml entity.name.tag.localname.xml"}
            {value: " ",       scopes: "text.xml meta.tag.xml"}
            {value: "type",    scopes: "text.xml meta.tag.xml entity.other.attribute-name.localname.xml"}
            {value: "=",       scopes: "text.xml meta.tag.xml"}
            {value: '"',       scopes: "text.xml meta.tag.xml string.quoted.double.xml punctuation.definition.string.begin.xml"}
            {value: "application/javascript", scopes: "text.xml meta.tag.xml string.quoted.double.xml"}
            {value: '"',       scopes: "text.xml meta.tag.xml string.quoted.double.xml punctuation.definition.string.end.xml"}
            {value: ">",       scopes: "text.xml meta.tag.xml punctuation.definition.tag.xml"}
          ]
          [scopes: "text.xml", value: "    console.log(function(string){"]
          [scopes: "text.xml", value: "      return string.toUpperCase();"]
          [scopes: "text.xml", value: "    }(\"Shouldn't be highlighted\"));"]
          [
            {value: "  ",      scopes: "text.xml"}
            {value: "</",      scopes: "text.xml meta.tag.xml punctuation.definition.tag.xml"}
            {value: "script",  scopes: "text.xml meta.tag.xml entity.name.tag.localname.xml"}
            {value: ">",       scopes: "text.xml meta.tag.xml punctuation.definition.tag.xml"}
          ]
          [
            {value: "</",      scopes: "text.xml meta.tag.xml punctuation.definition.tag.xml"}
            {value: "not-svg", scopes: "text.xml meta.tag.xml entity.name.tag.localname.xml"}
            {value: ">",       scopes: "text.xml meta.tag.xml punctuation.definition.tag.xml"}
          ]
        ]

      it "doesn't highlight JavaScript if <script> tags have unexpected type attributes", ->
        lines = grammar.tokenizeLines """
          <svg>
            <script type="not/javascript">
              <g>"use strict";</g>
            </script>
          </svg>
        """
        expect(lines).toEqual expandScopes [
          [
            {value: "<",      scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
            {value: "svg",    scopes: "text.xml meta.svg.xml meta.tag.xml entity.name.tag.localname.xml"}
            {value: ">",      scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
          ]
          [
            {value: "  ",     scopes: "text.xml meta.svg.xml"}
            {value: "<",      scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
            {value: "script", scopes: "text.xml meta.svg.xml meta.tag.xml entity.name.tag.localname.xml"}
            {value: " ",      scopes: "text.xml meta.svg.xml meta.tag.xml"}
            {value: "type",   scopes: "text.xml meta.svg.xml meta.tag.xml entity.other.attribute-name.localname.xml"}
            {value: "=",      scopes: "text.xml meta.svg.xml meta.tag.xml"}
            {value: "\"",     scopes: "text.xml meta.svg.xml meta.tag.xml string.quoted.double.xml punctuation.definition.string.begin.xml"}
            {value: "not/javascript", scopes: "text.xml meta.svg.xml meta.tag.xml string.quoted.double.xml"}
            {value: "\"",     scopes: "text.xml meta.svg.xml meta.tag.xml string.quoted.double.xml punctuation.definition.string.end.xml"}
            {value: ">",      scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
          ]
          [
            {value: "    ", scopes: "text.xml meta.svg.xml"}
            {value: "<",    scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
            {value: "g",    scopes: "text.xml meta.svg.xml meta.tag.xml entity.name.tag.localname.xml"}
            {value: ">",    scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
            {value: "\"use strict\";", scopes: "text.xml meta.svg.xml"}
            {value: "</",   scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
            {value: "g",    scopes: "text.xml meta.svg.xml meta.tag.xml entity.name.tag.localname.xml"}
            {value: ">",    scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
          ]
          [
            {value: "  ",   scopes: "text.xml meta.svg.xml"}
            {value: "</",   scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
            {value: "script", scopes: "text.xml meta.svg.xml meta.tag.xml entity.name.tag.localname.xml"}
            {value: ">",    scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
          ]
          [
            {value: "</",   scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
            {value: "svg",  scopes: "text.xml meta.svg.xml meta.tag.xml entity.name.tag.localname.xml"}
            {value: ">",    scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
          ]
        ]

      it "interprets <script> tags without type attributes as JavaScript", ->
        lines = grammar.tokenizeLines """
          <svg>
            <script>
              "use strict";
            </script>
          </svg>
        """
        expect(lines).toEqual expandScopes [
          [
            {value: "<",       scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
            {value: "svg",     scopes: "text.xml meta.svg.xml meta.tag.xml entity.name.tag.localname.xml"}
            {value: ">",       scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
          ]
          [
            {value: "  ",      scopes: "text.xml meta.svg.xml"}
            {value: "<",       scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
            {value: "script",  scopes: "text.xml meta.svg.xml meta.tag.xml entity.name.tag.localname.xml"}
            {value: ">",       scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
          ]
          [ value: "    \"use strict\";", scopes: "text.xml meta.svg.xml source.js.embedded.xml" ]
          [
            {value: "  ",      scopes: "text.xml meta.svg.xml source.js.embedded.xml"}
            {value: "</",      scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
            {value: "script",  scopes: "text.xml meta.svg.xml meta.tag.xml entity.name.tag.localname.xml"}
            {value: ">",       scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
          ]
          [
            {value: "</",      scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
            {value: "svg",     scopes: "text.xml meta.svg.xml meta.tag.xml entity.name.tag.localname.xml"}
            {value: ">",       scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
          ]
        ]

      it "terminates unclosed JavaScript strings before </script>", ->
        lines = grammar.tokenizeLines """
          <svg>
            <script>
              "JS</script>XML"
            </script>
          </svg>
        """
        expect(lines).toEqual expandScopes [
          [
            {value: "<",       scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
            {value: "svg",     scopes: "text.xml meta.svg.xml meta.tag.xml entity.name.tag.localname.xml"}
            {value: ">",       scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
          ]
          [
            {value: "  ",      scopes: "text.xml meta.svg.xml"}
            {value: "<",       scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
            {value: "script",  scopes: "text.xml meta.svg.xml meta.tag.xml entity.name.tag.localname.xml"}
            {value: ">",       scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
          ]
          [
            {value: "    ",    scopes: "text.xml meta.svg.xml source.js.embedded.xml"}
            {value: "\"JS",    scopes: "text.xml meta.svg.xml source.js.embedded.xml"}
            {value: "</",      scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
            {value: "script",  scopes: "text.xml meta.svg.xml meta.tag.xml entity.name.tag.localname.xml"}
            {value: ">",       scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
            {value: "XML\"",   scopes: "text.xml meta.svg.xml"}
          ]
          [
            {value: "  ",      scopes: "text.xml meta.svg.xml"}
            {value: "</",      scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
            {value: "script",  scopes: "text.xml meta.svg.xml meta.tag.xml entity.name.tag.localname.xml"}
            {value: ">",       scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
          ]
          [
            {value: "</",      scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
            {value: "svg",     scopes: "text.xml meta.svg.xml meta.tag.xml entity.name.tag.localname.xml"}
            {value: ">",       scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
          ]
        ]


    describe "when <style> tags are found inside SVG", ->
      it "recognises embedded CSS", ->
        lines = grammar.tokenizeLines """
          <svg>
            <style type="text/css">
              a { color: inherit; }
            </style>
          </svg>
        """
        cssScopes = "text.xml meta.svg.xml source.css.embedded.xml"
        expect(lines).toEqual expandScopes [
          [
            {value: "<",        scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
            {value: "svg",      scopes: "text.xml meta.svg.xml meta.tag.xml entity.name.tag.localname.xml"}
            {value: ">",        scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
          ]
          [
            {value: "  ",       scopes: "text.xml meta.svg.xml"}
            {value: "<",        scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
            {value: "style",    scopes: "text.xml meta.svg.xml meta.tag.xml entity.name.tag.localname.xml"}
            {value: " ",        scopes: "text.xml meta.svg.xml meta.tag.xml"}
            {value: "type",     scopes: "text.xml meta.svg.xml meta.tag.xml entity.other.attribute-name.localname.xml"}
            {value: "=",        scopes: "text.xml meta.svg.xml meta.tag.xml"}
            {value: '"',        scopes: "text.xml meta.svg.xml meta.tag.xml string.quoted.double.xml punctuation.definition.string.begin.xml"}
            {value: "text/css", scopes: "text.xml meta.svg.xml meta.tag.xml string.quoted.double.xml"}
            {value: '"',        scopes: "text.xml meta.svg.xml meta.tag.xml string.quoted.double.xml punctuation.definition.string.end.xml"}
            {value: ">",        scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
          ]
          [ scopes: cssScopes, value: '    a { color: inherit; }']
          [
            {value: "  ",     scopes: cssScopes}
            {value: "</",     scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
            {value: "style",  scopes: "text.xml meta.svg.xml meta.tag.xml entity.name.tag.localname.xml"}
            {value: ">",      scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
          ]
          [
            {value: "</",     scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
            {value: "svg",    scopes: "text.xml meta.svg.xml meta.tag.xml entity.name.tag.localname.xml"}
            {value: ">",      scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
          ]
        ]

      it "doesn't highlight CSS in plain XML", ->
        lines = grammar.tokenizeLines """
          <not-svg>
            <style type="text/css">
              /** No closing token… no SVG… no problem…
            </style>
          </not-svg>
        """
        expect(lines).toEqual expandScopes [
          [
            {value: "<",        scopes: "text.xml meta.tag.xml punctuation.definition.tag.xml"}
            {value: "not-svg",  scopes: "text.xml meta.tag.xml entity.name.tag.localname.xml"}
            {value: ">",        scopes: "text.xml meta.tag.xml punctuation.definition.tag.xml"}
          ]
          [
            {value: "  ",       scopes: "text.xml"}
            {value: "<",        scopes: "text.xml meta.tag.xml punctuation.definition.tag.xml"}
            {value: "style",    scopes: "text.xml meta.tag.xml entity.name.tag.localname.xml"}
            {value: " ",        scopes: "text.xml meta.tag.xml"}
            {value: "type",     scopes: "text.xml meta.tag.xml entity.other.attribute-name.localname.xml"}
            {value: "=",        scopes: "text.xml meta.tag.xml"}
            {value: '"',        scopes: "text.xml meta.tag.xml string.quoted.double.xml punctuation.definition.string.begin.xml"}
            {value: "text/css", scopes: "text.xml meta.tag.xml string.quoted.double.xml"}
            {value: '"',        scopes: "text.xml meta.tag.xml string.quoted.double.xml punctuation.definition.string.end.xml"}
            {value: ">",        scopes: "text.xml meta.tag.xml punctuation.definition.tag.xml"}
          ]
          [scopes: "text.xml", value: "    /** No closing token… no SVG… no problem…"]
          [
            {value: "  ",       scopes: "text.xml"}
            {value: "</",       scopes: "text.xml meta.tag.xml punctuation.definition.tag.xml"}
            {value: "style",    scopes: "text.xml meta.tag.xml entity.name.tag.localname.xml"}
            {value: ">",        scopes: "text.xml meta.tag.xml punctuation.definition.tag.xml"}
          ]
          [
            {value: "</",       scopes: "text.xml meta.tag.xml punctuation.definition.tag.xml"}
            {value: "not-svg",  scopes: "text.xml meta.tag.xml entity.name.tag.localname.xml"}
            {value: ">",        scopes: "text.xml meta.tag.xml punctuation.definition.tag.xml"}
          ]
        ]


      it "doesn't highlight CSS if <style> tags have unexpected type attributes", ->
        lines = grammar.tokenizeLines """
          <svg>
            <style type="not-css/wtf">
              <g>I don't know either.</g>
            </style>
          </svg>
        """
        expect(lines).toEqual expandScopes [
          [
            {value: "<",      scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
            {value: "svg",    scopes: "text.xml meta.svg.xml meta.tag.xml entity.name.tag.localname.xml"}
            {value: ">",      scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
          ]
          [
            {value: "  ",     scopes: "text.xml meta.svg.xml"}
            {value: "<",      scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
            {value: "style",  scopes: "text.xml meta.svg.xml meta.tag.xml entity.name.tag.localname.xml"}
            {value: " ",      scopes: "text.xml meta.svg.xml meta.tag.xml"}
            {value: "type",   scopes: "text.xml meta.svg.xml meta.tag.xml entity.other.attribute-name.localname.xml"}
            {value: "=",      scopes: "text.xml meta.svg.xml meta.tag.xml"}
            {value: "\"",     scopes: "text.xml meta.svg.xml meta.tag.xml string.quoted.double.xml punctuation.definition.string.begin.xml"}
            {value: "not-css/wtf", scopes: "text.xml meta.svg.xml meta.tag.xml string.quoted.double.xml"}
            {value: "\"",     scopes: "text.xml meta.svg.xml meta.tag.xml string.quoted.double.xml punctuation.definition.string.end.xml"}
            {value: ">",      scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
          ]
          [
            {value: "    ",  scopes: "text.xml meta.svg.xml"}
            {value: "<",     scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
            {value: "g",     scopes: "text.xml meta.svg.xml meta.tag.xml entity.name.tag.localname.xml"}
            {value: ">",     scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
            {value: "I don't know either.", scopes: "text.xml meta.svg.xml"}
            {value: "</",    scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
            {value: "g",     scopes: "text.xml meta.svg.xml meta.tag.xml entity.name.tag.localname.xml"}
            {value: ">",     scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
          ]
          [
            {value: "  ",    scopes: "text.xml meta.svg.xml"}
            {value: "</",    scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
            {value: "style", scopes: "text.xml meta.svg.xml meta.tag.xml entity.name.tag.localname.xml"}
            {value: ">",     scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
          ]
          [
            {value: "</",    scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
            {value: "svg",   scopes: "text.xml meta.svg.xml meta.tag.xml entity.name.tag.localname.xml"}
            {value: ">",     scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
          ]
        ]


      it "interprets <style> tags without type attributes as CSS", ->
        lines = grammar.tokenizeLines """
          <svg>
            <style>
              @media screen {}
            </style>
          </svg>
        """
        expect(lines).toEqual expandScopes [
          [
            {value: "<",       scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
            {value: "svg",     scopes: "text.xml meta.svg.xml meta.tag.xml entity.name.tag.localname.xml"}
            {value: ">",       scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
          ]
          [
            {value: "  ",      scopes: "text.xml meta.svg.xml"}
            {value: "<",       scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
            {value: "style",   scopes: "text.xml meta.svg.xml meta.tag.xml entity.name.tag.localname.xml"}
            {value: ">",       scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
          ]
          [ value: "    @media screen {}", scopes: "text.xml meta.svg.xml source.css.embedded.xml" ]
          [
            {value: "  ",      scopes: "text.xml meta.svg.xml source.css.embedded.xml"}
            {value: "</",      scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
            {value: "style",   scopes: "text.xml meta.svg.xml meta.tag.xml entity.name.tag.localname.xml"}
            {value: ">",       scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
          ]
          [
            {value: "</",      scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
            {value: "svg",     scopes: "text.xml meta.svg.xml meta.tag.xml entity.name.tag.localname.xml"}
            {value: ">",       scopes: "text.xml meta.svg.xml meta.tag.xml punctuation.definition.tag.xml"}
          ]
        ]
