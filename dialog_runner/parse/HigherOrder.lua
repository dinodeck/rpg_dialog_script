function Any(t, predicate, iter)
    t = t or {}
    iter = iter or ipairs

    for k, v in iter(t) do
        if predicate(v, k) then
            return true
        end
    end

    return false
end