require "AdHoc"

local this = GetThis()
local spawnTimer = 0
local nextID             = 0
local EnemyEntities       = {}
local EnemyMoving       = {}
local entityToIndex     = {}
local entityTime = {}
local entityLife = {}
local validEntity       = {}
local spawnAngle        = 30
local scaleSizes        = { 0.03, 0.05, 0.07 }
local distances         = { 0.15, 0.2, 0.25 }
local startingPositions = { "Up", "Down", "Left", "Right" }
local speed             = 0.2
local fadeInSpeed       = 0.2
local RayForward = Vector3D:new()
RayForward.x = 0
RayForward.y = -1
RayForward.z = 0
local RayPos = Vector3D:new()
RayPos.x = -1
RayPos.y = 0.05
RayPos.z = 0
local manager 
local managerscript

function RandomFloat(lower, greater)
    return lower + math.random()  * (greater - lower);
end

function HitEnemy(e)
    LogMessage("bbb")
    entityLife[e]= entityLife[e]-1
    if entityLife[e]==0 then
        validEntity[e]        = false
        DestroyEntity(e)
    end
end

function Start()
  manager = FindEntity("Scene Manager")
  managerscript = GetComponent(manager, "Script")
end

function SpawnEnemy()
    EnemyEntities[nextID]   = CreateEntity()
    local e               = EnemyEntities[nextID]
    validEntity[e]        = true     
    entityToIndex[e]      = nextID
    EnemyMoving[e]    = false
    entityTime[e] = 0
    entityLife[e] = 3
    -- Mesh
    local m = GetComponent(e, "Mesh")
    m:Load("gorst2.obj")

    -- Texture
    AddComponent(e, "Texture2D", "giftBox.tga")

    local t  = GetComponent(e, "Transform")

    local position  = startingPositions[math.random(1, 4)]
    local randomPos = RandomFloat(-1, 1)
    local low       = -spawnAngle
    local high      = spawnAngle

    if position == "Up" then
      t.translate.x = randomPos
      t.translate.z = 1
      t.rotation.y  = math.rad(180.0)
      high = high + (high * randomPos)
      low  = low - (low * randomPos)
    elseif position == "Down" then
      t.translate.x = randomPos
      t.translate.z = -1
      high  = high - (high * randomPos)
      low   = low + (low * randomPos)
    elseif position == "Left" then
      t.translate.x = -1
      t.translate.z = randomPos
      t.rotation.y  = math.rad(90.0)
      high = high + (high * randomPos)
      low  = low - (low* randomPos)
    elseif position == "Right" then
      t.translate.x = 1
      t.translate.z = randomPos
      t.rotation.y  = math.rad(-90.0)
      high  = high - (high * randomPos)
      low   = low + (low * randomPos)
    end

    -- Set translation
    t.translate.y = 0.2

    -- Set scale
    local randomScale      = math.random(1, 3)
    --EnemyEntities[nextID]      = scaleSizes[randomScale]
    t.scale.x = 0.04
    t.scale.y = 0.04
    t.scale.z = 0.04

    -- Set direction
    t.rotation.y = t.rotation.y + math.rad(RandomFloat(low, high))

    -- Collider
    AddComponent(e, "RigidBody", "ConvexMesh", "Dynamic")
    local r = GetComponent(e, "RigidBody")
    r:SetHasGravity(false)
    r:SetTrigger(true)
    r:SetKinematic(false)

    r.scale.x = t.scale.x
    r.scale.y = t.scale.y
    r.scale.z = t.scale.z
    r:UpdateGeometry()

    -- local forward     = t:GetForward()
    -- local randomSpeed = RandomFloat(1, 2)
    -- r:SetVelocity(forward.x * speed * randomSpeed, 0, forward.z * speed * randomSpeed)
end

function SpawnSet()
    --if AdHoc.Global.Start>=2 then
    SpawnEnemy()
    --SpawnHitBox()
    nextID = nextID + 1
   -- end
end

function RayHIt()
    for i = 0, nextID - 1 do
      -- Update box
      local e = EnemyEntities[i]
        if validEntity[e] == true then
            local t  = GetComponent(e, "Transform")
          
            t.translate.y=t.translate.y-0.1
            
            local et = Raycast(t.translate,RayForward, 2)
            t.translate.y=t.translate.y+0.1
            

              if et ~= 0 then
                LogMessage("aaa")
                DestroyEntity(et)
              end
        end
    end
end

function Moving()
    for i = 0, nextID - 1 do
      -- Update box
      local e = EnemyEntities[i]
        if validEntity[e] == true  then
          if EnemyMoving[e]  == false then
            entityTime[e] = entityTime[e]+10 * DeltaTime()
            if entityTime[e]>20 then
                local t  = GetComponent(e, "Transform")
                local r = GetComponent(e, "RigidBody")
                local forward     = t:GetForward()
                local randomSpeed = RandomFloat(1, 2)
                r:SetVelocity(forward.x * speed * randomSpeed, 0, forward.z * speed * randomSpeed)
                EnemyMoving[e]  = true
            end
          elseif managerscript:Call("StopSpawn") then
            local t  = GetComponent(e, "Transform")
            local r = GetComponent(e, "RigidBody")
            if t.scale.x > 0 then
              t.scale.x = t.scale.x - (fadeInSpeed / 2) * DeltaTime()
              t.scale.y = t.scale.y - (fadeInSpeed / 2) * DeltaTime()
              t.scale.z = t.scale.z - (fadeInSpeed / 2) * DeltaTime()
              r.scale.x = t.scale.x
            end
            r.scale.y = t.scale.y
            r.scale.z = t.scale.z
          end
        end
    end
end

function Update()
 
  if managerscript:Call("StopSpawn") then
  else
    spawnTimer = spawnTimer + 10 * DeltaTime()
      if(spawnTimer > 200) then
        SpawnSet()
        spawnTimer = 0
      end
      RayHIt()
  end
      
     
end

function FixedUpdate()
    Moving()
end


