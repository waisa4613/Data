require "AdHoc"

local this = GetThis()

function Start()

end

function Update()

end

function OnTriggerExit(rhs)
    local m = GetComponent(this, "Material")
    m.albedo.x = 0
end