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