    local stack = StateStack:Create()
    stack:Push(OpenParse:Create(stack, context))

    while true do

        if stack:IsEmpty() or context.is_error then
            break
        end

        stack:Step()

        --print(context:Byte())
        -- if context:AtEnd() then
            -- break
        -- else
            -- context:AdvanceCursor()
        -- end
    end