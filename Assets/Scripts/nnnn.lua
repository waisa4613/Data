require "AdHoc"

local this = GetThis()

local r

function Start()
    r = GetComponent(this, "RigidBody")
    r:SetHasGravity(false)
    r:SetVelocity(0, 0, 10)
end

function Update()

end
