DiscourseEventManager = {}
DiscourseEventManager.__index = DiscourseEventManager

function DiscourseEventManager:Create()
    local this =
    {
        mEventList = {}
    }
    setmetatable(this, self)
    return this
end

function DiscourseEventManager:Render(renderer, trackbar)

    local value = trackbar:Value()
    local left = trackbar:Left()
    local right = trackbar:Right()

    for k, v in ipairs(self.mEventList) do
        trackbar:DrawEvent(renderer, v.position, v.position > value)
    end

end

function DiscourseEventManager:AddEvent(v01)
    -- Yes, this should be ordered really.
    table.insert(self.mEventList, {position = v01})
end

function DiscourseEventManager:Jump01(prev01, now01)

    local eventsToRun = {}

    -- same or previous does not fire any events
    if prev01 >= now01 then
        return eventsToRun
    end

    -- future events that have been jumped over do fire
    for k, v in ipairs(self.mEventList) do
        if v.position > prev01 and v.position <= now01 then
            table.insert(eventsToRun, v)
        end
    end

    return eventsToRun
end