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

  it 'tokenizes comment endings with more than two dashes as invalid', ->
    {tokens} = grammar.tokenizeLine('<!-- invalid comment --->')
    expect(tokens[0]).toEqual value: '<!--', scopes: ['text.xml', 'comment.block.xml', 'punctuation.definition.comment.xml']
    expect(tokens[1]).toEqual value: ' invalid comment ', scopes: ['text.xml', 'comment.block.xml']
    expect(tokens[2]).toEqual value: '--', scopes: ['text.xml', 'comment.block.xml', 'invalid.illegal.bad-comments-or-CDATA.xml']
    expect(tokens[3]).toEqual value: '->', scopes: ['text.xml', 'comment.block.xml', 'invalid.illegal.bad-comments-or-CDATA.xml']

  it 'tokenizes comments with two dashes not followed by ">" as invalid', ->
    {tokens} = grammar.tokenizeLine('<!-- invalid -- comment -->')
    expect(tokens[0]).toEqual value: '<!--', scopes: ['text.xml', 'comment.block.xml', 'punctuation.definition.comment.xml']
    expect(tokens[1]).toEqual value: ' invalid ', scopes: ['text.xml', 'comment.block.xml']
    expect(tokens[2]).toEqual value: '--', scopes: ['text.xml', 'comment.block.xml', 'invalid.illegal.bad-comments-or-CDATA.xml']
    expect(tokens[3]).toEqual value: ' comment ', scopes: ['text.xml', 'comment.block.xml', 'invalid.illegal.bad-comments-or-CDATA.xml']
    expect(tokens[4]).toEqual value: '-->', scopes: ['text.xml', 'comment.block.xml', 'punctuation.definition.comment.xml']

  it 'tokenizes after invalid comment only if comment was properly closed', ->
    {tokens} = grammar.tokenizeLine('<!-- invalid -- comment ---><n></n>--><n></n>')
    expect(tokens[0]).toEqual value: '<!--', scopes: ['text.xml', 'comment.block.xml', 'punctuation.definition.comment.xml']
    expect(tokens[1]).toEqual value: ' invalid ', scopes: ['text.xml', 'comment.block.xml']
    expect(tokens[2]).toEqual value: '--', scopes: ['text.xml', 'comment.block.xml', 'invalid.illegal.bad-comments-or-CDATA.xml']
    expect(tokens[3]).toEqual value: ' comment ', scopes: ['text.xml', 'comment.block.xml', 'invalid.illegal.bad-comments-or-CDATA.xml']
    expect(tokens[4]).toEqual value: '--', scopes: ['text.xml', 'comment.block.xml', 'invalid.illegal.bad-comments-or-CDATA.xml']
    expect(tokens[5]).toEqual value: '-><n></n>', scopes: ['text.xml', 'comment.block.xml', 'punctuation.definition.comment.xml']
    expect(tokens[6]).toEqual value: '-->', scopes: ['text.xml', 'comment.block.xml', 'punctuation.definition.comment.xml']
    expect(tokens[7]).toEqual value: '<',   scopes: ['text.xml', 'meta.tag.no-content.xml', 'punctuation.definition.tag.xml']
    expect(tokens[8]).toEqual value: 'n',   scopes: ['text.xml', 'meta.tag.no-content.xml', 'entity.name.tag.xml', 'entity.name.tag.localname.xml']
    expect(tokens[9]).toEqual value: '>',   scopes: ['text.xml', 'meta.tag.no-content.xml', 'punctuation.definition.tag.xml']
    expect(tokens[10]).toEqual value: '</', scopes: ['text.xml', 'meta.tag.no-content.xml', 'punctuation.definition.tag.xml']
    expect(tokens[11]).toEqual value: 'n',  scopes: ['text.xml', 'meta.tag.no-content.xml', 'entity.name.tag.xml', 'entity.name.tag.localname.xml']
    expect(tokens[12]).toEqual value: '>',  scopes: ['text.xml', 'meta.tag.no-content.xml', 'punctuation.definition.tag.xml']

  it "tokenizes empty element meta.tag.no-content.xml", ->
    {tokens} = grammar.tokenizeLine('<n></n>')
    expect(tokens[0]).toEqual value: '<',   scopes: ['text.xml', 'meta.tag.no-content.xml', 'punctuation.definition.tag.xml']
    expect(tokens[1]).toEqual value: 'n',   scopes: ['text.xml', 'meta.tag.no-content.xml', 'entity.name.tag.xml', 'entity.name.tag.localname.xml']
    expect(tokens[2]).toEqual value: '>',   scopes: ['text.xml', 'meta.tag.no-content.xml', 'punctuation.definition.tag.xml']
    expect(tokens[3]).toEqual value: '</',  scopes: ['text.xml', 'meta.tag.no-content.xml', 'punctuation.definition.tag.xml']
    expect(tokens[4]).toEqual value: 'n',   scopes: ['text.xml', 'meta.tag.no-content.xml', 'entity.name.tag.xml', 'entity.name.tag.localname.xml']
    expect(tokens[5]).toEqual value: '>',   scopes: ['text.xml', 'meta.tag.no-content.xml', 'punctuation.definition.tag.xml']

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

  it "tokenizes attribute-name.localname when followed by spaces", ->
    lines = grammar.tokenizeLines """
      <el attrName     ="attrValue">
      </el>
    """
    expect(lines[0][3]).toEqual value: 'attrName', scopes: ['text.xml', 'meta.tag.xml', 'entity.other.attribute-name.localname.xml']

  describe "firstLineMatch", ->
    it "recognises Emacs modelines", ->
      valid = """
        #-*-xml-*-
        #-*-mode:xml-*-
        /* -*-xml-*- */
        // -*- XML -*-
        /* -*- mode:xml -*- */
        // -*- font:bar;mode:XML -*-
        // -*- font:bar;mode:XMl;foo:bar; -*-
        // -*-font:mode;mode:XML-*-
        // -*- foo:bar mode: xml bar:baz -*-
        " -*-foo:bar;mode:xML;bar:foo-*- ";
        " -*-font-mode:foo;mode:XML;foo-bar:quux-*-"
        "-*-font:x;foo:bar; mode : xml;bar:foo;foooooo:baaaaar;fo:ba;-*-";
        "-*- font:x;foo : bar ; mode : xMl ; bar : foo ; foooooo:baaaaar;fo:ba-*-";
      """
      for line in valid.split /\n/
        expect(grammar.firstLineRegex.scanner.findNextMatchSync(line)).not.toBeNull()

      invalid = """
        /* --*XML-*- */
        /* -*-- XML -*-
        /* -*- -- XML -*-
        /* -*- HXML -;- -*-
        // -*- iXML -*-
        // -*- XML; -*-
        // -*- xml-stuff -*-
        /* -*- model:xml -*-
        /* -*- indent-mode:xml -*-
        // -*- font:mode;xml -*-
        // -*- mode: -*- XML
        // -*- mode: grok-with-xml -*-
        // -*-font:mode;mode:xml--*-
      """
      for line in invalid.split /\n/
        expect(grammar.firstLineRegex.scanner.findNextMatchSync(line)).toBeNull()

    it "recognises Vim modelines", ->
      valid = """
        vim: se filetype=xml:
        # vim: se ft=xml:
        # vim: set ft=xml:
        # vim: set filetype=XML:
        # vim: ft=xml
        # vim: syntax=xML
        # vim: se syntax=XML:
        # ex: syntax=xml
        # vim:ft=xml
        # vim600: ft=xml
        # vim>600: set ft=xml:
        # vi:noai:sw=3 ts=6 ft=xml
        # vi::::::::::noai:::::::::::: ft=xml
        # vim:ts=4:sts=4:sw=4:noexpandtab:ft=xml
        # vi:: noai : : : : sw   =3 ts   =6 ft  =xml
        # vim: ts=4: pi sts=4: ft=xml: noexpandtab: sw=4:
        # vim: ts=4 sts=4: ft=xml noexpandtab:
        # vim:noexpandtab sts=4 ft=xml ts=4
        # vim:noexpandtab:ft=xml
        # vim:ts=4:sts=4 ft=xml:noexpandtab:\x20
        # vim:noexpandtab titlestring=hi\|there\\\\ ft=xml ts=4
      """
      for line in valid.split /\n/
        expect(grammar.firstLineRegex.scanner.findNextMatchSync(line)).not.toBeNull()

      invalid = """
        ex: se filetype=xml:
        _vi: se filetype=xml:
         vi: se filetype=xml
        # vim set ft=xmlz
        # vim: soft=xml
        # vim: hairy-syntax=xml:
        # vim set ft=xml:
        # vim: setft=xml:
        # vim: se ft=xml backupdir=tmp
        # vim: set ft=xml set cmdheight=1
        # vim:noexpandtab sts:4 ft:xml ts:4
        # vim:noexpandtab titlestring=hi\\|there\\ ft=xml ts=4
        # vim:noexpandtab titlestring=hi\\|there\\\\\\ ft=xml ts=4
      """
      for line in invalid.split /\n/
        expect(grammar.firstLineRegex.scanner.findNextMatchSync(line)).toBeNull()

    it "recognises a valid XML declaration", ->
      valid = """
        <?xml version="1.0"?>
        <?xml version="1.0" encoding="UTF-8"?>
        <?xml version="1.1" standalone="yes" ?>
        <?xml version = '1.0' ?>
        <?xml version="1.0" encoding='UTF-8' standalone='no' ?>
      """
      for line in valid.split /\n/
        expect(grammar.firstLineRegex.scanner.findNextMatchSync(line)).not.toBeNull()

      invalid = """
        <?XML version="1.0"?>
        <?xml version="1.0'?>
        <?xml version='1.0"?>
        <?xml version="2.0"?>
        <?xml encoding="UTF-8" version="1.0" ?>
        <?xml version="1.0" standalone="nah" ?>
        <?xml version=1.0 ?>
        <?xml version="1.0">
      """
      for line in invalid.split /\n/
        expect(grammar.firstLineRegex.scanner.findNextMatchSync(line)).toBeNull()
