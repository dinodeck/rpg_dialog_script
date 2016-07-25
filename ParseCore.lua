require("StateStack")

function CreateContext(content)
    return
    {
        content = content,
        cursor = 1,
        line_number = 1,
        column_number = 0,
        syntax_tree = {},

        Byte = function(self)
            return self.content:sub(self.cursor, self.cursor)
        end,

        AtEnd = function(self)
            return self.cursor == #self.content
        end,

        AdvanceCursor = function(self)

            self.cursor = self.cursor + 1
            if self.cursor > #self.content then
                print("Warning: Trying to advance past the end of the content.")
                self.cursor = #self.content
            end
            self.column_number = self.column_number + 1

            if self:Byte() == '\n' then
                self.line_number = self.line_number + 1
                self.column_number = 0
            end

        end
    }
end

-- [1] Start by printing out the no lines in the file
-- [2] Make a gist at this point as it's quite a common op

function DoParse(data)
    local context = CreateContext(data)
    while true do
        print(context:Byte())
        if context:AtEnd() then
            break
        else
            context:AdvanceCursor()
        end
    end
    return context
end