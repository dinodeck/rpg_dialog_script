
function FormatTimeMS(seconds)
    local minutes = math.floor(seconds / 60)
    local seconds = seconds % 60
    return string.format("%01d:%02d", minutes, seconds)
end

function FormatTimeMSD(seconds)
    local minutes = math.floor(seconds / 60)
    local seconds = seconds % 60
    local decimalPlaces = math.floor( (seconds - math.floor(seconds)) * 100 + 0.5 )
    return string.format("%01d:%02d:%02d", minutes, seconds, decimalPlaces)
end

function RGB(r, g, b, a)
    local a = a or 255
    return Vector.Create(r/255,g/255,b/255,a/255)
end


function GenerateUVs(tileWidth, tileHeight, texture)

    -- This is the table we'll fill with uvs and return.
    local uvs = {}

    local textureWidth = texture:GetWidth()
    local textureHeight = texture:GetHeight()
    local width = tileWidth / textureWidth
    local height = tileHeight / textureHeight
    local cols = textureWidth / tileWidth
    local rows = textureHeight / tileHeight

    local ux = 0
    local uy = 0
    local vx = width
    local vy = height

    for j = 0, rows - 1 do
        for i = 0, cols -1 do

            table.insert(uvs, {ux, uy, vx, vy})

            -- Advance the UVs to the next column
            ux = ux + width
            vx = vx + width

        end

        -- Put the UVs back to the start of the next row
        ux = 0
        vx = width
        uy = uy + height
        vy = vy + height
    end
    return uvs
end

function ShallowClone(t)
    local clone = {}
    for k, v in pairs(t) do
        clone[k] = v
    end
    return clone
end

function DeepClone(t)
    local clone = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            clone[k] = DeepClone(v)
        else
            clone[k] = v
        end
    end
    return clone
end

function Clamp(value, min, max)
    return math.max(min, math.min(value, max))
end

function Lerp(value, in0, in1, out0, out1)
    normed = (value - in0) / (in1 - in0);
    result = out0 + (normed * (out1 - out0));
    return result;
end

function Round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

function PixelCoordsToUVs(tex, def)
    local texWidth = tex:GetWidth()
    local texHeight = tex:GetHeight()

    local x = def.x / texWidth
    local y = def.y / texHeight
    local width = def.width / texWidth
    local height = def.height / texHeight

    return {x, y, x + width, y + height}

end

function CreateSpriteSet(def)
    local texture = Texture.Find(def.texture)
    local spriteSet = {}
    for k, v in pairs(def.sprites) do
        local sprite = Sprite.Create()
        sprite:SetTexture(texture)
        sprite:SetUVs(unpack(PixelCoordsToUVs(texture, v)))
        spriteSet[k] = sprite
    end
    return spriteSet
end