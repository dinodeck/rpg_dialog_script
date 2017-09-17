#!/opt/local/bin/lua

require("PrintTable")
require("ParseCore")
require("TestHelper")

tests =
{
    {
        name = "Empty string gives empty syntax tree",
        test = function()
            local testTable = {}
            return AreTablesEqual(DoParse(""), testTable)
        end
    },
    {
        name = "Empty line gives empty syntax tree",
        test = function()
            local testTable = {}
            return AreTablesEqual(DoParse("\n"), testTable)
        end
    },
    {
         name = "Speaker with no text gives error.",
         test = function()
             local tree, result = DoParse("null:")
             return result.isError == true
         end
    },
    {
         name = "Speaker with name and line creates syntax tree representation.",
         test = function()
            local testTable = {{speaker = "null", text = {"Hello"} }}
            local parsedTable = DoParse("null:Hello")
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
         end
    },
    {
        name = "Speaker name may not have space between name and colon",
        test = function()
            local tree, result = DoParse("null :Hello")
            return result.isError == true
        end,
    },
    {
        name = "Speaker name may not have tab between name and colon",
        test = function()
            local tree, result = DoParse("null\t:Hello")
            return result.isError == true
        end,
    },
    {
        name = "Speaker name may not contain newline",
        test = function()
            local tree, result = DoParse("nu\nll:Hello")
            return result.isError == true
        end,
    },
    {
        name = "Speech may contain colon",
        test = function()
            local testTable = {{speaker = "null", text = {"Hello Altar: Destroyer of Worlds."} }}
            local parsedTable = DoParse("null:Hello Altar: Destroyer of Worlds.")
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end,
    },
    {
        name = "Speech needs a speaker",
        test = function()
            local tree, result = DoParse("Hello")
            return result.isError == true
        end
    },
    {
        name = "Speaker mame may contain space",
        test = function()
            local testTable = {{speaker = "Mr null", text = {"Hello"} }}
            local parsedTable = DoParse("Mr null:Hello")
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "Ignore leading newline in speech",
        test = function()
            local testTable = {{speaker = "null", text = {"Hello"} }}
            local parsedTable = DoParse("null:\nHello")
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "Ignore leading whitespace in speech",
        test = function()
            local testTable = {{speaker = "null", text = {"Hello"} }}
            local parsedTable = DoParse("null: Hello")
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "Single line breaks are preserved.",
        test = function()
            local testTable = {{speaker = "null", text = {"It was really dark\nthat's why we didn't see him."} }}
            local parsedTable = DoParse("null:It was really dark\nthat's why we didn't see him.")
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "Extra space after speech line break is ignored",
        test = function()
            local testTable = {{speaker = "null", text = {"It was really dark\nthat's why we didn't see him."} }}
            local parsedTable = DoParse("null:It was really dark \n that's why we didn't see him.")
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "Trailing newlines are removed",
        test = function()
            local testTable = {{speaker = "null", text = {"Hello", "Goodbye"} }}
            local parsedTable = DoParse("null:Hello\n\nGoodbye\n\n\n")
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "A script can have multiple speakers",
        test = function()
            local testTable = {{speaker = "null", text = {"Hello"} }, {speaker = "bob", text = {"Hello"} }}
            local parsedTable = DoParse("null:Hello\nbob:Hello")
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "Space between multiple speakers is ignored",
        test = function()
            local testTable = {{speaker = "null", text = {"Hello"} }, {speaker = "bob", text = {"Hello"} }}
            local parsedTable = DoParse("null:Hello\n\n\nbob:Hello")
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    -- {
    --     name = "quick test",
    --     test = function()
    --         local tree, result = DoParse("Bob:\nHello\n\nThis is more test yo yo yo")
    --         return result.isError == false
    --     end
    -- },
    {
        name = "Unregistered tag throws error",
        test = function()

            local tree, result = DoParse("Bob:\nHello<null>")
            return result.isError == true
        end
    },
    {
        name = "Tag at end of line isn't included in speech",
        test = function()
        local tagTable = { ["null"] = { type = "Short" }}
            local testTable = {{speaker = "Bob", text = {"Hello"} }}
            local parsedTable = DoParse("Bob:\nHello<null>", tagTable)

            -- This test doesn't care about the tag data
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "Two tags at end of line aren't included in speech",
        test = function()
        local tagTable = { ["null"] = { type = "Short" }}
            local testTable = {{speaker = "Bob", text = {"Hello"} }}
            local parsedTable = DoParse("Bob:\nHello<null><null>", tagTable)
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "Embedded tag isn't included in speech",
        test = function()
        local tagTable = { ["null"] = { type = "Short" }}
            local testTable = {{speaker = "Bob", text = {"Hello"} }}
            local parsedTable = DoParse("Bob:\nHel<null>lo", tagTable)
            StripTable(parsedTable, "tags")
            StripTable(testTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "First speech part as tag is removed",
        test = function()
        local tagTable = { ["null"] = { type = "Short" }}
            local testTable = {{speaker = "Bob", text = {"Hello"} }}
            local parsedTable = DoParse("Bob:<null>Hello", tagTable)
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "First speech part as tag is removed including space",
        test = function()
            local tagTable = { ["null"] = { type = "Short" }}
            local parsedTable = DoParse("Bob: <null>Hello", tagTable)
            local testTable = DoParse("Bob: Hello", tagTable)
            StripTable(parsedTable, "tags")
            StripTable(testTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "First speech part before newline as tag is removed",
        test = function()
            local tagTable = { ["null"] = { type = "Short" }}
            local testTable = {{speaker = "Bob", text = {"Hello"} }}
            local parsedTable = DoParse("Bob:<null>\nHello", tagTable)
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "All space is trimmed before tag",
        test = function()
            local tagTable = { ["null"] = { type = "Short" }}
            local parsedTable = DoParse("Bob:\nHello\n\n\n\n<null>", tagTable)
            local testTable = DoParse("Bob:\nHello\n\n\n\n", tagTable)
            StripTable(parsedTable, "tags")
            StripTable(testTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "All space is trimmed before and after tag",
        test = function()
            local tagTable = { ["null"] = { type = "Short" }}
            local parsedTable = DoParse("Bob:\nHello\n\n\n\n<null>\n\n\n\nWorld", tagTable)
            local testTable = DoParse("Bob:\nHello\n\n\n\n\n\n\n\nWorld", tagTable)
            StripTable(parsedTable, "tags")
            StripTable(testTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "Wide tags are remove from final text",
        test = function()
            local tagTable = { ["wide"] = { type = "Wide" }}
            local parsedTable = DoParse("Bob:<wide>Hello World</wide>", tagTable)
            local testTable = DoParse("Bob: Hello World", tagTable)
            StripTable(parsedTable, "tags")
            StripTable(testTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "Unclosed tag gives error",
        test = function()
            local tagTable = { ["slow"] = { type = "Wide" }}
            local tree, result = DoParse("bob:<slow>Hello", tagTable)
            return result.isError == true
        end
    },
    {
        name = "Orphan wide-close tag gives error",
        test = function()
            local tagTable = { ["slow"] = { type = "Wide" }}
            local tree, result = DoParse("bob:</slow>Hello", tagTable)
            return result.isError == true
        end
    },
    {
        name = "Orphan short-close tag gives error",
        test = function()
            local tagTable = { ["slow"] = { type = "Short" }}
            local tree, result = DoParse("bob:</slow>Hello", tagTable)
            return result.isError == true
        end
    },
    {
        name = "Unclosed tag gives error, even with nested tags",
        test = function()
            local tagTable = { ["slow"] = { type = "Wide" }}
            local tree, result = DoParse("bob:<slow><slow>Hello</slow>", tagTable)
            return result.isError == true
        end
    },
    {
        name = "Nested wide tags work",
        test = function()
            local tagTable = { ["slow"] = { type = "Wide" }}
            local parsedTable = DoParse("bob:<slow><slow>Hello</slow></slow>", tagTable)
            local testTable = DoParse("bob:Hello", tagTable)
            StripTable(parsedTable, "tags")
            StripTable(testTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "Short tag nested in Wide tags",
        test = function()
            local tagTable =
            {
                ["slow"] = { type = "Wide" },
                ["null"] = { type = "Short" }
            }
            local parsedTable = DoParse("bob:<slow><null>Hello</slow>", tagTable)
            local testTable = DoParse("bob:Hello", tagTable)
            StripTable(parsedTable, "tags")
            StripTable(testTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "Cut script", --date between tags is removed
        test = function()
            local tagTable =
            {
                ["script"] = { type = "Cut" },
            }
            local parsedTable = DoParse("bob:<script>Words go here</script>Hello", tagTable)
            local testTable = DoParse("bob:Hello", tagTable)
            StripTable(parsedTable, "tags")
            StripTable(testTable, "tags")
            return AreTablesEqual(parsedTable, testTable)

        end
    },
    {
        name = "Multi-line cut script",
        test = function()
            local tagTable =
            {
                ["script"] = { type = "Cut" },
            }

            local parsedTable = DoParse("bob:\n<script>\n\nWords go here\n\n</script>\nHello", tagTable)
            local testTable = DoParse("bob:Hello", tagTable)
            StripTable(parsedTable, "tags")
            StripTable(testTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "Multi-line start same line as text cut script",
        test = function()
            local tagTable =
            {
                ["script"] = { type = "Cut" },
            }

            local parsedTable = DoParse("bob:Hello<script>\nWords go here\n\n</script>", tagTable)
            local testTable = DoParse("bob:Hello", tagTable)
            StripTable(parsedTable, "tags")
            StripTable(testTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "Multi-line end same line as text cut script",
        test = function()
            local tagTable =
            {
                ["script"] = { type = "Cut" },
            }

            local parsedTable = DoParse("bob:<script>\nWords go here\n\n</script>Hello", tagTable)
            local testTable = DoParse("bob:Hello", tagTable)
            StripTable(parsedTable, "tags")
            StripTable(testTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "Multi-line end same line as text cut script",
        test = function()
            local tagTable =
            {
                ["script"] = { type = "Cut" },
            }

            local parsedTable = DoParse("bob:Hello\n\n<script>post text box script</script>\n\nGoodbye", tagTable)
            local testTable = DoParse("bob:Hello\n\nGoodbye", tagTable)
            StripTable(parsedTable, "tags")
            StripTable(testTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "Unclosed tag gives error",
        test = function()
            local tagTable = { ["slow"] = { type = "Wide" }}
            local tree, result = DoParse("bob:<slow>Hello", tagTable)
            return result.isError == true
        end
    },
    {
        name = "Tag at start of a line is at offset 0",
        test = function()


            local testText = "bob:<null>Hello"
            local tagTable = { ["null"] = { type = "Short" }}
            local tree, result = DoParse(testText, tagTable)

            local _, firstEntry = next(tree)
            local tagLookup = FormatTags(firstEntry.tags)
            local tagEntry = tagLookup[1][0] or {}


            --Hello Wor
            --123456789

            -- Tag position
            --*Hello Wo
            -- 0 offset

            --Hello Wor*
            -- 9 offset

            return tagEntry[1].id == "null"
        end
    },
    {
        name = "Tag at end of a line is at offset 0",
        test = function()


            local testText = "bob:Hello<null>"
            local tagTable = { ["null"] = { type = "Short" }}
            local tree, result = DoParse(testText, tagTable)

            local _, firstEntry = next(tree)
            local strLength = #("Hello")
            local tagLookup = FormatTags(firstEntry.tags)
            local tagEntry = tagLookup[1][strLength] or {}

            return tagEntry[1].id == "null"
        end
    },
    {
        name = "Front tag offset is correct in regards to line merging",
        test = function()


            local testText = "bob:   <null>Hello"
            local tagTable = { ["null"] = { type = "Short" }}
            local tree, result = DoParse(testText, tagTable)

            local _, firstEntry = next(tree)

            local tagLookup = FormatTags(firstEntry.tags)
            local tagEntry = tagLookup[1][0] or {}

            return tagEntry[1].id == "null"
        end
    },
    {
        name = "Front tag offset is correct in regards to line merging with pre-newline",
        test = function()


            local testText = "bob:   \n<null>Hello"
            local tagTable = { ["null"] = { type = "Short" }}
            local tree, result = DoParse(testText, tagTable)

            local _, firstEntry = next(tree)

            local tagLookup = FormatTags(firstEntry.tags)
            local tagEntry = tagLookup[1][0] or {}

            return tagEntry[1].id == "null"
        end
    },
    {
        name = "Front tag offset is correct in regards to line merging with post-newline",
        test = function()


            local testText = "bob:   <null>\nHello"
            local tagTable = { ["null"] = { type = "Short" }}
            local tree, result = DoParse(testText, tagTable)

            local _, firstEntry = next(tree)

            local tagLookup = FormatTags(firstEntry.tags)
            local tagEntry = tagLookup[1][0] or {}

            return tagEntry[1].id == "null"
        end
    },
    {
        name = "New line should be stripped with trailing tag", -- !! REPEAT THIS TEST WITH INLINE CUT
        test = function()


            local testText = "bob:Hello\n <null>"
            local tagTable = { ["null"] = { type = "Short" }}
            local tree, result = DoParse(testText, tagTable)

           -- I PrintTable(tree)
            return tree[1].text[1] == "Hello"
        end
    },
    {
        name = "All newlines before inner short tag are stripped", -- !! REPEAT THIS TEST WITH INLINE CUT
        test = function()

            -- Hello          Hello
            -- <null>    -->  World
            -- World

            local testText = "bob:Hello\n <null>\nWorld"
            local tagTable = { ["null"] = { type = "Short" }}
            local tree, result = DoParse(testText, tagTable)

           -- I PrintTable(tree)
            return tree[1].text[1] == "Hello\nWorld"
        end
    },
    {
        name = "Trailing tag should give correct index", -- !! REPEAT THIS TEST WITH INLINE CUT
        test = function()
            local testText = "bob:Hello\n<null>"
            local tagTable = { ["null"] = { type = "Short" }}
            local tree, result = DoParse(testText, tagTable)

            local _, firstEntry = next(tree)
            local strLength = #("Hello")
            local tagLookup = FormatTags(firstEntry.tags)
            local tagEntry = tagLookup[1][strLength] or {}
            return tagEntry[1].id == "null"
        end
    },
    {
        name = "Inner short tags should give correct index", -- !! REPEAT THIS TEST WITH INLINE CUT
        test = function()
            local testText = "bob:Hello\n<null>\nWorld"
            local tagTable = { ["null"] = { type = "Short" }}
            local tree, result = DoParse(testText, tagTable)

            local _, firstEntry = next(tree)
            --PrintTable(tree)
            local strLength = #("Hello")
            local tagLookup = FormatTags(firstEntry.tags)
            local tagEntry = tagLookup[1][strLength] or {}
            return tagEntry[1].id == "null"
        end
    },
    {
        name = "Both wide tags are added to the tag table",
        test = function()
            local testText = "bob:<slow>Hello</slow>"
            local tagTable = { ["slow"] = { type = "Wide" }}
            local tree, result = DoParse(testText, tagTable)

            local openTag, closeTag = GetFirstTagPair("slow", tree)
            local doTagsExist = (openTag ~= nil) and (closeTag ~= nil)
            return doTagsExist
        end,
    },
    {
        name = "Wide tag marksup twoword oneliner",
        test = function()
            local txt = "bob:<slow>Hello</slow> World"
            local text1 = GetTextInFirstWideTag(txt, {"slow"}, "slow")

            return text1 == "Hello"
        end,
    },
    {
        name = "Wide tag marksup full oneliner",
        test = function()
            local txt = "bob:<slow>Hello World</slow>"
            local text1 = GetTextInFirstWideTag(txt, {"slow"}, "slow")

            return text1 == "Hello World"
        end,
    },
    {
        name = "Wide tag marksup full oneliner nested",
        test = function()
            local txt = "bob:<slow><red>Hello World</red></slow>"
            local tags = {"slow", "red"}

            local text1 = GetTextInFirstWideTag(txt, tags, "slow")
            local text2 = GetTextInFirstWideTag(txt, tags, "red")

            return text1 == "Hello World" and
                  text2 == "Hello World"
        end,
    },
    {
        name = "Wide tag marksup full two-liner one page",
        test = function()
            local txt = "bob:<slow>Hello\nWorld</slow>"
            local text1 = GetTextInFirstWideTag(txt, {"slow"}, "slow")

            return text1 == "Hello\nWorld"
        end,
    },
    {
        name = "Wide tag marksup full two pages", -- really starting too need some helpers...
        test = function()
            local testText = "bob:<slow>Hello\n\nWorld</slow>"
            local tagTable = { ["slow"] = { type = "Wide" }}
            local tree, result = DoParse(testText, tagTable)
            local openTag, closeTag = GetFirstTagPair("slow", tree)

            local s = openTag.offset + 1
            local e = closeTag.offset + 1

            local isOpenTagOnLineOne = openTag.line == 1
            local isCloseTagOnLineTwo = closeTag.line == 2
            local isOpenTagOffsetAtStart = s == 1
            local isCloseOffsetAtEndOfWorld = e == #"World"

            return isCloseTagOnLineTwo and isOpenTagOnLineOne
                    and isOpenTagOffsetAtStart
                    and isCloseOffsetAtEndOfWorld
        end,
    },
    {
        name = "Wide tag respects line folding", -- really starting too need some helpers...
        test = function()
            local testText = "bob:<slow>Hello\n\n\nWorld</slow>"
            local tagTable = { ["slow"] = { type = "Wide" }}
            local tree, result = DoParse(testText, tagTable)
            local openTag, closeTag = GetFirstTagPair("slow", tree)

            local s = openTag.offset + 1
            local e = closeTag.offset + 1

            local isOpenTagOnLineOne = openTag.line == 1
            local isCloseTagOnLineTwo = closeTag.line == 2
            local isOpenTagOffsetAtStart = s == 1
            local isCloseOffsetAtEndOfWorld = e == #"World"

            return isCloseTagOnLineTwo and isOpenTagOnLineOne
                    and isOpenTagOffsetAtStart
                    and isCloseOffsetAtEndOfWorld
        end,
    },
    {
        name = "Wide tag marksup full oneliner nested with line break",
        test = function()

            local txt = "bob:<slow>\n<red>Hello World</red></slow>"
            local tags = {"slow", "red"}

            local text1 = GetTextInFirstWideTag(txt, tags, "slow")
            local text2 = GetTextInFirstWideTag(txt, tags, "red")

            return text1 == "Hello World" and
                  text2 == "Hello World"
        end,
    },
    {
        name = "Nexted Wide tag with two line breaks",
        test = function()

            local txt = "bob:<slow>\n<red>Hello World</red>\n</slow>"
            local tags = {"slow", "red"}

            local text1 = GetTextInFirstWideTag(txt, tags, "slow")
            local text2 = GetTextInFirstWideTag(txt, tags, "red")

            return text1 == "Hello World" and
                  text2 == "Hello World"
        end,
    },
    {
        name = "Nexted Wide tag with line break per tag",
        test = function()

            local txt = "bob:<slow>\n<red>\nHello World\n</red>\n</slow>"
            local tags = {"slow", "red"}

            local text1 = GetTextInFirstWideTag(txt, tags, "slow")
            local text2 = GetTextInFirstWideTag(txt, tags, "red")

            return text1 == "Hello World" and
                  text2 == "Hello World"
        end,
    },
    {
        name = "Nexted Wide tag with line break per tag and continuing text",
        test = function()

            local txt = "bob:<slow>\n<red>\nHello\n</red>\n</slow> World"
            local tags = {"slow", "red"}

            local text1 = GetTextInFirstWideTag(txt, tags, "slow")
            local text2 = GetTextInFirstWideTag(txt, tags, "red")

            return text1 == "Hello" and
                  text2 == "Hello"
        end,
    },
    {
        name = "Nexted Wide tag with continuing text",
        test = function()

            local txt = "bob:<slow><red>Hello</red></slow> World"
            local tags = {"slow", "red"}

            local text1 = GetTextInFirstWideTag(txt, tags, "slow")
            local text2 = GetTextInFirstWideTag(txt, tags, "red")

            return text1 == "Hello" and
                  text2 == "Hello"
        end,
    },
    {
        name = "Nested Wide tag with double line break per tag",
        test = function()

            local txt = "bob:<slow>\n\n<red>\n\nHello World\n\n</red>\n\n</slow>"
            local tags = {"slow", "red"}

            local text1 = GetTextInFirstWideTag(txt, tags, "slow")
            local text2 = GetTextInFirstWideTag(txt, tags, "red")

            return text1 == "Hello World" and text2 == "Hello World"
        end,
    },
    {
        name = "Test tricky nested tags",
        test = function()

            --
            -- Bob:Yoyo
            -- <slow>
            --
            -- <red>
            -- Hello World
            -- </red>
            --
            -- </slow> lolo

            --
            -- I'm ok with this being the table
            -- {
            --    "Yoyo",
            --    "Hello World"
            --    "lolo"
            -- }
            --
            --

            local txt = "bob:Yoyo\n<slow>\n\n<red>\n\nHello World\n\n</red>\n\n</slow> lolo"
            local tags = {"slow", "red"}

            local text1 = GetTextInFirstWideTag(txt, tags, "slow")
            local text2 = GetTextInFirstWideTag(txt, tags, "red")

            printf("<slow>%s</slow><red>%s</red>", text1, text2)
            return text1 == "Hello World" and text2 == "Hello World"
        end,
    },
    {
        name = "Test less  tricky nested tags",
        test = function()

            --
            -- Bob:Yoyo
            --
            -- <slow><red>Hello World</red></slow>
            --
            -- lolo

            --
            -- I'm ok with this being the table
            -- {
            --    "Yoyo",
            --    "Hello World"
            --    "lolo"
            -- }
            --
            --

            local txt = "bob:Yoyo\n\n<slow><red>Hello World</red></slow>\n\n lolo"
            local tags = {"slow", "red"}

            local text1 = GetTextInFirstWideTag(txt, tags, "slow")
            local text2 = GetTextInFirstWideTag(txt, tags, "red")

            return text1 == "Hello World" and text2 == "Hello World"
        end,
    },
    {
        name = "Test cut tag gets written into tag table",
        test = function()
            local txt = "bob:<script>Test();</script>Hello World"
            local tagTable = { ["script"] = { type = "Cut" }}
            local tree, result = DoParse(txt, tagTable)

            local _, firstEntry = next(tree)

            if not next(firstEntry.tags or {}) then
                print("Empty tag table")
                return false
            end

            PrintTable(firstEntry.tags)

            local hasOpenTag = firstEntry.tags[1].id == "script" and
                                firstEntry.tags[1].op == "open"
            return hasOpenTag
        end,
    },
    --{
    --      name = "Test inline cut tag at start of line for correct position.",
    --},
    -- {
    --     name = "Test inline cut tag at end of line for correct position."
    -- },
    -- {
    --     name = "Test inline cut tag at inside line for correct position."
    -- }
    -- Remaining tests?
    -- No tests that wide tags even work at all
    --  - Do the above tests with multiple line wides
    --      - Same line open tag
    --      - New line open tag

    -- The above with cut

    -- #Cut
    -- Test this:
    -- Bob:
    -- Hello
    --
    -- Didn't expect to see you here. <script>blah</script>

    -- Later cut between text boxes, it should be an entry on it's own, without text
    -- A script that's run between textboxes
    -- Double space <some script stuff> double space
    -- In this case maybe the tag itself can check for \n\n before it starts
    -- ^ do this add an annotation "After close"
    -- an annotation or even force the text to change to seomthing like
    --
    -- bob: hello
    -- bob: goodbye
    --
    -- or maybe this would work
    --
    -- script: <script>big ass script</script>


    -- Start test that tag's recorded positions
    -- and for the wide tags the text they cover


    -- First up:
    -- Slow text
    -- Fast text
    -- Pause
    -- Color text
    -- Shaking text
    -- Couple of transistions 0 - 2s or whatever
    --    - Fade
    --    - Fade and fall
    --    - Rotate
    --    - Fall and bounce back
    -- Reintegration
}

RunTests(tests)