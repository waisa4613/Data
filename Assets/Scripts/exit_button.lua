require "AdHoc"

local this = GetThis()
local input = GetInput()


local transform = GetComponent(this, "Transform")

Exit = false

local transform = GetComponent(this, "Transform")
local rigidbody = GetComponent(this, "RigidBody")

local a = 0.01
local w = 1.0
local p = 0.02
local t = 0

local w2 = 2.0
local p2 = 0.02

function RandomFloat(lower, greater)
    return lower + math.random()  * (greater - lower);
end

function GetState()
    return Exit
end

function Update()
    Move()
end

function Move()
    Lissajous()
end

function Lissajous()

    local x = transform.translate.x + a * math.sin(w*t + p)
    local y = transform.translate.y + a * math.sin(w2*t + p)

    t = t +  math.pi*2/360

    rigidbody:SetTranslation(x, y, transform.translate.z)
end

function VibrationX()
    
    local x = transform.translate.x + a * math.sin(w*t + p)

    t = t +  math.pi*2/30

    rigidbody:SetTranslation(x, transform.translate.y, transform.translate.z)

end

function VibrationY()
    
    local y = transform.translate.y + a * math.sin(w*t + p)

    t = t +  math.pi*2/30

    rigidbody:SetTranslation(transform.translate.x, y, transform.translate.z)

end