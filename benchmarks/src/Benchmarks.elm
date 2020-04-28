module Benchmarks exposing (..)

import Benchmark exposing (Benchmark, describe)
import Helpers
import Markdown
import Markdown.OrderedList
import Markdown.Parser
import Parser
import Parser.Advanced as Advanced exposing ((|.), (|=), chompIf, chompUntil, chompWhile, getChompedString, map, succeed, symbol)
import Parser.Token as Token
import ThematicBreak


suite : Benchmark
suite =
    {-
    if True then
        describe "markdown parsing"
            [ heading
            , elmMarkdownExplorationsReadme
            , withHeadingsAndLists
            , withHeadingsAndListsAndHtml
            ]

    else
        succeedOrMap
    -}
    describe "" []


heading =
    "# This is a heading"
        |> compare "just a heading"


elmMarkdownExplorationsReadme =
    let
        source =
            """# elm-markdown

## Level 2 heading

### Level 3 heading

"""
    in
    source
        |> compare "elm-explorations/markdown readme"


withHeadingsAndLists =
    let
        source =
            """# elm-markdown

- Item 1 
- Item 2 
- Item 3 

## Level 2 heading

- [Google](https://google.com)
- [Bing](https://bing.com)
- [DuckDuckGo](https://duckduckgo.com)

### Level 3 heading

- Item 1
- Item 2
- Item 3
"""
    in
    source
        |> compare "withHeadingsAndLists"


withHeadingsAndListsAndHtml =
    let
        source =
            """# elm-markdown

- Item 1 
- Item 2 
- Item 3 

## Level 2 heading

<SearchEnginesBox>
- [Google](https://google.com)
- [Bing](https://bing.com)
- [DuckDuckGo](https://duckduckgo.com)
</SearchEnginesBox>

<MyCustomHtmlTag></MyCustomHtmlTag>

<Nested>
<Inner>
## This is a sub-heading

**This is bold**
</Inner>
</Nested>

### Level 3 heading

- Item 1
- Item 2
- Item 3
"""
    in
    source
        |> compare "withHeadingsAndListsAndHtml"


compare title markdown =
    Benchmark.benchmark title
        (\_ -> Markdown.Parser.parse markdown)



--Benchmark.compare "long example"
--    "elm-markdown-decoder"
--    (\_ -> Markdown.Parser.parse markdown)
--    "elm-explorations/markdown"
--    (\_ -> explorationsParse markdown)


explorationsParse =
    Markdown.toHtmlWith
        { defaultHighlighting = Just "elm"
        , githubFlavored =
            Just
                { tables = True
                , breaks = True
                }
        , sanitize = False
        , smartypants = True
        }
        []


thematicBreak =
    Benchmark.benchmark "thematic break"
        (\_ -> Advanced.run ThematicBreak.parser "_    __  ____")


orderedList =
    Benchmark.benchmark "thematic break"
        (\_ ->
            Advanced.run (Markdown.OrderedList.parser Nothing)
                """1. foo bar
            2. stuff stuff
            3. milk, eggs
            """
        )


stringBetweenChars =
    let
        withChomp =
            succeed identity
                |. chompIf (\c -> c == '<') (Parser.Expecting (String.fromChar '<'))
                |= getChompedString (chompWhile (\c -> c /= '>'))
                |. chompIf (\c -> c == '>') (Parser.Expecting (String.fromChar '>'))

        withToken =
            succeed identity
                |. symbol Token.lessThan
                |= getChompedString (chompUntil Token.greaterThan)
                |. symbol Token.greaterThan
    in
    Benchmark.compare "between chars"
        "chomp"
        (\_ -> Parser.run withChomp "<foo>")
        "symbol"
        (\_ -> Parser.run withToken "<foo>")


type BlankLine
    = BlankLine


succeedOrMap =
    describe "succeed or map"
        [ let
            withMap =
                Advanced.backtrackable (chompWhile Helpers.isSpaceOrTab)
                    |. symbol Token.newline
                    |> Advanced.map (\_ -> BlankLine)

            withSucceed =
                succeed BlankLine
                    |. Advanced.backtrackable (chompWhile Helpers.isSpaceOrTab)
                    |. symbol Token.newline
          in
          Benchmark.compare "ignore argument"
            "map"
            (\_ -> Parser.run withMap "               \n")
            "succeed"
            (\_ -> Parser.run withSucceed "               \n")
        , let
            withMap =
                getChompedString (symbol Token.newline)
                    |> Advanced.map String.reverse

            withSucceed =
                succeed String.reverse
                    |= getChompedString (symbol Token.newline)
          in
          Benchmark.compare "use argument"
            "map"
            (\_ -> Parser.run withMap "\n")
            "succeed"
            (\_ -> Parser.run withSucceed "\n")
        ]


isSpaceOrTab : Char -> Bool
isSpaceOrTab c =
    case c of
        ' ' ->
            True

        '\t' ->
            True

        _ ->
            False


spaceOrTab =
    let
        withChomp =
            chompIf isSpaceOrTab (Parser.Expecting "space or tab")

        withToken =
            Advanced.oneOf
                [ symbol Token.space
                , symbol Token.tab
                ]
    in
    Benchmark.compare "between chars"
        "chomp"
        (\_ -> Parser.run withChomp "\t")
        "token"
        (\_ -> Parser.run withToken "\t")
