require "AdHoc"

local this  = GetThis()
local input = GetInput() 

local downVector = Vector3D:new()
downVector.x = 0
downVector.y = -1
downVector.z = 0

local moveLimit = 0.9

function Move()
    local transform = GetComponent(this, "Transform")
    local speed     = 1

    -- Move
    if input:GetKey(AdHoc.Key.w) then
        transform.translate.z = transform.translate.z + speed * DeltaTime()
    elseif input:GetKey(AdHoc.Key.s) then
        transform.translate.z = transform.translate.z - speed * DeltaTime()
    elseif input:GetKey(AdHoc.Key.a) then
        transform.translate.x = transform.translate.x - speed * DeltaTime()
    elseif input:GetKey(AdHoc.Key.d) then
        transform.translate.x = transform.translate.x + speed * DeltaTime()
    end

    -- Movement limit
    if transform.translate.z > moveLimit then
        transform.translate.z = moveLimit
    elseif transform.translate.z < -moveLimit then
        transform.translate.z = -moveLimit
    end
    if transform.translate.x > moveLimit then
        transform.translate.x = moveLimit
    elseif transform.translate.x < -moveLimit then
        transform.translate.x = -moveLimit
    end
end

function RayHit()
    local transform = GetComponent(this, "Transform")
    local e = Raycast(transform.translate, downVector, 10)

    if e ~= 0 then
        local m = GetComponent(this, "Material")
        m.albedo.x = 7
        m.albedo.y = 1
        m.albedo.z = 1
        if input:GetKeyDown(AdHoc.Key.space) then
            local camera = FindEntity("Runtime Camera")
            if camera ~= nil then
                local cameraScript = GetComponent(camera, "Script")
                cameraScript:Set("shake", 1)
            end
            local manager = FindEntity("Scene Manager")
            local s = GetComponent(manager, "Script")
            s:Call("OpenBox", e)
        end
    else
        local m = GetComponent(this, "Material")
        m.albedo.x = 1
        m.albedo.y = 1
        m.albedo.z = 1
    end
end

function RayHitRotation()
    local transform = GetComponent(this, "Transform")
    local e = Raycast(transform.translate, downVector, 10)

    if e ~= 0 then
        local m = GetComponent(this, "Material")
        m.albedo.x = 7
        m.albedo.y = 1
        m.albedo.z = 1
        local transform = GetComponent(e, "Transform")
       
        angleY = transform.rotation.y
        if input:GetKey(AdHoc.Key.j) then
            angleY = angleY - 1 * DeltaTime()
        elseif input:GetKey(AdHoc.Key.l) then
            angleY = angleY + 1 * DeltaTime()
        end

        local rigidbody = GetComponent(e, "RigidBody")
        rigidbody:SetRotation(0, angleY, 0)
    else
        local m = GetComponent(this, "Material")
        m.albedo.x = 1
        m.albedo.y = 1
        m.albedo.z = 1
    end
end

function Update()
    Move()
    RayHit()
    RayHitRotation()
end
