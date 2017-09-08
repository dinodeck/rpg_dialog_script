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
            return AreTablesEqual(DoParse("null:Hello"), testTable)
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
            return AreTablesEqual(DoParse("null:Hello Altar: Destroyer of Worlds."), testTable)
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
            return AreTablesEqual(DoParse("Mr null:Hello"), testTable)
        end
    },
    {
        name = "Ignore leading newline in speech",
        test = function()
            local testTable = {{speaker = "null", text = {"Hello"} }}
            return AreTablesEqual(DoParse("null:\nHello"), testTable)
        end
    },
    {
        name = "Ignore leading whitespace in speech",
        test = function()
            local testTable = {{speaker = "null", text = {"Hello"} }}
            return AreTablesEqual(DoParse("null: Hello"), testTable)
        end
    },
    {
        name = "Single line breaks are preserved.",
        test = function()
            local testTable = {{speaker = "null", text = {"It was really dark\nthat's why we didn't see him."} }}
            return AreTablesEqual(DoParse("null:It was really dark\nthat's why we didn't see him."), testTable)
        end
    },
    {
        name = "Extra space after speech line break is ignored",
        test = function()
            local testTable = {{speaker = "null", text = {"It was really dark\nthat's why we didn't see him."} }}
            return AreTablesEqual(DoParse("null:It was really dark \n that's why we didn't see him."), testTable)
        end
    },
    {
        name = "Trailing newlines are removed",
        test = function()
            local testTable = {{speaker = "null", text = {"Hello", "Goodbye"} }}
            return AreTablesEqual(DoParse("null:Hello\n\nGoodbye\n\n\n"), testTable)
        end
    },
    {
        name = "A script can have multiple speakers",
        test = function()
            local testTable = {{speaker = "null", text = {"Hello"} }, {speaker = "bob", text = {"Hello"} }}
            return AreTablesEqual(DoParse("null:Hello\nbob:Hello"), testTable)
        end
    },
    {
        name = "Space between multiple speakers is ignored",
        test = function()
            local testTable = {{speaker = "null", text = {"Hello"} }, {speaker = "bob", text = {"Hello"} }}
            return AreTablesEqual(DoParse("null:Hello\n\n\nbob:Hello"), testTable)
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
            return AreTablesEqual(DoParse("Bob:\nHello<null>", tagTable), testTable)
        end
    },
    {
        name = "Two tags at end of line aren't included in speech",
        test = function()
        local tagTable = { ["null"] = { type = "Short" }}
            local testTable = {{speaker = "Bob", text = {"Hello"} }}
            return AreTablesEqual(DoParse("Bob:\nHello<null><null>", tagTable), testTable)
        end
    },
    {
        name = "Embedded tag isn't included in speech",
        test = function()
        local tagTable = { ["null"] = { type = "Short" }}
            local testTable = {{speaker = "Bob", text = {"Hello"} }}
            return AreTablesEqual(DoParse("Bob:\nHel<null>lo", tagTable), testTable)
        end
    },
    {
        name = "First speech part as tag is removed",
        test = function()
        local tagTable = { ["null"] = { type = "Short" }}
            local testTable = {{speaker = "Bob", text = {"Hello"} }}
            return AreTablesEqual(DoParse("Bob:<null>Hello", tagTable), testTable)
        end
    },
    {
        name = "First speech part as tag is removed including space",
        test = function()
        local tagTable = { ["null"] = { type = "Short" }}
            return AreTablesEqual(DoParse("Bob: <null>Hello", tagTable),
                                  DoParse("Bob: Hello", tagTable),
             testTable)
        end
    },
    {
        name = "First speech part before newline as tag is removed",
        test = function()
            local tagTable = { ["null"] = { type = "Short" }}
            local testTable = {{speaker = "Bob", text = {"Hello"} }}
            return AreTablesEqual(DoParse("Bob:<null>\nHello", tagTable), testTable)
        end
    },
    {
        name = "All space is trimmed before tag",
        test = function()
            local tagTable = { ["null"] = { type = "Short" }}
            return AreTablesEqual(DoParse("Bob:\nHello\n\n\n\n<null>", tagTable),
                                  DoParse("Bob:\nHello\n\n\n\n", tagTable))
        end
    },
    {
        name = "All space is trimmed before and after tag",
        test = function()
            local tagTable = { ["null"] = { type = "Short" }}
            return AreTablesEqual(DoParse("Bob:\nHello\n\n\n\n<null>\n\n\n\nWorld", tagTable),
                                  DoParse("Bob:\nHello\n\n\n\n\n\n\n\nWorld", tagTable))
        end
    },
    {
        name = "Wide tags are remove from final text",
        test = function()
            local tagTable = { ["wide"] = { type = "Wide" }}
            return AreTablesEqual(DoParse("Bob:<wide>Hello World</wide>", tagTable),
                                  DoParse("Bob: Hello World", tagTable))
        end

        -- 1. If it's wide put the first one on the open stack
        -- 2. If you meet a close pop the top of the stack and make sure they match
        -- 3. Clear both as you find them
        -- 4. Next test is nested tags
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
        name = "Orphan close tag gives error",
        test = function()
            local tagTable = { ["slow"] = { type = "Wide" }}
            local tree, result = DoParse("bob:</slow>Hello", tagTable)
            return result.isError == true
        end
    },
    {
        name = "Orphan close tag gives error even if short",
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
        name = "Nexted wide tags work",
        test = function()
            local tagTable = { ["slow"] = { type = "Wide" }}
            local tree, result = DoParse("bob:<slow><slow>Hello</slow></slow>", tagTable)
            return result.isError == true
        end
    }
    -- All the above tests should return text as a table not a string
    -- Then later there needs to be a bit of clever mungery to get it to look correct

    -- {
    --     name = "Empty line means new entry",
    --     local testTable = {{speaker="null", text}}
    -- }
    -- {
    --     name = "missing closing brace - simple error",
    --     test = function()
    --         local _, result = DoParse("Hello")
    --         return result.isError == true
    --     end
    -- }
}

RunTests(tests)