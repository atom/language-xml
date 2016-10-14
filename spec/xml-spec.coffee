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

    expect(lines[1][1]).toEqual {value: '<!--', scopes: ['text.xml', 'meta.tag.sgml.doctype.xml', 'meta.internalsubset.xml', 'comment.block.xml', 'punctuation.definition.comment.xml']}
    expect(lines[2][1]).toEqual {value: '<!--', scopes: ['text.xml', 'meta.tag.sgml.doctype.xml', 'meta.internalsubset.xml', 'comment.block.xml', 'punctuation.definition.comment.xml']}
    expect(lines[3][1]).toEqual {value: '<!--', scopes: ['text.xml', 'meta.tag.sgml.doctype.xml', 'meta.internalsubset.xml', 'comment.block.xml', 'punctuation.definition.comment.xml']}

  it "tokenizes empty element meta.tag.no-content.xml", ->
    {tokens} = grammar.tokenizeLine('<n></n>')
    expect(tokens[0]).toEqual {value: '<', scopes: ['text.xml', 'meta.tag.no-content.xml', 'punctuation.definition.tag.xml']}
    expect(tokens[1]).toEqual {value: 'n', scopes: ['text.xml', 'meta.tag.no-content.xml', 'entity.name.tag.xml', 'entity.name.tag.localname.xml']}
    expect(tokens[2]).toEqual {value: '>', scopes: ['text.xml', 'meta.tag.no-content.xml', 'punctuation.definition.tag.xml']}
    expect(tokens[3]).toEqual {value: '</', scopes: ['text.xml', 'meta.tag.no-content.xml', 'punctuation.definition.tag.xml']}
    expect(tokens[4]).toEqual {value: 'n', scopes: ['text.xml', 'meta.tag.no-content.xml', 'entity.name.tag.xml', 'entity.name.tag.localname.xml']}
    expect(tokens[5]).toEqual {value: '>', scopes: ['text.xml', 'meta.tag.no-content.xml', 'punctuation.definition.tag.xml']}

  describe "SVG handling", ->
    it "recognises SVG tags", ->
      {tokens} = grammar.tokenizeLine "<svg><g></g></svg>"
      expect(tokens[0]).toEqual {value: '<', scopes: ['text.xml', 'meta.svg.xml', 'meta.tag.xml', 'punctuation.definition.tag.xml']}
      expect(tokens[1]).toEqual {value: 'svg', scopes: ['text.xml', 'meta.svg.xml', 'meta.tag.xml', 'entity.name.tag.localname.xml']}
      expect(tokens[2]).toEqual {value: '>', scopes: ['text.xml', 'meta.svg.xml', 'meta.tag.xml', 'punctuation.definition.tag.xml']}
      expect(tokens[3]).toEqual {value: '<', scopes: ['text.xml', 'meta.svg.xml', 'meta.tag.no-content.xml', 'punctuation.definition.tag.xml']}
      expect(tokens[4]).toEqual {value: 'g', scopes: ['text.xml', 'meta.svg.xml', 'meta.tag.no-content.xml', 'entity.name.tag.xml', 'entity.name.tag.localname.xml']}
      expect(tokens[5]).toEqual {value: '>', scopes: ['text.xml', 'meta.svg.xml', 'meta.tag.no-content.xml', 'punctuation.definition.tag.xml']}
      expect(tokens[6]).toEqual {value: '</', scopes: ['text.xml', 'meta.svg.xml', 'meta.tag.no-content.xml', 'punctuation.definition.tag.xml']}
      expect(tokens[7]).toEqual {value: 'g', scopes: ['text.xml', 'meta.svg.xml', 'meta.tag.no-content.xml', 'entity.name.tag.xml', 'entity.name.tag.localname.xml']}
      expect(tokens[8]).toEqual {value: '>', scopes: ['text.xml', 'meta.svg.xml', 'meta.tag.no-content.xml', 'punctuation.definition.tag.xml']}
      expect(tokens[9]).toEqual {value: '</', scopes: ['text.xml', 'meta.svg.xml', 'meta.tag.xml', 'punctuation.definition.tag.xml']}
      expect(tokens[10]).toEqual {value: 'svg', scopes: ['text.xml', 'meta.svg.xml', 'meta.tag.xml', 'entity.name.tag.localname.xml']}
      expect(tokens[11]).toEqual {value: '>', scopes: ['text.xml', 'meta.svg.xml', 'meta.tag.xml', 'punctuation.definition.tag.xml']}

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
        expect(lines[0][0]).toEqual {value: "<", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[0][1]).toEqual {value: "svg", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "entity.name.tag.localname.xml"]}
        expect(lines[0][2]).toEqual {value: ">", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[1][0]).toEqual {value: "  ", scopes: ["text.xml", "meta.svg.xml"]}
        expect(lines[1][1]).toEqual {value: "<", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[1][2]).toEqual {value: "script", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "entity.name.tag.localname.xml"]}
        expect(lines[1][3]).toEqual {value: " ", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml"]}
        expect(lines[1][4]).toEqual {value: "type", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "entity.other.attribute-name.localname.xml"]}
        expect(lines[1][5]).toEqual {value: "=", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml"]}
        expect(lines[1][6]).toEqual {value: '"', scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "string.quoted.double.xml", "punctuation.definition.string.begin.xml"]}
        expect(lines[1][7]).toEqual {value: "application/javascript", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "string.quoted.double.xml"]}
        expect(lines[1][8]).toEqual {value: '"', scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "string.quoted.double.xml", "punctuation.definition.string.end.xml"]}
        expect(lines[1][9]).toEqual {value: ">", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[2][0]).toEqual {value: '    "use strict";', scopes: ["text.xml", "meta.svg.xml", "source.js.embedded.xml"]}
        expect(lines[3][0]).toEqual {value: '    document.addEventListener("DOMContentLoaded", e => {', scopes: ["text.xml", "meta.svg.xml", "source.js.embedded.xml"]}
        expect(lines[4][0]).toEqual {value: '      console.log("Ready");', scopes: ["text.xml", "meta.svg.xml", "source.js.embedded.xml"]}
        expect(lines[5][0]).toEqual {value: '    });', scopes: ["text.xml", "meta.svg.xml", "source.js.embedded.xml"]}
        expect(lines[6][0]).toEqual {value: "  ", scopes: ["text.xml", "meta.svg.xml", "source.js.embedded.xml"]}
        expect(lines[6][1]).toEqual {value: "</", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[6][2]).toEqual {value: "script", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "entity.name.tag.localname.xml"]}
        expect(lines[6][3]).toEqual {value: ">", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[7][0]).toEqual {value: "</", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[7][1]).toEqual {value: "svg", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "entity.name.tag.localname.xml"]}
        expect(lines[7][2]).toEqual {value: ">", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}

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
        expect(lines[0][0]).toEqual {value: "<", scopes: ["text.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[0][1]).toEqual {value: "not-svg", scopes: ["text.xml", "meta.tag.xml", "entity.name.tag.localname.xml"]}
        expect(lines[0][2]).toEqual {value: ">", scopes: ["text.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[1][0]).toEqual {value: "  ", scopes: ["text.xml"]}
        expect(lines[1][1]).toEqual {value: "<", scopes: ["text.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[1][2]).toEqual {value: "script", scopes: ["text.xml", "meta.tag.xml", "entity.name.tag.localname.xml"]}
        expect(lines[1][3]).toEqual {value: " ", scopes: ["text.xml", "meta.tag.xml"]}
        expect(lines[1][4]).toEqual {value: "type", scopes: ["text.xml", "meta.tag.xml", "entity.other.attribute-name.localname.xml"]}
        expect(lines[1][5]).toEqual {value: "=", scopes: ["text.xml", "meta.tag.xml"]}
        expect(lines[1][6]).toEqual {value: '"', scopes: ["text.xml", "meta.tag.xml", "string.quoted.double.xml", "punctuation.definition.string.begin.xml"]}
        expect(lines[1][7]).toEqual {value: "application/javascript", scopes: ["text.xml", "meta.tag.xml", "string.quoted.double.xml"]}
        expect(lines[1][8]).toEqual {value: '"', scopes: ["text.xml", "meta.tag.xml", "string.quoted.double.xml", "punctuation.definition.string.end.xml"]}
        expect(lines[1][9]).toEqual {value: ">", scopes: ["text.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[2][0]).toEqual {value: "    console.log(function(string){", scopes: ["text.xml"]}
        expect(lines[3][0]).toEqual {value: "      return string.toUpperCase();", scopes: ["text.xml"]}
        expect(lines[4][0]).toEqual {value: "    }(\"Shouldn't be highlighted\"));", scopes: ["text.xml"]}
        expect(lines[5][0]).toEqual {value: "  ", scopes: ["text.xml"]}
        expect(lines[5][1]).toEqual {value: "</", scopes: ["text.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[5][2]).toEqual {value: "script", scopes: ["text.xml", "meta.tag.xml", "entity.name.tag.localname.xml"]}
        expect(lines[5][3]).toEqual {value: ">", scopes: ["text.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[6][0]).toEqual {value: "</", scopes: ["text.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[6][1]).toEqual {value: "not-svg", scopes: ["text.xml", "meta.tag.xml", "entity.name.tag.localname.xml"]}
        expect(lines[6][2]).toEqual {value: ">", scopes: ["text.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}

      it "doesn't highlight JavaScript if <script> tags have unexpected type attributes", ->
        lines = grammar.tokenizeLines """
          <svg>
            <script type="not/javascript">
              <g>"use strict";</g>
            </script>
          </svg>
        """
        expect(lines[0][0]).toEqual {value: "<", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[0][1]).toEqual {value: "svg", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "entity.name.tag.localname.xml"]}
        expect(lines[0][2]).toEqual {value: ">", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[1][0]).toEqual {value: "  ", scopes: ["text.xml", "meta.svg.xml"]}
        expect(lines[1][1]).toEqual {value: "<", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[1][2]).toEqual {value: "script", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "entity.name.tag.localname.xml"]}
        expect(lines[1][3]).toEqual {value: " ", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml"]}
        expect(lines[1][4]).toEqual {value: "type", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "entity.other.attribute-name.localname.xml"]}
        expect(lines[1][5]).toEqual {value: "=", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml"]}
        expect(lines[1][6]).toEqual {value: "\"", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "string.quoted.double.xml", "punctuation.definition.string.begin.xml"]}
        expect(lines[1][7]).toEqual {value: "not/javascript", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "string.quoted.double.xml"]}
        expect(lines[1][8]).toEqual {value: "\"", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "string.quoted.double.xml", "punctuation.definition.string.end.xml"]}
        expect(lines[1][9]).toEqual {value: ">", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[2][0]).toEqual {value: "    ", scopes: ["text.xml", "meta.svg.xml"]}
        expect(lines[2][1]).toEqual {value: "<", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[2][2]).toEqual {value: "g", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "entity.name.tag.localname.xml"]}
        expect(lines[2][3]).toEqual {value: ">", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[2][4]).toEqual {value: "\"use strict\";", scopes: ["text.xml", "meta.svg.xml"]}
        expect(lines[2][5]).toEqual {value: "</", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[2][6]).toEqual {value: "g", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "entity.name.tag.localname.xml"]}
        expect(lines[2][7]).toEqual {value: ">", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[3][0]).toEqual {value: "  ", scopes: ["text.xml", "meta.svg.xml"]}
        expect(lines[3][1]).toEqual {value: "</", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[3][2]).toEqual {value: "script", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "entity.name.tag.localname.xml"]}
        expect(lines[3][3]).toEqual {value: ">", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[4][0]).toEqual {value: "</", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[4][1]).toEqual {value: "svg", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "entity.name.tag.localname.xml"]}
        expect(lines[4][2]).toEqual {value: ">", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}

      it "interprets <script> tags without type attributes as JavaScript", ->
        lines = grammar.tokenizeLines """
          <svg>
            <script>
              "use strict";
            </script>
          </svg>
        """
        expect(lines[0][0]).toEqual {value: "<", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[0][1]).toEqual {value: "svg", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "entity.name.tag.localname.xml"]}
        expect(lines[0][2]).toEqual {value: ">", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[1][0]).toEqual {value: "  ", scopes: ["text.xml", "meta.svg.xml"]}
        expect(lines[1][1]).toEqual {value: "<", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[1][2]).toEqual {value: "script", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "entity.name.tag.localname.xml"]}
        expect(lines[1][3]).toEqual {value: ">", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[2][0]).toEqual {value: "    \"use strict\";", scopes: ["text.xml", "meta.svg.xml", "source.js.embedded.xml"]}
        expect(lines[3][0]).toEqual {value: "  ", scopes: ["text.xml", "meta.svg.xml", "source.js.embedded.xml"]}
        expect(lines[3][1]).toEqual {value: "</", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[3][2]).toEqual {value: "script", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "entity.name.tag.localname.xml"]}
        expect(lines[3][3]).toEqual {value: ">", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[4][0]).toEqual {value: "</", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[4][1]).toEqual {value: "svg", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "entity.name.tag.localname.xml"]}
        expect(lines[4][2]).toEqual {value: ">", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}

      it "terminates unclosed JavaScript strings before </script>", ->
        lines = grammar.tokenizeLines """
          <svg>
            <script>
              "JS</script>XML"
            </script>
          </svg>
        """
        expect(lines[0][0]).toEqual {value: "<", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[0][1]).toEqual {value: "svg", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "entity.name.tag.localname.xml"]}
        expect(lines[0][2]).toEqual {value: ">", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[1][0]).toEqual {value: "  ", scopes: ["text.xml", "meta.svg.xml"]}
        expect(lines[1][1]).toEqual {value: "<", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[1][2]).toEqual {value: "script", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "entity.name.tag.localname.xml"]}
        expect(lines[1][3]).toEqual {value: ">", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[2][0]).toEqual {value: "    ", scopes: ["text.xml", "meta.svg.xml", "source.js.embedded.xml"]}
        expect(lines[2][1]).toEqual {value: "\"JS", scopes: ["text.xml", "meta.svg.xml", "source.js.embedded.xml"]}
        expect(lines[2][2]).toEqual {value: "</", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[2][3]).toEqual {value: "script", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "entity.name.tag.localname.xml"]}
        expect(lines[2][4]).toEqual {value: ">", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[2][5]).toEqual {value: "XML\"", scopes: ["text.xml", "meta.svg.xml"]}
        expect(lines[3][0]).toEqual {value: "  ", scopes: ["text.xml", "meta.svg.xml"]}
        expect(lines[3][1]).toEqual {value: "</", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[3][2]).toEqual {value: "script", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "entity.name.tag.localname.xml"]}
        expect(lines[3][3]).toEqual {value: ">", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[4][0]).toEqual {value: "</", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[4][1]).toEqual {value: "svg", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "entity.name.tag.localname.xml"]}
        expect(lines[4][2]).toEqual {value: ">", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}


    describe "when <style> tags are found inside SVG", ->
      it "recognises embedded CSS", ->
        lines = grammar.tokenizeLines """
          <svg>
            <style type="text/css">
              a { color: inherit; }
            </style>
          </svg>
        """
        expect(lines[0][0]).toEqual {value: "<", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[0][1]).toEqual {value: "svg", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "entity.name.tag.localname.xml"]}
        expect(lines[0][2]).toEqual {value: ">", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[1][0]).toEqual {value: "  ", scopes: ["text.xml", "meta.svg.xml"]}
        expect(lines[1][1]).toEqual {value: "<", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[1][2]).toEqual {value: "style", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "entity.name.tag.localname.xml"]}
        expect(lines[1][3]).toEqual {value: " ", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml"]}
        expect(lines[1][4]).toEqual {value: "type", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "entity.other.attribute-name.localname.xml"]}
        expect(lines[1][5]).toEqual {value: "=", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml"]}
        expect(lines[1][6]).toEqual {value: '"', scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "string.quoted.double.xml", "punctuation.definition.string.begin.xml"]}
        expect(lines[1][7]).toEqual {value: "text/css", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "string.quoted.double.xml"]}
        expect(lines[1][8]).toEqual {value: '"', scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "string.quoted.double.xml", "punctuation.definition.string.end.xml"]}
        expect(lines[1][9]).toEqual {value: ">", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[2][0]).toEqual {value: '    a { color: inherit; }', scopes: ["text.xml", "meta.svg.xml", "source.css.embedded.xml"]}
        expect(lines[3][0]).toEqual {value: "  ", scopes: ["text.xml", "meta.svg.xml", "source.css.embedded.xml"]}
        expect(lines[3][1]).toEqual {value: "</", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[3][2]).toEqual {value: "style", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "entity.name.tag.localname.xml"]}
        expect(lines[3][3]).toEqual {value: ">", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[4][0]).toEqual {value: "</", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[4][1]).toEqual {value: "svg", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "entity.name.tag.localname.xml"]}
        expect(lines[4][2]).toEqual {value: ">", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}

      it "doesn't highlight CSS in plain XML", ->
        lines = grammar.tokenizeLines """
          <not-svg>
            <style type="text/css">
              /** No closing token… no SVG… no problem…
            </style>
          </not-svg>
        """
        expect(lines[0][0]).toEqual {value: "<", scopes: ["text.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[0][1]).toEqual {value: "not-svg", scopes: ["text.xml", "meta.tag.xml", "entity.name.tag.localname.xml"]}
        expect(lines[0][2]).toEqual {value: ">", scopes: ["text.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[1][0]).toEqual {value: "  ", scopes: ["text.xml"]}
        expect(lines[1][1]).toEqual {value: "<", scopes: ["text.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[1][2]).toEqual {value: "style", scopes: ["text.xml", "meta.tag.xml", "entity.name.tag.localname.xml"]}
        expect(lines[1][3]).toEqual {value: " ", scopes: ["text.xml", "meta.tag.xml"]}
        expect(lines[1][4]).toEqual {value: "type", scopes: ["text.xml", "meta.tag.xml", "entity.other.attribute-name.localname.xml"]}
        expect(lines[1][5]).toEqual {value: "=", scopes: ["text.xml", "meta.tag.xml"]}
        expect(lines[1][6]).toEqual {value: '"', scopes: ["text.xml", "meta.tag.xml", "string.quoted.double.xml", "punctuation.definition.string.begin.xml"]}
        expect(lines[1][7]).toEqual {value: "text/css", scopes: ["text.xml", "meta.tag.xml", "string.quoted.double.xml"]}
        expect(lines[1][8]).toEqual {value: '"', scopes: ["text.xml", "meta.tag.xml", "string.quoted.double.xml", "punctuation.definition.string.end.xml"]}
        expect(lines[1][9]).toEqual {value: ">", scopes: ["text.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[2][0]).toEqual {value: "    /** No closing token… no SVG… no problem…", scopes: ["text.xml"]}
        expect(lines[3][0]).toEqual {value: "  ", scopes: ["text.xml"]}
        expect(lines[3][1]).toEqual {value: "</", scopes: ["text.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[3][2]).toEqual {value: "style", scopes: ["text.xml", "meta.tag.xml", "entity.name.tag.localname.xml"]}
        expect(lines[3][3]).toEqual {value: ">", scopes: ["text.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[4][0]).toEqual {value: "</", scopes: ["text.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[4][1]).toEqual {value: "not-svg", scopes: ["text.xml", "meta.tag.xml", "entity.name.tag.localname.xml"]}
        expect(lines[4][2]).toEqual {value: ">", scopes: ["text.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}


      it "doesn't highlight CSS if <style> tags have unexpected type attributes", ->
        lines = grammar.tokenizeLines """
          <svg>
            <style type="not-css/wtf">
              <g>I don't know either.</g>
            </style>
          </svg>
        """
        expect(lines[0][0]).toEqual {value: "<", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[0][1]).toEqual {value: "svg", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "entity.name.tag.localname.xml"]}
        expect(lines[0][2]).toEqual {value: ">", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[1][0]).toEqual {value: "  ", scopes: ["text.xml", "meta.svg.xml"]}
        expect(lines[1][1]).toEqual {value: "<", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[1][2]).toEqual {value: "style", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "entity.name.tag.localname.xml"]}
        expect(lines[1][3]).toEqual {value: " ", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml"]}
        expect(lines[1][4]).toEqual {value: "type", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "entity.other.attribute-name.localname.xml"]}
        expect(lines[1][5]).toEqual {value: "=", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml"]}
        expect(lines[1][6]).toEqual {value: "\"", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "string.quoted.double.xml", "punctuation.definition.string.begin.xml"]}
        expect(lines[1][7]).toEqual {value: "not-css/wtf", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "string.quoted.double.xml"]}
        expect(lines[1][8]).toEqual {value: "\"", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "string.quoted.double.xml", "punctuation.definition.string.end.xml"]}
        expect(lines[1][9]).toEqual {value: ">", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[2][0]).toEqual {value: "    ", scopes: ["text.xml", "meta.svg.xml"]}
        expect(lines[2][1]).toEqual {value: "<", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[2][2]).toEqual {value: "g", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "entity.name.tag.localname.xml"]}
        expect(lines[2][3]).toEqual {value: ">", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[2][4]).toEqual {value: "I don't know either.", scopes: ["text.xml", "meta.svg.xml"]}
        expect(lines[2][5]).toEqual {value: "</", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[2][6]).toEqual {value: "g", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "entity.name.tag.localname.xml"]}
        expect(lines[2][7]).toEqual {value: ">", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[3][0]).toEqual {value: "  ", scopes: ["text.xml", "meta.svg.xml"]}
        expect(lines[3][1]).toEqual {value: "</", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[3][2]).toEqual {value: "style", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "entity.name.tag.localname.xml"]}
        expect(lines[3][3]).toEqual {value: ">", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[4][0]).toEqual {value: "</", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[4][1]).toEqual {value: "svg", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "entity.name.tag.localname.xml"]}
        expect(lines[4][2]).toEqual {value: ">", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}


      it "interprets <style> tags without type attributes as CSS", ->
        lines = grammar.tokenizeLines """
          <svg>
            <style>
              @media screen {}
            </style>
          </svg>
        """
        expect(lines[0][0]).toEqual {value: "<", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[0][1]).toEqual {value: "svg", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "entity.name.tag.localname.xml"]}
        expect(lines[0][2]).toEqual {value: ">", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[1][0]).toEqual {value: "  ", scopes: ["text.xml", "meta.svg.xml"]}
        expect(lines[1][1]).toEqual {value: "<", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[1][2]).toEqual {value: "style", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "entity.name.tag.localname.xml"]}
        expect(lines[1][3]).toEqual {value: ">", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[2][0]).toEqual {value: "    @media screen {}", scopes: ["text.xml", "meta.svg.xml", "source.css.embedded.xml"]}
        expect(lines[3][0]).toEqual {value: "  ", scopes: ["text.xml", "meta.svg.xml", "source.css.embedded.xml"]}
        expect(lines[3][1]).toEqual {value: "</", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[3][2]).toEqual {value: "style", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "entity.name.tag.localname.xml"]}
        expect(lines[3][3]).toEqual {value: ">", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[4][0]).toEqual {value: "</", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}
        expect(lines[4][1]).toEqual {value: "svg", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "entity.name.tag.localname.xml"]}
        expect(lines[4][2]).toEqual {value: ">", scopes: ["text.xml", "meta.svg.xml", "meta.tag.xml", "punctuation.definition.tag.xml"]}

  it "tokenizes attribute-name of multi-line tag", ->
    linesWithIndent = grammar.tokenizeLines """
      <el
        attrName="attrValue">
      </el>
    """
    expect(linesWithIndent[1][1]).toEqual value: 'attrName', scopes: ['text.xml', 'meta.tag.xml', 'entity.other.attribute-name.localname.xml']
    
    linesWithoutIndent = grammar.tokenizeLines """
      <el
attrName="attrValue">
      </el>
    """
    expect(linesWithoutIndent[1][0]).toEqual value: 'attrName', scopes: ['text.xml', 'meta.tag.xml', 'entity.other.attribute-name.localname.xml']

  it "tokenizes attribute-name.namespace contains period", ->
    lines = grammar.tokenizeLines """
      <el name.space:attrName="attrValue">
      </el>
    """
    expect(lines[0][3]).toEqual value: 'name.space', scopes: ['text.xml', 'meta.tag.xml', 'entity.other.attribute-name.namespace.xml']

  it "tokenizes attribute-name.namespace contains East-Asian Kanji", ->
    lines = grammar.tokenizeLines """
      <el 名前空間名:attrName="attrValue">
      </el>
    """
    expect(lines[0][3]).toEqual value: '名前空間名', scopes: ['text.xml', 'meta.tag.xml', 'entity.other.attribute-name.namespace.xml']

  it "tokenizes attribute-name.localname contains period", ->
    lines = grammar.tokenizeLines """
      <el attr.name="attrValue">
      </el>
    """
    expect(lines[0][3]).toEqual value: 'attr.name', scopes: ['text.xml', 'meta.tag.xml', 'entity.other.attribute-name.localname.xml']

  it "tokenizes attribute-name.localname contains colon", ->
    lines = grammar.tokenizeLines """
      <el namespace:attr:name="attrValue">
      </el>
    """
    expect(lines[0][5]).toEqual value: 'attr:name', scopes: ['text.xml', 'meta.tag.xml', 'entity.other.attribute-name.localname.xml']

  it "tokenizes attribute-name.localname contains East-Asian Kanji", ->
    lines = grammar.tokenizeLines """
      <el 属性名="attrValue">
      </el>
    """
    expect(lines[0][3]).toEqual value: '属性名', scopes: ['text.xml', 'meta.tag.xml', 'entity.other.attribute-name.localname.xml']
