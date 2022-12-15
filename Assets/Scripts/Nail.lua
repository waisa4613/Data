require "AdHoc"

local this  = GetThis()
local input = GetInput() 
local en = {}

local downVector = Vector3D:new()
downVector.x = 0
downVector.y = -1
downVector.z = 0
local VibStop = true
local VibTime = 0
local vibe =true
local moveLimit = 0.9
local rayDistance = 0.7
local m = GetComponent(this,"Mesh")
AdHoc.Global.Start=0
rayPos = { Vector3D:new(), Vector3D:new(), Vector3D:new(),Vector3D:new()}



function Move()
    local transform = GetComponent(this, "Transform")
    local speed     = 1
    -- Move
    if AdHoc.Global.Start>=2 then
        m.toDraw =true
    if input:GetKey(AdHoc.Key.w) or input:GetButton(AdHoc.Controller.dpad_up,0)
    then
        transform.translate.z = transform.translate.z + speed * DeltaTime()
    elseif input:GetKey(AdHoc.Key.s)or input:GetButton(AdHoc.Controller.dpad_down,0)
     then
        transform.translate.z = transform.translate.z - speed * DeltaTime()
    elseif input:GetKey(AdHoc.Key.a) or input:GetButton(AdHoc.Controller.dpad_left,0)
     then
        transform.translate.x = transform.translate.x - speed * DeltaTime()
    elseif input:GetKey(AdHoc.Key.d) or input:GetButton(AdHoc.Controller.dpad_right,0) 
    then
        transform.translate.x = transform.translate.x + speed * DeltaTime()
    end
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
    
    local cnt = 1
    for i = -1, 1, 2 do
        for p = -1, 1, 2 do
            rayPos[cnt].x=transform.translate.x+0.07*i
            rayPos[cnt].y=transform.translate.y
            rayPos[cnt].z=transform.translate.z+0.07*p
            cnt = cnt + 1
        end
    end
    local et = {Raycast(transform, downVector, rayDistance),Raycast(rayPos[1], downVector,rayDistance),Raycast(rayPos[2], downVector, rayDistance),Raycast(rayPos[3], downVector, rayDistance),Raycast(rayPos[4], downVector, rayDistance)}

    local Press = false

    if input:GetKeyDown(AdHoc.Key.space) or input:GetButtonDown(AdHoc.Controller.b , 0) then
       
        Press = true
        local t = FindEntity("NailFall")
        if t ~= nil then
            local ns =GetComponent(t,"Script")
            ns:Call("NailSpawn",transform)
        end
        if VibStop==true  then
            input:SetControllerVibration(20 ,20 ,0)
            VibStop=false
            --LogMessage("VibOn")
        end
       
    end

    local rayFlag = false
    local e = 0
    for i = 1, 5 do
        if et[i]~=0 then
            rayFlag=true
            if e == 0 then
                e=et[i]
            elseif e ~= et[i] then
                local t1 =  GetComponent(e, "Transform")
                local t2 =  GetComponent(et[i], "Transform")
                local distance1 = math.sqrt((transform.translate.x-t1.translate.x)*(transform.translate.x-t1.translate.x)+(transform.translate.z-t1.translate.z)*(transform.translate.z-t1.translate.z))
                local distance2 = math.sqrt((transform.translate.x-t2.translate.x)*(transform.translate.x-t2.translate.x)+(transform.translate.z-t2.translate.z)*(transform.translate.z-t2.translate.z))

                if distance1 > distance2 then
                    e = et[i]
                end
            end
        end
    end

    if rayFlag == true then
        local m = GetComponent(this, "Material")
        m.albedo.x = 7
        m.albedo.y = 1
        m.albedo.z = 1
        if Press == true then
            local ScoreManager = FindEntity("ScoreManager")
            if ScoreManager ~= nil then
                local sm =GetComponent(ScoreManager,"Script")
                sm:Call("AddScore",6,1)
            end
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
        if input:GetKey(AdHoc.Key.j)   or input:GetButton(AdHoc.Controller.rshoulder, 0) then
            angleY = angleY - 1 * DeltaTime()
           -- LogMessage("yyy")
        elseif input:GetKey(AdHoc.Key.l) or input:GetButton(AdHoc.Controller.lshoulder , 0)then
            angleY = angleY + 1 * DeltaTime()
           -- LogMessage("xxxx")

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
    
    if VibStop == false then 
        
        VibTime = VibTime + 1
        --LogMessage(VibTime)
        
    end
    if VibTime>=4 then 
    --LogMessage("VibOff")
    input:SetControllerVibration(0,0,0)
    VibStop=true
    VibTime=0
    end
end

function FixedUpdate() 

   

end
