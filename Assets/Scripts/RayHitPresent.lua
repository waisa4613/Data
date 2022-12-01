require "AdHoc"

local this         = GetThis()
local input        = GetInput()
local hitObjectCnt = 1
local angleY       = 0
local hitanimationflg = false
local animationtime = 0
local animationendtime = 7
local deletecount = 0
local moveend = 0.9

local entities              = {}
local nextId                = 0

-- Global flags
rotationFlg  = false
FPSflg       = false
objectcount = 0
maxobject = 20

AdHoc.Global.g_NailId = this

local meshName = {}
meshName[1]    = "bed.obj"
meshName[2]    = "dai.obj"
meshName[3]    = "sofa_double.obj"
meshName[4]    = "table.obj"

local downVector = Vector3D:new()
downVector.x = 0
downVector.y = -1
downVector.z = 0

local nailcolor = 0.3

local objScript = [[
    local this = GetThis()
    local animationtime = 0
    local animationendtime = 7

    function Start()
      
    end

    function Update()
        Animation()
    end

    function FixedUpdate()
        animationtime=animationtime+1
        if animationtime>animationendtime then
            DestroyEntity(this)
        end
    end

    function Animation()
        local transforms = GetComponent(this, "Transform")
        transforms.translate.x = transforms.translate.x 
        transforms.translate.y = transforms.translate.y-(1/(animationendtime-2))
        transforms.translate.z = transforms.translate.z 
        if transforms.translate.y < 0.2 then
            transforms.translate.y = 0.2
        end
    end

]]

function AddObjectCount()
    objectcount = objectcount + 1
end

function SpawnNaild()
    entities[nextId] = CreateEntity()
    local entitiestransforms = GetComponent(entities[nextId], "Transform")
    local thistransforms = GetComponent(this, "Transform")

    entitiestransforms.translate.x = thistransforms.translate.x 
    entitiestransforms.translate.y = thistransforms.translate.y
    entitiestransforms.translate.z = thistransforms.translate.z 
   
    entitiestransforms.scale.x = 0.05
    entitiestransforms.scale.y = 0.20
    entitiestransforms.scale.z = 0.05

    local meshes = GetComponent(entities[nextId], "Mesh")
    meshes:Load("Nail.obj")

    local m = GetComponent(entities[nextId], "Material")
    m.albedo.x = nailcolor
    m.albedo.y = nailcolor
    m.albedo.z = nailcolor

    AddComponent(entities[nextId], "Script", objScript)

    nextId = nextId + 1
end

function MoveCrossHair()
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

    if input:GetKeyDown(AdHoc.Key.space)  then
        SpawnNaild()
    end

    -- Movement limit
    if transform.translate.z > moveend then
        transform.translate.z = moveend
    elseif transform.translate.z < -moveend then
        transform.translate.z = -moveend
    end
    if transform.translate.x > moveend then
        transform.translate.x = moveend
    elseif transform.translate.x < -moveend then
        transform.translate.x = -moveend
    end

    if hitanimationflg == false then
        transform.translate.y = 1
    end

    -- Update rigidbody location
    local r = GetComponent(this, "RigidBody")
    r:SetTranslation(transform.translate.x, transform.translate.y, transform.translate.z )
end

function RayHit()
    local transform = GetComponent(this, "Transform")
    local rayOrigin = transform
    rayOrigin.translate.y = rayOrigin.translate.y - (rayOrigin.scale.y + 0.01)

    local e = Raycast(rayOrigin.translate, downVector, 0.3)

    if e ~= 0 then
        local m = GetComponent(this, "Material")
        m.albedo.x = 1
        m.albedo.y = 0
        m.albedo.z = 0
        if input:GetKeyDown(AdHoc.Key.space) then
            AddObjectCount()
            SpawnNaild()
            
            hitObjectCnt = hitObjectCnt + 1

            local transforms = GetComponent(e, "Transform")
            transforms.scale.x = 0.05
            transforms.scale.y = 0.05
            transforms.scale.z = 0.05

            local s      = GetComponent(e, "Script")
            local meshes = GetComponent(e, "Mesh")
            meshes:Load(meshName[s:Get("type")])
            s:Call("IsSet", true)
            s:Call("Hit")
            --s:Call("Particle")

            AdHoc.Global.CameraShake = true

            material = GetComponent(e, "Material")
            material.albedo.x = math.random(0, 1)
            material.albedo.y = math.random(0, 1)
            material.albedo.z = math.random(0, 1)

            -- TODO: change to mesh collider?
            local r = GetComponent(e, "RigidBody")
            r:SetVelocity(0, 0, 0)
            r:SetTranslation(transforms.translate.x, 0.1, transforms.translate.z)
            r:UpdateGeometry()
       end
    else
        local m = GetComponent(this, "Material")
        m.albedo.x = nailcolor
        m.albedo.y = nailcolor
        m.albedo.z = nailcolor
    end
end

function RayHitRotation()
    local transform = GetComponent(this, "Transform")
    local rayOrigin = transform
    rayOrigin.translate.y = rayOrigin.translate.y - (rayOrigin.scale.y + 0.01)
    local e = Raycast(rayOrigin.translate, downVector, 0.7)

    if e ~= 0 then
       
        local m = GetComponent(this, "Material")
        m.albedo.x = 1
        m.albedo.y = 0
        m.albedo.z = 0
        local transform3 = GetComponent(e, "Transform")
       
        angleY = transform3.rotation.y
        if input:GetKey(AdHoc.Key.j) then
            angleY = angleY + 0.05
        elseif input:GetKey(AdHoc.Key.l) then
            angleY = angleY - 0.05
        end

        local tempRigidbody = GetComponent(e, "RigidBody")
        tempRigidbody:SetRotation(0, angleY, 0)
        tempRigidbody:UpdateGeometry()

        if input:GetKeyDown(AdHoc.Key.space) then
            deletecount=deletecount+1
            if deletecount==3 then
                DestroyEntity(e)
            end
        end
    else
        deletecount=0
        local m = GetComponent(this, "Material")
        m.albedo.x = nailcolor
        m.albedo.y = nailcolor
        m.albedo.z = nailcolor
    end
end

function Start()
    local t = GetComponent(this, "Transform")
    t.translate.y = 1
end

function Update()
    if FPSflg == false then
        if hitanimationflg == true then
            HitAnimation()
        end
        MoveCrossHair()
        if objectcount >= maxobject then
            rotationFlg = true
         end
        if rotationFlg == false then
            RayHit()
        else
            RayHitRotation()
        end
        if input:GetKeyUp(AdHoc.Key.enter) and rotationFlg == true then
            FPSflg = true
        end
    else
        local m = GetComponent(this, "Mesh")
        m.toDraw = false;
    end
end

function FixedUpdate()
    if hitanimationflg==true then
        animationtime=animationtime+1
        if animationtime>animationendtime then
            hitanimationflg = false
            animationtime = 0
        end
    end
end

function HitAnimation()
    local transforms = GetComponent(this, "Transform")
    transforms.translate.x = transforms.translate.x 
    transforms.translate.y = transforms.translate.y - (1 / animationendtime)
    transforms.translate.z = transforms.translate.z 

    local r = GetComponent(this, "RigidBody")
    r:SetTranslation(transforms.translate.x, transforms.translate.y, transforms.translate.z )
end
