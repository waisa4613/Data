require "AdHoc"

-- local
local nextID            = 0
local boxEntities       = {}
local entityToIndex     = {}
local validEntity       = {}
local boxScales         = {}
local boxIsShiny        = {}
local shinyBoxTimer     = {}
local ghostEntities     = {}
local scaleSizes        = { 0.075, 0.1, 0.125 }
local distances         = { 0.15, 0.2, 0.25 }
local startingPositions = { "Up", "Down", "Left", "Right" }
local speed             = 0.3
local sin               = 0
local sinScale          = 150
local ghostScale        = 0.3
local ghostDistances    = {}
local fadeInSpeed       = 0.2
local spawnTimer        = 0
local spawnAngle        = 30
local shinyChance       = 800
local bigMeshName       = {"N_bed.obj","N_sofa.obj"}
local mediumMeshName    = {"dai.obj"}--,"N_chair.obj","N_chest.obj"
local smallMeshName     = {"N_tv.obj"}
local bigMeshTex        = {"N_bed.tga","N_sofa.tga"}
local mediumMeshTex     = {"N_table.tga"}--,"N_chair.tga","N_chest.tga"
local smallMeshTex      = {"N_tv.tga"}

local openingEntities   = {}
local openingBoxTimers  = {}
local openingBoxesCount = 0

-- global
maxModelCount            = 100
maxObjects               = 6
maxObjectsCount          = 0
changeToFpsModeAvailable = false

function RandomFloat(lower, greater)
    return lower + math.random()  * (greater - lower);
end

function StopSpawn()
  if nextID >= maxModelCount or maxObjectsCount > maxObjects then
    return true
  else
    return false
  end
end

function OpenBox(e)
  openingEntities[openingBoxesCount] = e
  openingBoxesCount                  = openingBoxesCount + 1
  openingBoxTimers[e]                = 50

  local r = GetComponent(e, "RigidBody")
  local t = GetComponent(e,"Transform")
  t.translate.x =  t.translate.x
  t.translate.y = 0.2
  t.translate.z =  t.translate.z
  r:SetVelocity(0, 0, 0)
  r:SetPosition(t.translate.x, t.translate.y, t.translate.z)
end

function InvalidEntity(e)
  if validEntity[e] then
  validEntity[e] = false

  maxObjectsCount = maxObjectsCount + 1

  -- Stop drawing ghost
  local ghostMesh  = GetComponent(ghostEntities[entityToIndex[e]], "Mesh")
  ghostMesh.toDraw = false

  local boxMesh = GetComponent(e, "Mesh")
  local randomMeshID = 0
  local selectMesh 
  local selectMeshTex 
  
  if boxScales[entityToIndex[e]] == scaleSizes[1] then
    randomMeshID = math.random(1, #smallMeshName)
    selectMesh = smallMeshName[randomMeshID]
    selectMeshTex = smallMeshTex[randomMeshID]

  elseif boxScales[entityToIndex[e]] == scaleSizes[2] then
    randomMeshID = math.random(1, #mediumMeshName)
    selectMesh = mediumMeshName[randomMeshID]
    selectMeshTex = mediumMeshTex[randomMeshID]

  elseif boxScales[entityToIndex[e]] == scaleSizes[3] then
    randomMeshID = math.random(1, #bigMeshName)
    selectMesh = bigMeshName[randomMeshID]
    selectMeshTex = bigMeshTex[randomMeshID]
  end

  boxMesh:Load(selectMesh)
  RemoveComponent(e, "Texture2D")
  AddComponent(e,"Texture2D",selectMeshTex)
  
  local boxTransform = GetComponent(e, "Transform")
  boxTransform.scale.x = 0.06
  boxTransform.scale.y = 0.06
  boxTransform.scale.z = 0.06

  local boxRigidBody = GetComponent(e, "RigidBody")
  
  local vec  = Vector3D:new()
  vec.x = boxRigidBody.translate.x
  vec.y = boxRigidBody.translate.y
  vec.z = boxRigidBody.translate.z

  
  RemoveComponent(e, "RigidBody")

  AddComponent(e, "RigidBody", "ConvexMesh", "Dyanmic")
  local r = GetComponent(e, "RigidBody")
  r:SetHasGravity(false)
  r:SetTrigger(true)
  r:SetKinematic(false)
  r:SetPosition(vec.x, 0, vec.z)
  r:UpdateGeometry()

  local boxMaterial = GetComponent(e, "Material")
  boxMaterial.albedo.x = 1
  boxMaterial.albedo.y = 1
  boxMaterial.albedo.z = 1

  --ScoreAdd
  end
end

function SpawnBox()
    boxEntities[nextID]   = CreateEntity()
    boxIsShiny[nextID]    = false
    shinyBoxTimer[nextID] = 0
    local e               = boxEntities[nextID]
    validEntity[e]        = true     
    entityToIndex[e]      = nextID
    -- Mesh
    local m = GetComponent(e, "Mesh")
    m:Load("giftBox.obj")

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
    t.translate.y = 0.5

    -- Set scale
    local randomScale      = math.random(1, 3)
    boxScales[nextID]      = scaleSizes[randomScale]
    ghostDistances[nextID] = distances[randomScale];
    t.scale.x = 0
    t.scale.y = 0
    t.scale.z = 0

    -- Set direction
    t.rotation.y = t.rotation.y + math.rad(RandomFloat(low, high))

    -- Collider
    AddComponent(e, "RigidBody", "Box", "Dynamic")
    local r = GetComponent(e, "RigidBody")
    r:SetHasGravity(false)
    r:SetTrigger(true)
    r:SetKinematic(false)

    local forward     = t:GetForward()
    local randomSpeed = RandomFloat(1, 2)
    r:SetVelocity(forward.x * speed * randomSpeed, 0, forward.z * speed * randomSpeed)
end

function SpawnGhost()
  ghostEntities[nextID] = CreateEntity()
  local e               = ghostEntities[nextID]

  -- Mesh
  local m = GetComponent(e, "Mesh")
  m:Load("ghost.obj")

  -- Texture
  AddComponent(e, "Texture2D", "ghost.tga")

  local boxTransform    = GetComponent(boxEntities[nextID], "Transform")
  local ghostTransform  = GetComponent(e, "Transform")

  -- Set translation
  ghostTransform.translate.x = boxTransform.translate.x
  ghostTransform.translate.y = boxTransform.translate.y
  ghostTransform.translate.z = boxTransform.translate.z

  -- Set scale
  ghostTransform.scale.x = 0
  ghostTransform.scale.y = 0
  ghostTransform.scale.z = 0

  -- Set direction
  ghostTransform.rotation.y = boxTransform.rotation.y

  local boxForward = boxTransform:GetForward()
  ghostTransform.translate.x = boxTransform.translate.x
  ghostTransform.translate.y = boxTransform.translate.y
  ghostTransform.translate.z = boxTransform.translate.z
end

function SpawnSet()
  if AdHoc.Global.Start>=2 then
  SpawnBox()
  SpawnGhost()
  nextID = nextID + 1
  end
end

function UpdateSets(fadeIn)
  for i = 0, nextID - 1 do
    -- Update box
    local e = boxEntities[i]

    if validEntity[e] == true then

      local t = GetComponent(e, "Transform")
      local r = GetComponent(e, "RigidBody")

      local y = t.translate.y + (math.sin(sin) / sinScale)
      r:SetTranslation(t.translate.x, y, t.translate.z)

      local isShiny = math.random(0, shinyChance)
      if isShiny == shinyChance and boxIsShiny[i] == false then
      boxIsShiny[i] = true
      end
      -- Update ghost
      local ghostTransform  = GetComponent(ghostEntities[i], "Transform")
      local boxForward      = t:GetForward()

      ghostTransform.translate.x = t.translate.x - ghostDistances[i] * boxForward.x
      ghostTransform.translate.y = y
      ghostTransform.translate.z = t.translate.z - ghostDistances[i] * boxForward.z

      -- Fade in
      if fadeIn then
        if t.scale.x <= boxScales[i] then
          t.scale.x = t.scale.x + fadeInSpeed * DeltaTime()
          t.scale.y = t.scale.y + fadeInSpeed * DeltaTime()
          t.scale.z = t.scale.z + fadeInSpeed * DeltaTime()
        end
      else
        if t.scale.x > 0 then
          t.scale.x = t.scale.x - (fadeInSpeed / 2) * DeltaTime()
          t.scale.y = t.scale.y - (fadeInSpeed / 2) * DeltaTime()
          t.scale.z = t.scale.z - (fadeInSpeed / 2) * DeltaTime()
        end
      end

        r.scale.x = t.scale.x
        r.scale.y = t.scale.y
        r.scale.z = t.scale.z
        r:UpdateGeometry()

        ghostTransform.scale.x = t.scale.x * ghostScale
        ghostTransform.scale.y = t.scale.y * ghostScale
        ghostTransform.scale.z = t.scale.z * ghostScale
     

      -- Shiny box
      if boxIsShiny[i] == true then
        local m = GetComponent(ghostEntities[i], "Material")
        m.albedo.x = 5
        m.albedo.y = 5
        m.albedo.z = 3
        shinyBoxTimer[i] = shinyBoxTimer[i] + 1.0 * DeltaTime()
        if shinyBoxTimer[i] > 2.5 then
          shinyBoxTimer[i] = 0
          boxIsShiny[i]    = false
        end
      else
        local m = GetComponent(ghostEntities[i], "Material")
        m.albedo.x = 1
        m.albedo.y = 1
        m.albedo.z = 1
      end
    end
  end
end

function Update()
  local fadeIn = true
  if not StopSpawn() then
    spawnTimer = spawnTimer + 10 * DeltaTime()
    if(spawnTimer > 10) then
      SpawnSet()
      spawnTimer = 0
    end
  else
    changeToFpsModeAvailable = true
    fadeIn = false
  end
  UpdateSets(fadeIn)
end

function OpeningBoxes()
    for i = 0, openingBoxesCount - 1 do
      openingBoxTimers[openingEntities[i]] = openingBoxTimers[openingEntities[i]] - 1
      if openingBoxTimers[openingEntities[i]] > 0 and validEntity[openingEntities[i]] then
        local m = GetComponent(openingEntities[i], "Material")
        m.albedo.x = m.albedo.x + 1.0
        m.albedo.y = m.albedo.y + 1.0
        m.albedo.z = m.albedo.z + 1.0
      else
          InvalidEntity(openingEntities[i])
      end
    end
end

function FixedUpdate()
  sin = sin + 0.1
  OpeningBoxes()
end
