assert(led.count == 69, "This script must have exactly 69 leds assigned")

drawLettersSeperate = true

-- x axis is the part parallel to the window.
-- y axis is the part of the strip that points towards the door.
-- z axis is the small upward part of the strip.

xAxisStart = 46
deltaXAxis = 1

yAxisStart = 31
deltaYAxis = -1

zAxisStart = 45
deltaZAxis = -1

-- makes a new vector
function new(x,y,z)
    return {x=x or 0, y=y or 0, z=z or 0}
end

-- get the magnitude of a vector
function getmag(v)
    return math.sqrt(v.x^2 + v.y^2 + v.z^2)
end

-- get the magnitude squared of a vector
function magSq(v)
    return v.x^2 + v.y^2 + v.z^2
end

-- meta function to make vectors negative
-- ex: (negative) -vector(5,6) is the same as vector(-5,-6)
function unm(v)
    return new(-v.x, -v.y, -v.z)
end

-- meta function to add vectors together
-- ex: (vector(5,6) + vector(6,5)) is the same as vector(11,11)
function add(a,b)
    return new(a.x+b.x, a.y+b.y, a.z+b.z)
end

-- meta function to subtract vectors
function sub(a,b)
    return new(a.x-b.x, a.y-b.y, a.z-b.z)
end

-- meta function to multiply vectors
function mul(a,b)
    if type(a) == 'number' then
        return new(mul(a, b.x), mul(a, b.y), mul(a, b.z))
    elseif type(b) == 'number' then
        return new(mul(a.x, b), mul(a.y, b), mul(a.z, b))
    else
        return new(mul(a.x,b.x), mul(a.y,b.y), mul(a.z,a.z))
    end
end

-- meta function to divide vectors
function div(a,b)
    return new(a.x/b, a.y/b, a.z/b)
end

-- meta function to check if vectors have the same values
function eq(a,b)
    return a.x==b.x and a.y==b.y and a.z==b.z
end

-- meta function to change how vectors appear as string
-- ex: print(vector(2,8,10)) - this prints '(2,8,10)'
function tostring(v)
    return "("..v.x..", "..v.y..", "..v.z..")"
end

-- get the distance between two vectors
function dist(a,b)
    return math.sqrt((min(a.x,b.x))^2 + (min(a.y,b.y))^2 + (min(a.z,b.z))^2)
end

-- return the dot product of the vector
function dot(v)
    return v.x * v.x + v.y * v.y + v.z * v.z
end

-- normalize the vector (give it a magnitude of 1)
function norm(v)
    local m = getmag(v)
    if m~=0 then
        return div(v, m)
    end
    return v
end

-- Clamp each axis between max and min's corresponding axis
function clamp(v, min, max)
    local x = math.min( math.max( v.x, min.x ), max.x )
    local y = math.min( math.max( v.y, min.y ), max.y )
    local z = math.min( math.max( v.z, min.z ), max.z )
    return new(x,y,z)
end

-- get the heading (direction) of a vector
function heading(v)
    -- TODO: add z
    return -math.atan(v.y, v.x)
end

-- return x, y and z of vector, unpacked from table
function unpack(v)
    return v.x, v.y, v.z
end

function distance(a, b)
    return math.sqrt((a.x - b.x)^2 + (a.y - b.y)^2 + (a.z - b.z)^2)
end

function clearStrip()
    led.setAll(0, 0, 0)
end

function displayCoordinate(v, color)
    led.set(math.floor(xAxisStart + deltaXAxis * v.x), color.r, color.g, color.b)
    led.set(math.floor(yAxisStart + deltaYAxis * v.y), color.r, color.g, color.b)
    led.set(math.floor(zAxisStart + deltaZAxis * v.z), color.r, color.g, color.b)
end

-- Given a list of points, calculate each coordinate in betweem them that should be displayed.
-- Returns the interpolation
function interpolate(points)
    local interpolatedList = {}
    local vi = points[1]
    local goalPointIndex = 2
    while (goalPointIndex <= #points) do
        -- print(vi)
        while (distance(vi, points[goalPointIndex]) >= 1) do
            table.insert(interpolatedList, vi)
            local direction = norm(sub(points[goalPointIndex], vi))
            -- division should lead to better accuracy?
            vi = add(vi, div(direction, 5))
        end
        vi = points[goalPointIndex]
        goalPointIndex = goalPointIndex + 1
    end
    return interpolatedList
end

-- Display a the list of many interpolations (which are each also lists)
function displayInterpolations(lists, colors, sleepMsecs)
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
    clearStrip()
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
        time.sleepMsecs(sleepMsecs)
        clearStrip()
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
        table.insert(pointsZ, new( 0, 12, 12))
        table.insert(pointsZ, new(12,  0, 12))
        table.insert(pointsZ, new( 0, 12,  0))
        table.insert(pointsZ, new(12,  0,  0))

        table.insert(pointsE, new(11,  0, 11))
        table.insert(pointsE, new( 0, 11, 11))
        table.insert(pointsE, new( 0, 11,  6))
        table.insert(pointsE, new( 9,  2,  6)) -- middelste streepje van E is korter
        table.insert(pointsE, new( 0, 11,  6))
        table.insert(pointsE, new( 0, 11,  0))
        table.insert(pointsE, new(11,  0,  0))

        table.insert(pointsU, new( 0, 12, 11))
        table.insert(pointsU, new( 0, 12,  3))
        table.insert(pointsU, new( 2, 10,  0))
        table.insert(pointsU, new(10,  2,  0))
        table.insert(pointsU, new(12,  0,  3))
        table.insert(pointsU, new(12,  0, 11))
    
        table.insert(pointsS, new(11,  0, 11))
        table.insert(pointsS, new( 0, 11, 11))
        table.insert(pointsS, new( 0, 11,  5))
        table.insert(pointsS, new(11,  0,  5))
        table.insert(pointsS, new(11,  0,  0))
        table.insert(pointsS, new( 0, 11,  0))
    else
        -- coordinaten om letters naast elkaar te zetten
        table.insert(pointsZ, new( 0, 31, 13))
        table.insert(pointsZ, new( 5, 24, 13))
        table.insert(pointsZ, new( 0, 31,  0))
        table.insert(pointsZ, new( 5, 24,  0))

        table.insert(pointsE, new(10, 16, 11))
        table.insert(pointsE, new( 6, 23, 11))
        table.insert(pointsE, new( 6, 23,  6))
        table.insert(pointsE, new( 9, 18,  6))
        table.insert(pointsE, new( 6, 23,  6))
        table.insert(pointsE, new( 6, 23,  0))
        table.insert(pointsE, new(10, 16,  0))

        table.insert(pointsU, new(11, 15, 11))
        table.insert(pointsU, new(11, 15,  2))
        table.insert(pointsU, new(13, 13,  0))
        table.insert(pointsU, new(16, 10,  0))
        table.insert(pointsU, new(16,  8,  2))
        table.insert(pointsU, new(16,  8, 11))

        table.insert(pointsS, new(22,  0, 11))
        table.insert(pointsS, new(17,  7, 11))
        table.insert(pointsS, new(17,  7,  6))
        table.insert(pointsS, new(22,  0,  6))
        table.insert(pointsS, new(22,  0,  0))
        table.insert(pointsS, new(17,  7,  0))
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
    table.insert(colors, {r=255,g=127,b=0}) -- zeus orange
    table.insert(colors, {r=0,g=255,b=0})
    table.insert(colors, {r=0,g=0,b=255})
    table.insert(colors, {r=255,g=0,b=0})
    
    displayInterpolations(interpolations, colors, 20)
end

