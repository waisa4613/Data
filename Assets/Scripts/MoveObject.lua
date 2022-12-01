require "AdHoc"

local this                  = GetThis()
local entities              = {}
local entitiesHitFlg        = {}
local entitiesObjectFlag    = {}
local nextId                = 0
local time                  = 0
local positionX             = -0.9

local objScript = [[
    local this = GetThis()
    type       = 10
    hit        = false
    local audio
    local idletime = 0
    local randomScale  = math.random(1, 3)
    local scaleSizes = {}
    scaleSizes[1]    = 0.075
    scaleSizes[2]    = 0.1
    scaleSizes[3]    = 0.125
    local once = false
    local speed = 0.3
    local endline = 1.5
    

    --position
    local t2={}
    t2["CornerPosition"]=Vector3D:new()
    t2["CornerPosition2"]=Vector3D:new()
    t2["linetransform"]=Vector3D:new()
    t2["Movetransform"]=Vector3D:new()
    t2["force"]=Vector3D:new()
    t2["Vector"]=Vector3D:new()
    t2["Vector2"]=Vector3D:new()
    t2["angleforce"]=Vector3D:new()
    t2["angle"]=0
    local range=1

    --flg
    hitAreaFlg = false
    particleflg=false
    moveflg=true
    moveingtime=0
    idleflg = true
    isdeletegorst = false

    --gorst
    local ghostEntities = {}
    
    --パーティクル用変数
    local particleentities={}
    local rigidbodies = {}
    local nextId = 0
    local transform
    local destroyparticletime = 0

    local isSet = false
    local isGolden =false

    function IsSet(x)
        isSet = x
    end

    function IsGolden(x)
        isGolden = x
    end

    function Hit()
        moveflg=false
        DestroyGhost()
    end

    --PositionFunction
    function SecondPointAngle(_x1,_y1,_x2,_y2) 
        local angle=(_x1*_x2+_y1*_y2)/(math.sqrt((_x1*_x1+_y1*_y1))*math.sqrt((_x2*_x2+_y2*_y2)))
        angle=math.acos(angle)
        angle=angle/math.pi*180
        return angle
    end
    
    function AngleRotationX(_x1,_z1,_x2,_z2,_angle)
        local X=(_x1-_x2)*math.cos(_angle)-(_z1-_z2)*math.sin(_angle)
        return X
    end
    
    function AngleRotationZ(_x1,_z1,_x2,_z2,_angle)
        local Z=(_x1-_x2)*math.sin(_angle)+(_z1-_z2)*math.cos(_angle)
        return Z
    end
    
    function NormalizeX(_x1,_z1,_x2,_z2)
        local Power=math.sqrt(((_x1-_x2)*(_x1-_x2))+((_z1-_z2)*(_z1-_z2)))
        return (_x1-_x2)/Power
    end
    
    function NormalizeZ(_x1,_z1,_x2,_z2)
        local Power=math.sqrt(((_x1-_x2)*(_x1-_x2))+((_z1-_z2)*(_z1-_z2)))
        return (_z1-_z2)/Power
    end

    -- FIXME
    function HitArea()
        local transforms = GetComponent(this, "Transform")
        
        if transforms.translate.z<1.0 and transforms.translate.z>0.8 then
            hitAreaFlg=true
        elseif transforms.translate.z>-1.0 and transforms.translate.z<-0.8 then
            hitAreaFlg=true
        elseif transforms.translate.x<1.0 and transforms.translate.x>0.8 then
            hitAreaFlg=true
        elseif transforms.translate.x>-1.0 and transforms.translate.x<-0.8 then
            hitAreaFlg=true
        elseif transforms.translate.x>-0.2 and transforms.translate.x<0.2 then
            if transforms.translate.z>-0.2 and transforms.translate.z<0.2 then
                hitAreaFlg=true
            else
                hitAreaFlg=false
            end
        else
            hitAreaFlg=false
        end

        if transforms.translate.y<0.2 then
            hitAreaFlg=false
        end
        if isGolden==true then
            material=GetComponent(this,"Material")
            material.albedo.x=1
            material.albedo.y=1
            material.albedo.z=0
        elseif hitAreaFlg == true then
            material=GetComponent(this,"Material")
            material.albedo.x=5
            material.albedo.y=5
            material.albedo.z=3
        elseif isSet == false then
            material=GetComponent(this,"Material")
            material.albedo.x=1
            material.albedo.y=1
            material.albedo.z=1
        end
    end

    function Start()
       randomScale  = math.random(1, 3)
       type = math.random(1, 4)
       audio = Audio:new()
       audio:Create("attack.wav")
       GhostSpawn()
       SetPosition()
    end

    function Update()
        if idleflg == true then
            StartAction()
        else
            if once == false then
                local r = GetComponent(this, "RigidBody")
                r:SetVelocity(t2["force"].x*speed, 0, t2["force"].z*speed)
                once=true
            end

            local s = GetComponent(AdHoc.Global.g_NailId, "Script")
            local rotationFlg = s:Get("rotationFlg")
            if rotationFlg == false then
                HitArea()
            else
                local transforms = GetComponent(this, "Transform")
                if transforms.translate.y >= 0.3 then
                    DestroyGhost()
                    DestroyEntity(this)
                end
            end
           
            if moveflg==true then
                Moving()
            end
            
            if isdeletegorst==false then
                GhostFollow()
            end
        end
    end

    function FixedUpdate()
        moveingtime = moveingtime + 0.1
        if idletime > 2 then
            idleflg = false
        else
            idletime = idletime + 0.1
        end
        if particleflg == true then
            destroyparticletime = destroyparticletime+1
            if destroyparticletime > 2 then
                 destroyparticletime = 0
                 for i = 0, nextId - 1 do  
                    DestroyEntity(particleentities[i])
                 end
                particleflg=false
            end
        end
    end

    function StartAction()
        local transforms = GetComponent(this, "Transform")
        transforms.scale.x = scaleSizes[randomScale] * (idletime / 2)
        transforms.scale.y = scaleSizes[randomScale] * (idletime / 2)
        transforms.scale.z = scaleSizes[randomScale] * (idletime / 2)

        local ghostTransform = GetComponent(ghostEntities[0], "Transform")
        ghostTransform.scale.x = transforms.scale.x * 0.3
        ghostTransform.scale.y = transforms.scale.y * 0.3
        ghostTransform.scale.z = transforms.scale.z * 0.3
    end

    function SetPosition()
        --オブジェクトの出現場所を乱数で決定
        local PositionRandom = math.random(0, 3)
        local PositionSpace = math.random(0, range * 2)
    
        --数字によって出現場所を決定
        if PositionRandom==0 then
            t2["linetransform"].x=-range
            t2["linetransform"].y=3
            t2["linetransform"].z=-range+PositionSpace
    
           if PositionSpace<=range then
                t2["CornerPosition"].x=-range
                t2["CornerPosition"].z=range
                t2["CornerPosition2"].x=range
                t2["CornerPosition2"].z=-range
                t2["angleforce"].x=-1
                t2["angleforce"].z=1
            else
                t2["CornerPosition"].x=-range
                t2["CornerPosition"].z=-range
                t2["CornerPosition2"].x=range
                t2["CornerPosition2"].z=range
                t2["angleforce"].x=1
                t2["angleforce"].z=1
            end
    
        
        elseif PositionRandom==1 then
           t2["linetransform"].x=-range+PositionSpace
           t2["linetransform"].y=3
           t2["linetransform"].z=-range
    
           if PositionSpace<=range then
                t2["CornerPosition"].x=range
                t2["CornerPosition"].z=-range
                t2["CornerPosition2"].x=-range
                t2["CornerPosition2"].z=range
                t2["angleforce"].x=1
                t2["angleforce"].z=1
            else
                t2["CornerPosition"].x=-range
                t2["CornerPosition"].z=-range
                t2["CornerPosition2"].x=range
                t2["CornerPosition2"].z=range
                t2["angleforce"].x=1
                t2["angleforce"].z=-1
            end
    
        elseif PositionRandom==2 then
            t2["linetransform"].x=range
            t2["linetransform"].y=3
            t2["linetransform"].z=-range+PositionSpace
    
            if PositionSpace<=range then
                t2["CornerPosition"].x=range
                t2["CornerPosition"].z=range
                t2["CornerPosition2"].x=-range
                t2["CornerPosition2"].z=-range
                t2["angleforce"].x=1
                t2["angleforce"].z=1
            else
                t2["CornerPosition"].x=range
                t2["CornerPosition"].z=-range
                t2["CornerPosition2"].x=-range
                t2["CornerPosition2"].z=range
                t2["angleforce"].x=-1
                t2["angleforce"].z=1
            end
    
        elseif PositionRandom==3 then
           t2["linetransform"].x=-range+PositionSpace
           t2["linetransform"].y=3
           t2["linetransform"].z=range
    
           if PositionSpace<=range then
            t2["CornerPosition"].x=range
            t2["CornerPosition"].z=range
            t2["CornerPosition2"].x=-range
            t2["CornerPosition2"].z=-range
            t2["angleforce"].x=1
            t2["angleforce"].z=-1
        else
            t2["CornerPosition"].x=-range
            t2["CornerPosition"].z=range
            t2["CornerPosition2"].x=range
            t2["CornerPosition2"].z=-range
            t2["angleforce"].x=1
            t2["angleforce"].z=1
        end
        end
    
        --端の座標と今いる座標とのベクトルの向きを出す
        t2["Vector"].x=t2["CornerPosition"].x-t2["linetransform"].x
        t2["Vector"].z=t2["CornerPosition"].z-t2["linetransform"].z
        t2["Vector2"].x=t2["CornerPosition2"].x-t2["linetransform"].x
        t2["Vector2"].z=t2["CornerPosition2"].z-t2["linetransform"].z
    
        --2つのベクトルから角度を求める
        local radian=SecondPointAngle( t2["Vector"].x, t2["Vector"].z, t2["Vector2"].x, t2["Vector2"].z)
    
        --度数方をラジアンに反感
        radian=math.floor(radian)
        --LogMessage( radian)
        radian=math.random(0,radian)
        t2["angle"]=radian/180*math.pi

        -- --進んでいく方向の点を求める
        t2["Movetransform"].x=t2["angleforce"].x*AngleRotationX(t2["CornerPosition"].x,t2["CornerPosition"].z,t2["linetransform"].x,t2["linetransform"].z,t2["angle"])
        t2["Movetransform"].z=t2["angleforce"].z*AngleRotationZ(t2["CornerPosition"].x,t2["CornerPosition"].z,t2["linetransform"].x,t2["linetransform"].z,t2["angle"])
        t2["Movetransform"].x=t2["Movetransform"].x+t2["linetransform"].x
        t2["Movetransform"].z=t2["Movetransform"].z+t2["linetransform"].z
    
        --今いる座標と行く方向の座標からベクトルを求めて正規化する
        t2["force"].x=NormalizeX(t2["Movetransform"].x,t2["Movetransform"].z,t2["linetransform"].x,t2["linetransform"].z)
        t2["force"].z=NormalizeZ(t2["Movetransform"].x,t2["Movetransform"].z,t2["linetransform"].x,t2["linetransform"].z)

        local transforms = GetComponent(this, "Transform")
        local Rigidbody = GetComponent(this, "RigidBody")
        Rigidbody:SetTranslation(t2["linetransform"].x,0.5,t2["linetransform"].z)
        Rigidbody:SetRotation(0,t2["angle"],0)
        local m = GetComponent(this, "Mesh")
        m.toDraw = true
    end

    function GhostSpawn()
        ghostEntities[0] = CreateEntity()
        local ghostTransform = GetComponent(ghostEntities[0], "Transform")
        local t = GetComponent(this, "Transform")

        local meshes = GetComponent(ghostEntities[0], "Mesh")
        meshes:Load("ghost.obj")
        AddComponent(ghostEntities[0], "Texture2D", "ghosttex.tga")
    end

    function GhostFollow()
        local transforms = GetComponent(this, "Transform")
        local ghostTransform = GetComponent(ghostEntities[0], "Transform")
        ghostTransform.translate.x = transforms.translate.x - t2["force"].x * ghostTransform.scale.x * 3
        ghostTransform.translate.y = transforms.translate.y
        ghostTransform.translate.z = transforms.translate.z - t2["force"].z * ghostTransform.scale.x * 3
    end

    function Moving()
        local transforms = GetComponent(this, "Transform")
        transforms.translate.x = transforms.translate.x
        transforms.translate.y = transforms.translate.y+(math.sin(moveingtime)/200)
        transforms.translate.z = transforms.translate.z
        local r = GetComponent(this, "RigidBody")
        r:SetTranslation( transforms.translate.x, transforms.translate.y,  transforms.translate.z )
        
        if transforms.translate.z > endline or transforms.translate.z < -endline or  transforms.translate.x > endline or transforms.translate.x < -endline then
            local s = GetComponent(AdHoc.Global.g_NailId, "Script")
            s:Call("AddObjectCount")
            r:SetTranslation(t2["linetransform"].x- t2["force"].x*speed,0.5,t2["linetransform"].z- t2["force"].z*speed)
            DestroyGhost()
            DestroyEntity(this)
        end
    end

    function DestroyGhost()
        DestroyEntity(ghostEntities[0])
        isdeletegorst =true
    end
]]

function SpawnObject()
    entities[nextId] = CreateEntity()
    local m = GetComponent(entities[nextId], "Mesh")
    m:Load("W_present.obj")
    m.toDraw = false

    AddComponent(entities[nextId], "RigidBody", "Box", "Dynamic")
    AddComponent(entities[nextId], "Script", objScript)
    AddComponent(entities[nextId], "Texture2D", "W_present.tga")

    local r = GetComponent(entities[nextId], "RigidBody")
    r:SetHasGravity(false)
    r:SetTrigger(true)

    nextId = nextId + 1
end

function FixedUpdate()
    if (nextId - 1) == 10 then
        local sq = GetComponent(entities[nextId-1], "Script")
        sq:Call("IsGolden", true)
    end
    time = time + 1
    if time > 60 then
        local s = GetComponent(AdHoc.Global.g_NailId, "Script")
        local rotationFlg = s:Get("rotationFlg")
        local maxobject   = s:Get("maxobject")
    if rotationFlg == false  then
        if maxobject > nextId then
            SpawnObject()
            time = 0
        end
    end
   end
end
