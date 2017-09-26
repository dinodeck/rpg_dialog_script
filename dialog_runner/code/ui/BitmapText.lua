-- Should be support for newlines

-- Render and nextline and size



BitmapText = {}
BitmapText.__index = BitmapText
function BitmapText:Create(def)
    local texture = Texture.Find(def.texture)
    local this =
    {
        mTexture = texture,
        mWidth = texture:GetWidth(),
        mHeight = texture:GetHeight(),
        mGlyphW = def.cut_width,
        mGlyphH = def.cut_height,
        mLookUp = def.lookup,
        mSprite = Sprite.Create(),
        mAlignX = "left",
        mAlignY = "top"

    }
    this.mSprite:SetTexture(this.mTexture)

    this.mLookUp['\n'] = { uv = this.mLookUp[' '].uv, stepX = 0 }
    this.mLookUp['\r'] = { uv = this.mLookUp[' '].uv, stepX = 0 }

    setmetatable(this, self)
    return this
end

function BitmapText:GlyphWidth(glyph)
    local data = self.mLookUp[glyph] or self.mLookUp['?']
    return data.stepX or self.mGlyphW
end

-- used for alignment
function BitmapText:GlyphOffset(glyph)
    local data = self.mLookUp[glyph] or self.mLookUp['?']
    return (data.uv[3] or self.mGlyphW)*0.5
end

function BitmapText:GlyphUV(glyph)
    local data = self.mLookUp[glyph] or self.mLookUp['?']
    return self:IndexToUV(unpack(data.uv))
end

function BitmapText:AlignText(x, y)
    self.mAlignX = x
    self.mAlignY = y
end

function BitmapText:AlignTextX(x)
    self.mAlignX = x
end

function BitmapText:AlignTextY(y)
    self.mAlignY = y
end

function BitmapText:IndexToUV(x, y, w)
    local width = (w or self.mGlyphW)/self.mWidth
    local height = self.mGlyphH/self.mHeight

    local _x = x * (self.mGlyphW/self.mWidth)
    local _y = y * (self.mGlyphH/self.mHeight)

    return _x, _y, _x + width, _y + height
end

function BitmapText:DrawText(renderer, x, y, text)

    local _x = x
    for i = 1, string.len(text) do
        local c = string.sub(text, i, i)

        self.mSprite:SetUVs(self:GlyphUV(c))
        self.mSprite:SetPosition(_x, y)
        renderer:DrawSprite(self.mSprite)
        _x = _x + self:GlyphWidth(c)
    end

end

function BitmapText:RenderSubString(renderer, x, y, text, start, finish, color)

    start = start or 1
    finish = finish or string.len(text)
    color = color or Vector.Create(1, 1, 1, 1)

    self.mSprite:SetColor(color)
    local prevC = -1
    for i = start, finish do
        local c = string.sub(text, i, i)
        if prevC ~= -1 then
            -- kerning can be done here!
            x = x + self:GlyphWidth(prevC)
        end

        self.mSprite:SetUVs(self:GlyphUV(c))
        self.mSprite:SetPosition(x + self:GlyphOffset(c), y)
        renderer:DrawSprite(self.mSprite)

        prevC = c
    end
end

function BitmapText:DrawCache(renderer, cache, trans01, Transition)

    local index = math.floor(#cache*trans01)
    function calc01(index, count, progress)
        return (count*progress) - index
    end
    char01 = calc01(index, #cache, trans01)

    Transition = Transition or function(_, _, _, data) return data end

    for k, v in ipairs(cache) do

        local charData = Transition(k, index, char01, v)

        self.mSprite:SetUVs(unpack(charData.uvs))
        self.mSprite:SetPosition(unpack(charData.position))
        self.mSprite:SetColor(charData.color)
        renderer:DrawSprite(self.mSprite)
    end

end



-- This is a duplicate of the above there must be a better way
function BitmapText:CacheSubString(cache, x, y, text, start, finish, color)
    start = start or 1
    finish = finish or string.len(text)
    color = color or Vector.Create(1, 1, 1, 1)

    self.mSprite:SetColor(color)
    local prevC = -1

    for i = start, finish do
        local c = string.sub(text, i, i)
        if prevC ~= -1 then
            -- kerning can be done here!
            x = x + self:GlyphWidth(prevC)
        end

        table.insert(cache,
        {
            uvs = { self:GlyphUV(c) },
            position = { x + self:GlyphOffset(c), y },
            color = color,
            debugC = c,
        })

        prevC = c
    end
end

function BitmapText:Round(n)
    if n < 0 then
        return math.ceil(n - 0.5)
    else
        return math.floor(n + 0.5)
    end
end

function BitmapText:CacheText2d(x, y, text, color, maxWidth)
    -- returns a table of character info and positions
    -- this is then going to be modified and drawn
    local cache = {}
    self:DrawText2d(nil, x, y, text, color, maxWidth, cache)
    return cache
end

function BitmapText:DrawText2d(renderer, x, y, text, color, maxWidth, cache)

    -- We can only draw strings, so coerce all
    -- other types to string
    text = tostring(text)

    x = self:Round(x)
    y = self:Round(y)

    local yOffset = 0
    maxWidth = maxWidth or -1
    -- Center to top-left origin

    y = y - self.mGlyphH * 0.5

    if self.mAlignY == "bottom" then
        local lines = self:CountLines(text, maxWidth)
        yOffset = lines * self.mGlyphH
    elseif self.mAlignY == "center" then
        local lines = self:CountLines(text, maxWidth)
        yOffset = lines * math.floor((self.mGlyphH*0.5))
    end

    local lineEnd = 1
    local textLen = string.len(text)

    if textLen < 1 then
        return
    end

    -- local c = string.sub(text, 1, 1)
    -- x = x + self.mGlyphW * 0.5

    while lineEnd < (textLen + 1) do

        local outStart, lEnd, outPixelWidth =
            self:NextLine(text, lineEnd, maxWidth)

        lineEnd = math.min(textLen, lEnd) -- this shouldn't happen! hack fix!

        local xPos = x
        if self.mAlignX == "right" then
            xPos = xPos - outPixelWidth
        elseif self.mAlignX == "center" then
           xPos = xPos - math.ceil(outPixelWidth * 0.5)
        end

        if cache then
            self:CacheSubString(cache,
                                xPos, y + yOffset,
                                text, outStart, lineEnd,
                                color)
        else
            self:RenderSubString(renderer,
                            xPos, y + yOffset,
                            text, outStart, lineEnd,
                            color)
        end

        y = y - self.mGlyphH;

        -- so the while loop will properly support 1 char strings
        if lineEnd == textLen then
            break
        end
        lineEnd = lineEnd + 1
    end

end


function BitmapText:RenderLine(renderer, x, y, text, color)
    alignX = self.mAlignX
    alignY = self.mAlignY
    color = color or Vector.Create(1,1,1,1)

    if alignX == "right" then
        x = x - self:MeasureText(text):X()
    elseif alignX == "center" then
        x = x - self:MeasureText(text):X() / 2;
    end

    if alignY == "bottom" then
        y = y - self.mGlyphH
    elseif alignY == "center" then
        y = y - self.mGlyphH * 0.5
    end


    local prevC = -1
    for i = 1, string.len(text) do
        local c = string.sub(text, i, i)

        if prevC ~= -1 then
            x = x + self:GlyphWidth(prevC)
        end


        self.mSprite:SetUVs(self:GlyphUV(c))
        self.mSprite:SetPosition(x, y)
        renderer:DrawSprite(self.mSprite)

        prevC = c;
    end
end


function BitmapText:CalcWidth(str)
    -- return string.len(str) * self.mGlyphW
    local width = 0
    for i = 1, string.len(str) do
        local c = string.sub(str, i, i)
        width = width + self:GlyphWidth(c)
    end

    return width
end

function BitmapText:CalcHeight()
    return self.mGlyphH
end

function BitmapText:MeasureText(text, maxWidth)

    -- This function would be easy to change, if it didn't have the if
    -- Handle \n lines
    -- Countlines uses NextLine
    -- That's the place to make the change

    local maxWidth = maxWidth or -1

    if maxWidth < 1 then

        local width = self:CalcWidth(text)
        local height = self.mGlyphH
        return Vector.Create(width, height)

    else

        local lines, outLongestLine = self:CountLines(text, maxWidth)
        local width = outLongestLine
        if lines == 1 then
            width = self:CalcWidth(text)
        end
        local height = lines * self.mGlyphH
        return Vector.Create(width, height)
    end
end


-- Returns 3 variables
-- start - start of the next line
-- finish - end the next line
-- width - pixel with of the line
function BitmapText:NextLine(text, cursor, maxWidth)
    if self:IsWhiteSpace(string.sub(text, cursor, cursor)) then
        cursor = cursor + 1
    end

    local safeCursor = cursor
    local finish = cursor + 1

    local prevC = string.sub(text, cursor, cursor)

    local pixelWidth = 0
    local safePixelWidth = 0

    for i = cursor + 1, string.len(text) do
        local c = string.sub(text, i, i)
        local finishW = self:GlyphWidth(prevC)--self.mGlyphW;

        local foundNextLine = maxWidth ~= -1 and
            safeCursor ~= cursor and
            (pixelWidth  + finishW) >= maxWidth
        foundNextLine = foundNextLine or c == '\n'

        if not foundNextLine then

            if self:IsWhiteSpace(c) then
                safeCursor = math.max(cursor, i - 1)
                safePixelWidth = pixelWidth
            end

            pixelWidth = pixelWidth + finishW
        else
            finishW = self:GlyphWidth(prevC)
            if c == '\n' then
                safeCursor = math.max(cursor, i - 1)

            end
            return cursor, safeCursor + 1, safePixelWidth + finishW
        end

        prevC = c;
        finish = finish + 1;
    end

    local finishW = 0;

    if prevC ~= -1 then
        finishW = self:GlyphWidth(prevC);
    end

    -- From cursor to last word
     return cursor, finish, pixelWidth + finishW;
end

function BitmapText:IsWhiteSpace(char)
    if char == ' ' then
        return true
    end
    return false
end

function BitmapText:CountLines(text, maxWidth)

    local lineCount = 0
    local lineEnd = 1
    local outMaxLineWidth = -1
    local outStart = -1

    local textLen = string.len(text)

    if textLen == 1 then
        return 1
    end

    while lineEnd < textLen do

        outStart, lineEnd, outPixelWidth = self:NextLine(text,
                                                      lineEnd,
                                                       maxWidth)

        outMaxLineWidth = math.max(outMaxLineWidth, outPixelWidth)

        lineCount = lineCount + 1
    end

    return lineCount, outMaxLineWidth
end
