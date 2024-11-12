assert(led.count == 69, "This script must have exactly 69 leds assigned")

-- Vector library
local vector = {}
vector = {
    new = function(x, y, z)
        return {x=x or 0, y=y or 0, z=z or 0}
    end,
    getmag = function(v)
        return math.sqrt(v.x ^ 2 + v.y ^ 2 + v.z ^ 2)
    end,
    norm = function(v)
        local m = vector.getmag(v)
        if m ~= 0 then
            return vector.div(v, m)
        end
        return v
    end,
    add = function(a, b)
        return vector.new(a.x + b.x, a.y + b.y, a.z + b.z)
    end,
    sub = function(a, b)
        return vector.new(a.x - b.x, a.y - b.y, a.z - b.z)
    end,
    div = function(a, b)
        return vector.new(a.x / b, a.y / b, a.z / b)
    end,
    dist = function(a, b)
        return math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2 + (a.z - b.z) ^ 2)
    end,
}

-- x axis is projected on the part parallel to the window.
-- y axis is projected on the part of the strip that points towards the door.
-- z axis is projected on the small vertical part of the strip.

local drawLettersSeperate = true

local xAxisStart = 46
local deltaXAxis = 1

local yAxisStart = 31
local deltaYAxis = -1

local zAxisStart = 45
local deltaZAxis = -1

local function clearStrip()
    led.setAll(0, 0, 0)
end

local function displayCoordinate(v, color)
    led.set(math.floor(xAxisStart + deltaXAxis * v.x), color.r, color.g, color.b)
    led.set(math.floor(yAxisStart + deltaYAxis * v.y), color.r, color.g, color.b)
    led.set(math.floor(zAxisStart + deltaZAxis * v.z), color.r, color.g, color.b)
end

-- Given a list of points, calculate each coordinate in betweem them that should be displayed.
-- Returns the interpolation
local function interpolate(points)
    local interpolatedList = {}
    local vi = points[1]
    local goalPointIndex = 2
    while (goalPointIndex <= #points) do
        -- print(vi)
        while (vector.dist(vi, points[goalPointIndex]) >= 1) do
            table.insert(interpolatedList, vi)
            local direction = vector.norm(vector.sub(points[goalPointIndex], vi))
            -- division should lead to better accuracy?
            vi = vector.add(vi, vector.div(direction, 5))
        end
        vi = points[goalPointIndex]
        goalPointIndex = goalPointIndex + 1
    end
    return interpolatedList
end

-- Display a the list of many interpolations (which are each also lists)
local function displayInterpolations(lists, colors, sleepMsecs)
    local i = 1
    -- get max length of interpolated lists
    local maxLength = 0
    while (i <= #lists) do
        local l = #lists[i]
        if (maxLength < l) then
            maxLength = l
        end
        i = i + 1
    end
    i = 1
    led.setAll(0, 0, 0)
    -- display a point for each list every timestamp
    while (i <= maxLength) do
        -- from #lists to 1 to make sure interpolations earlier in lists overwrite later ones when the led they turn on is the same
        local j = #lists
        while (j >= 1) do
            if (i <= #(lists[j])) then
                displayCoordinate(lists[j][i], colors[j])
            end
            j = j - 1
        end
        time.waitFrames(1)
        led.setAll(0, 0, 0)
        i = i + 1
    end
end

while true do
    local pointsZ = {}
    local pointsE = {}
    local pointsU = {}
    local pointsS = {}

    if not drawLettersSeperate then
        -- coordinaten om letters door elkaar te zetten
        table.insert(pointsZ, vector.new( 0, 12, 12))
        table.insert(pointsZ, vector.new(12,  0, 12))
        table.insert(pointsZ, vector.new( 0, 12,  0))
        table.insert(pointsZ, vector.new(12,  0,  0))

        table.insert(pointsE, vector.new(11,  0, 11))
        table.insert(pointsE, vector.new( 0, 11, 11))
        table.insert(pointsE, vector.new( 0, 11,  6))
        table.insert(pointsE, vector.new( 9,  2,  6)) -- middelste streepje van E is korter
        table.insert(pointsE, vector.new( 0, 11,  6))
        table.insert(pointsE, vector.new( 0, 11,  0))
        table.insert(pointsE, vector.new(11,  0,  0))

        table.insert(pointsU, vector.vector.new( 0, 12, 11))
        table.insert(pointsU, vector.vector.new( 0, 12,  3))
        table.insert(pointsU, vector.vector.new( 2, 10,  0))
        table.insert(pointsU, vector.vector.new(10,  2,  0))
        table.insert(pointsU, vector.vector.new(12,  0,  3))
        table.insert(pointsU, vector.vector.new(12,  0, 11))
    
        table.insert(pointsS, vector.new(11,  0, 11))
        table.insert(pointsS, vector.new( 0, 11, 11))
        table.insert(pointsS, vector.new( 0, 11,  5))
        table.insert(pointsS, vector.new(11,  0,  5))
        table.insert(pointsS, vector.new(11,  0,  0))
        table.insert(pointsS, vector.new( 0, 11,  0))
    else
        -- coordinaten om letters naast elkaar te zetten
        table.insert(pointsZ, vector.new( 0, 31, 13))
        table.insert(pointsZ, vector.new( 5, 24, 13))
        table.insert(pointsZ, vector.new( 0, 31,  0))
        table.insert(pointsZ, vector.new( 5, 24,  0))

        table.insert(pointsE, vector.new(10, 16, 11))
        table.insert(pointsE, vector.new( 6, 23, 11))
        table.insert(pointsE, vector.new( 6, 23,  6))
        table.insert(pointsE, vector.new( 9, 18,  6))
        table.insert(pointsE, vector.new( 6, 23,  6))
        table.insert(pointsE, vector.new( 6, 23,  0))
        table.insert(pointsE, vector.new(10, 16,  0))

        table.insert(pointsU, vector.new(11, 15, 11))
        table.insert(pointsU, vector.new(11, 15,  2))
        table.insert(pointsU, vector.new(13, 13,  0))
        table.insert(pointsU, vector.new(16, 10,  0))
        table.insert(pointsU, vector.new(16,  8,  2))
        table.insert(pointsU, vector.new(16,  8, 11))

        table.insert(pointsS, vector.new(22,  0, 11))
        table.insert(pointsS, vector.new(17,  7, 11))
        table.insert(pointsS, vector.new(17,  7,  6))
        table.insert(pointsS, vector.new(22,  0,  6))
        table.insert(pointsS, vector.new(22,  0,  0))
        table.insert(pointsS, vector.new(17,  7,  0))
    end

    local interpolatedPointsZ = interpolate(pointsZ)
    local interpolatedPointsE = interpolate(pointsE)
    local interpolatedPointsU = interpolate(pointsU)
    local interpolatedPointsS = interpolate(pointsS)

    local interpolations = {}
    table.insert(interpolations, interpolatedPointsZ)
    table.insert(interpolations, interpolatedPointsE)
    table.insert(interpolations, interpolatedPointsU)
    table.insert(interpolations, interpolatedPointsS)

    local colors = {}
    table.insert(colors, {r=255, g=127, b=0  }) -- zeus orange
    table.insert(colors, {r=0,   g=255, b=0  })
    table.insert(colors, {r=0,   g=0,   b=255})
    table.insert(colors, {r=255, g=0,   b=0  })
    
    displayInterpolations(interpolations, colors, 20)
end
