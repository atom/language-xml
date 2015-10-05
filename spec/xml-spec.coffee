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

    expect(lines[1][1]).toEqual value: '<!--', scopes: ['text.xml', 'meta.tag.sgml.doctype.xml', 'meta.internalsubset.xml', 'comment.block.xml', 'punctuation.definition.comment.xml']
    expect(lines[2][1]).toEqual value: '<!--', scopes: ['text.xml', 'meta.tag.sgml.doctype.xml', 'meta.internalsubset.xml', 'comment.block.xml', 'punctuation.definition.comment.xml']
    expect(lines[3][1]).toEqual value: '<!--', scopes: ['text.xml', 'meta.tag.sgml.doctype.xml', 'meta.internalsubset.xml', 'comment.block.xml', 'punctuation.definition.comment.xml']
