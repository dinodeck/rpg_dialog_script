
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

printf = function(...) print(string.format(...)) end

function Filter(t, p)
    local _result = {}
    for k, v in ipairs(t) do
        if p(v, k) then
            table.insert(_result, v)
        end
    end
    return _result
end

function StartsWith(str, start)
    return str:find(start) == 1
end

function RunTests(tests)


    if arg[1] == "--filter" then
        isFilter = true
        local prefix = tostring(arg[2])
        tests = Filter(tests,
                       function(test)
                          return StartsWith(test.name, prefix)
                       end)
    end

    passCount = 0

    failureList = {}

    local testsRun = 0
    for k, v in ipairs(tests) do

            printf("TEST: %s", v.name)
            local test_result = false
            local isError, msg = pcall(function() test_result = v.test() end)
            printf("RESULT: %s", tostring(test_result))
            if test_result then
                passCount = passCount + 1
            else
                table.insert(failureList, v.name)
            end
            if not isError then
                printf("ERROR: %s", tostring(msg))
            end
            print("")

    end

    printf("Tests passed [%d/%d]", passCount, #tests)

    if #failureList > 0 then
        print("FAILURES:")
        for k, v in ipairs(failureList) do
            printf("    %s", v)
        end
    end
end