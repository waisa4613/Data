require "AdHoc"

local this = GetThis()

function Start()
    transform = GetComponent(this, "Transform")
    LogMessage(transform:GetForward().x)
    LogMessage(transform:GetForward().y)
    LogMessage(transform:GetForward().z)
    transform.rotation.x=0
    transform.rotation.y=math.rad(45)
    transform.rotation.z=0
    LogMessage(transform:GetForward().x)
    LogMessage(transform:GetForward().y)
    LogMessage(transform:GetForward().z)
end

function Update()

    transform = GetComponent(this, "Transform")
    transform.translate.x=transform.translate.x+transform:GetForward().x/10
    transform.translate.y= transform.translate.y+transform:GetForward().y/10
    transform.translate.z=transform.translate.z+transform:GetForward().z/10
end
