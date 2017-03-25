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
             local testTable = {{speaker = "null", text = "Hello" }}
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
        name = "Speech may contain colon",
        test = function()
            local testTable = {{speaker = "null", text = "Hello Altar: Destroyer of Worlds." }}
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
    -- {
    --     name = "Ignore leading whitespace in speech",
    --     test = function()
    --         local testTable = {{speaker = "null", text = "null:\nHello" }}
    --         return AreTablesEqual(DoParse("null:Hello"), testTable)
    --     end
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