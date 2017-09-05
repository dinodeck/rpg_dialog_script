-- require("StateStack")

if not Asset then
require("HigherOrder")
end

printf = function(...) print(string.format(...)) end -- <- need a util class

eMatch =
{
    Success = "Success",
    Failure = "Failure",
    HaltFailure = "HaltFailure",
    Ongoing = "Ongoing"
}
function IsWhiteSpace(byte)
    local whitespace = {' ', '\n', '\t'}
    for k, v in ipairs(whitespace) do
        if v == byte then
            return true
        end
    end

    return false
end

MaWhiteSpace = {}
MaWhiteSpace.__index = MaWhiteSpace
function MaWhiteSpace:Create(context)
    local this =
    {
        mId = "MaWhiteSpace",
        mName = "Space Matcher",
        mContext = context,
        mState = eMatch.Ongoing,
    }

    setmetatable(this, self)
    return this
end

function MaWhiteSpace:Match()
    if self.mState ~= eMatch.Ongoing then
        return
    end

    if self.mContext:AtEnd() then
        self.mError = "Expecting whitespace got end of file"
        self.mState = eMatch.Failure
       return
    end

    if not self.mContext:IsWhiteSpace() then
       local c = tostring(self.mContext:Byte())
       self.mError = "Looking for whitespace but got [" .. c .. "]"
       self.mState = eMatch.Failure
       return
    end

    -- if the next character is non-whitespace, return as success so far
    if self.mContext:PeekAtEnd() or
       not self.mContext:PeekIsWhiteSpace() then
       print("Whitespace sucess")
       self.mState = eMatch.Success
   end
end


MaEnd = {}
MaEnd.__index = MaEnd
function MaEnd:Create(context)
    local this =
    {
        mId = "MaEnd",
        mName = "End Matcher",
        mContext = context,
        mState = eMatch.Ongoing
    }

    setmetatable(this, self)
    return this
end

function MaEnd:Match()
    if self.mState ~= eMatch.Ongoing then
        return
    end

    if self.mContext:AtEnd() then
        self.mState = eMatch.Success
    else
        self.mState = eMatch.Failure
    end
end

MaSpeaker = {}
MaSpeaker.__index = MaSpeaker
function MaSpeaker:Create(context)
    local this =
    {
        mId = "MaSpeaker",
        mName = "Speaker Matcher",
        mContext = context,
        mState = eMatch.Ongoing,
        mAccumulator = {}
    }

    setmetatable(this, self)
    return this
end

function MaSpeaker:GetName()
    return table.concat(self.mAccumulator)
end

function MaSpeaker:Match()
    if self.mState ~= eMatch.Ongoing then
        return
    end

    local c = self.mContext:Byte()

    if #self.mAccumulator == 0 then
        local expectedStart = self.mContext.cursor == 1
        or self.mContext:PrevByte() == "\n"

         if not expectedStart then
             self.mError = "Looking for speaker but must start on newline or first line of file."
             self.mState = eMatch.Failure
         end
    end

    if c == "\n" then
        self.mError = "Looking for speaker name but newline."
        self.mState = eMatch.Failure
        return
    end

    if self.mContext:AtEnd() then
        self.mError = "Unexpected end of file while execting speaker name."
        self.mState = eMatch.Failure
        return
    end

    table.insert(self.mAccumulator, c)

    if IsWhiteSpace(self.mAccumulator[1]) then
        self.mError = "Speaker name may not start with whitespace."
        self.mState = eMatch.Failure
        return
    end

    if c == ":" then

        local len = #self.mAccumulator
        if len == 1 then
            self.mError = "Speaker name must be at least one character."
            self.mState = eMatch.Failure
            return
        end

        if IsWhiteSpace(self.mAccumulator[len-1]) then
            self.mError = "Speaker name must not end in whitespace"
            self.mState = eMatch.Failure
            return
        end

        table.remove(self.mAccumulator) -- don't want ':' in the name
        self.mState = eMatch.Success
    end
end

MaSpeechLine = {}
MaSpeechLine.__index = MaSpeechLine
function MaSpeechLine:Create(context)
    local this =
    {
        mId = "MaSpeechLine",
        mName = "Speech Line Matcher",
        mContext = context,
        mState = eMatch.Ongoing,
        mAccumulator = {}
    }

    setmetatable(this, self)
    return this
end

function MaSpeechLine:GetLine()
    return table.concat(self.mAccumulator)
end

function MaSpeechLine:Match()
    if self.mState ~= eMatch.Ongoing then
        return
    end

    local c = self.mContext:Byte()

    if #self.mAccumulator > 0 then
        if c == '\n' or self.mContext:AtEnd()  then
            self.mState = eMatch.Success
            return
        end
    elseif self.mContext:AtEnd() then
        self.mError = "Expected line of speech got end of file."
        self.mState = eMatch.Failure
        return
    end

    table.insert(self.mAccumulator, c)

    if IsWhiteSpace(self.mAccumulator[1]) then
        self.mError = "Speech line may not start with whitespace."
        self.mState = eMatch.Failure
        return
    end
end

MaEmptyLine = {}
MaEmptyLine.__index = MaEmptyLine
function MaEmptyLine:Create(context)
    local this =
    {
        mId = "MaEmptyLine",
        mName = "Empty Speech Line Matcher",
        mContext = context,
        mState = eMatch.Ongoing,
        mAccumulator = {}
    }

    setmetatable(this, self)
    return this
end

function MaEmptyLine:Match()
    if self.mState ~= eMatch.Ongoing then
        return
    end

    if self.mContext:Byte() == '\n' and self.mContext:NextByte() == '\n' or
        self.mContext:Byte() == '\n' and self.mContext:PrevByte() == '\n' then
        self.mState = eMatch.Success
        return
    end

    self.mState = eMatch.Failure
end

MaTag = {}
MaTag.__index = MaTag
function MaTag:Create(context)
    local this =
    {
        mId = "MaTag",
        mName = "Tag Matcher",
        mContext = context,
        mState = eMatch.Ongoing,
        mAccumulator = {},
        mIsOpen = false
    }

    setmetatable(this, self)
    return this
end

function  MaTag:Reset()
    self.mIsOpen = false
    self.mAccumulator = {}
end

function MaTag:StripTag(str)
    return string.sub(str, 2, -2)
end

function MaTag:Match()
    if self.mState ~= eMatch.Ongoing then
        return
    end

    local c = self.mContext:Byte()

    if self.mIsOpen then
        if c == '\n' then
            self:Reset()
            return
        end

        if c == '>' then
            self.mIsOpen = false
            if #self.mAccumulator > 1 then
                table.insert(self.mAccumulator, c)
                self.mTagFull = table.concat(self.mAccumulator)
                self.mTag = self:StripTag(self.mTagFull)
                printf("Tag matched [%s]", self.mTagFull)

                if not self.mContext:GetTag(self.mTag) then
                    self.mError = string.format("Unknown tag [%s]", self.mTagFull)
                    self.mState = eMatch.HaltFailure
                    return
                end

                self.mState = eMatch.Success
                return
            else
                self:Reset()
                return
            end
        end
        table.insert(self.mAccumulator, c)
    end

    if self.mContext:AtEnd() then
        self.mError = "Reading tag failed."
        self.mState = eMatch.Failure
        return
    end

    if c == "<" then
        self.mIsOpen = true
        self.mAccumulator = {}
        table.insert(self.mAccumulator, c)
    end

    -- self.mState = eMatch.Failure
end


-- Maybe these blocks have enter and exit functions?
ReaderActions =
{
    START =
    {
        { MaEnd,        "FINISH"      },
        { MaWhiteSpace, "START"       },
        { MaSpeaker,    "SPEECH_UNIT_START" }
    },
    SPEECH_UNIT_START =
    {
        { MaSpeechLine, "SPEECH_UNIT" },
        { MaTag,        "NOT_IMPLEMENTED"},
        { MaWhiteSpace, "SPEECH_UNIT_START" },
    },
    SPEECH_UNIT =
    {
        { MaEmptyLine,  "SPEECH_UNIT" },
        { MaSpeaker,    "SPEECH_UNIT_START" },
        { MaSpeechLine, "SPEECH_UNIT" },
        { MaWhiteSpace, "SPEECH_UNIT" },
        { MaEnd,        "FINISH"      },
    },
    -- TAG =
    -- {
    --     { MaTag, "TAG" }
    -- },
    NOT_IMPLEMENTED = "NOT_IMPLEMENTED",
    FINISH = "FINISH"
}


function CreateContext(content, tagTable)
    local this =
    {
        content = content,
        cursor = 1,
        line_number = 1,
        column_number = 0,
        syntax_tree = {},
        is_error = false,
        tagTable = tagTable or {},

        Byte = function(self)
            return self.content:sub(self.cursor, self.cursor)
        end,

        NextByte = function(self)
            local cursor = self.cursor + 1
            return self.content:sub(cursor, cursor)
        end,

        PrevByte = function(self)
            local cursor = self.cursor - 1
            return self.content:sub(cursor, cursor)
        end,

        AtEnd = function(self)
            return self.cursor > #self.content
        end,


        IsWhiteSpace = function(self)
            return IsWhiteSpace(self:Byte())
        end,

        PeekAtEnd = function(self)
            return (self.cursor + 1) > #self.content
        end,

        PeekIsWhiteSpace = function(self)
            return IsWhiteSpace(self:NextByte())
        end,

        AdvanceCursor = function(self)

            self.cursor = self.cursor + 1
            self.column_number = self.column_number + 1

            if self:Byte() == '\n' then
                self.line_number = self.line_number + 1
                self.column_number = 0
            end

        end,

        OpenSpeech = function(self, speaker)
            table.insert(self.syntax_tree,
            {
                speaker = speaker,
                lineList = {},
                text = ""
            })
        end,

        AddLine = function(self, line)
            local current = self.syntax_tree[#self.syntax_tree]
            table.insert(current.lineList, line)
        end,

        AddLineBreak = function(self)
            self:AddLine('\n')
        end,

        -- CloseAnyOpenTag = function(self)
        --     local current = self.syntax_tree[#self.syntax_tree]

        --     if not current then return end

        --     current.openTag = nil
        -- end,

        GetTag = function(self, id)
            return self.tagTable[id]
        end,

        CloseAnyOpenSpeech = function(self)
            local current = self.syntax_tree[#self.syntax_tree]

            if not current then return end

            -- self:CloseAnyOpenTag()

            -- Avoid double spaces
            for k, v in ipairs(current.lineList) do
                if v:sub(-1) == " " then
                    current.lineList[k] = current.lineList[k]:sub(1, -2)
                end
            end

            -- Trim trailing newlines
            for i = #current.lineList, 1, -1 do
                local v = current.lineList[i]
                if v == '\n' then
                    table.remove(current.lineList)
                else
                    break
                end
            end

            current.text = {}
            local buffer = ""

            for k, v in ipairs(current.lineList) do

                if buffer == "" or buffer:sub(-1) == '\n' or v:sub(-1) == '\n' then

                    -- Two spaces are a new entry
                    if v == '\n' then

                        if buffer ~= "" then

                            if buffer:sub(-1) == '\n' then
                                buffer = buffer:sub(1, -2)
                            end
                            table.insert(current.text, buffer)
                            buffer = ""
                        end

                    else
                        buffer = buffer .. v
                    end
                else
                    buffer = buffer .. '\n' .. v
                end

            end
            table.insert(current.text, buffer)
            current.lineList = nil

        end
    }
    return this
end

Reader = {}
Reader.__index = Reader
function Reader:Create(matchDef, context)
    local this =
    {
        mMatchList = {},
        mMatchActionList = {},
        mContext = context,
    }

    for k, v in ipairs(matchDef) do
        this.mMatchList[k] = v[1]:Create(context)
        this.mMatchActionList[k] = v[2]
    end

    setmetatable(this, self)
    return this
end

function Reader:GetMatchers()
    return self.mMatchList
end

function Reader:IsFinished()

    if (not next(self:GetMatchers())) or   -- 1. The matcher list is empty
        self:ReadFailed() or            -- 2. All matches have failed -> error
        self:FoundMatch() then          -- 3. One match has passed
        return true
    end

    return false
end

function Reader:ReadFailed()
    local onlyFailsRemain = not Any(self:GetMatchers(),
        function(match)
            local state = match.mState
            return state == eMatch.Ongoing or state == eMatch.Success
        end)

    local haltingFailure = Any(self:GetMatchers(),
                            function(match)
                                return match.mState == eMatch.HaltFailure
                            end)

    return onlyFailsRemain or haltingFailure
end

function Reader:FoundMatch()
    return self:FindMatch() ~= nil
end

function Reader:FindMatch()
      for k, v in ipairs(self:GetMatchers()) do
        local state = v.mState
        if state == eMatch.Success then
            return v
        end
    end
    return nil
end

function Reader:GetMatchAction(match)
    for k, v in ipairs(self:GetMatchers()) do
        if v == match then
            return self.mMatchActionList[k]
        end
    end
    return nil
end

function Reader:Step()
    local context = self.mContext
    for k, v in ipairs(self:GetMatchers()) do
        local result = v:Match()
    end
end

function Reader:GetError()

    local lines = {}

    for k, v in ipairs(self:GetMatchers()) do
        if v.mError ~= nil and v.mError ~= "" then
            table.insert(lines, "Possible error: " .. v.mError)
        end
    end

    return lines
end


function ProcessMatch(match, context)
    --print(match.mId)

    if match.mId == "MaTag" then



    elseif match.mId == "MaSpeaker" then
        context:CloseAnyOpenSpeech()
        local name = match:GetName()
        context:OpenSpeech(name)
        printf("name: [%s]", name)
    elseif match.mId == "MaEmptyLine" then
        context:AddLineBreak()
    elseif match.mId == "MaSpeechLine" then
        local line = match:GetLine()
        context:AddLine(line)
        printf("line: [%s]", line)
    elseif match.mId == "MaEnd" then
        context:CloseAnyOpenSpeech()
    end
end

function DoParse(data, tagTable)
    local context = CreateContext(data, tagTable)
    local reader = Reader:Create(ReaderActions.START, context)

    while reader ~= nil do
        reader:Step()
        while not reader:IsFinished() do
            context:AdvanceCursor()
            reader:Step()
        end


        if reader:ReadFailed() then
            print("Reader failed")
            context.errorLines = reader:GetError()
            context.isError = true
            reader = nil
        elseif reader:FoundMatch() then
            local match = reader:FindMatch()
            printf("Found match %s", match.mName)
            ProcessMatch(match, context)
            local action = reader:GetMatchAction(match)

            if action == "FINISH" then
                print("Finished read.")
                reader = nil
            elseif action == "NOT_IMPLEMENTED" then
                print("Not implemented, ending here.")
                reader = nil
            else
                reader = Reader:Create(ReaderActions[action], context)
                context:AdvanceCursor()
                print("Reader", action)
            end
        end

    end

    PrintTable(context.syntax_tree)

    return context.syntax_tree,
    {
        isError = context.isError,
        errorLines = context.errorLines,
        lastLine = context.line_number
    }
end