#!/opt/local/bin/lua

require("ParseCore")


-- This will fail horribly on tables with loops
function AreTablesEqual(t1, t2)
    if type(t1) == "table" and type(t2) == "table" then

        -- Yes it would be better to merge the key set
        -- but this is simpler
        for k, v in pairs(t1) do
            if not AreTablesEqual(t1[k], t2[k]) then
                return false
            end
        end

        for k, v in pairs(t2) do
            if not AreTablesEqual(t1[k], t2[k]) then
                return false
            end
        end
        return true
    else
        return t1 == t2
    end
end


tests =
{
    one_box_of_text = function()
        return false
    end,

    one_box_of_text_with_speaker = function()
        return false
    end
}

DoParse("[Hello]")