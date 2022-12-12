require "AdHoc"

local this  = GetThis()
local input = GetInput() 

local nextID            = 0
local nailEntities      = {}
local entityToIndex     = {}
local entityTime        = {}
local entityAnimation   = {}

fallTime               = 2
LifeLength             = 30
SerializeField("fallTime", fallTime)
SerializeField("LifeLength", LifeLength)

function NailSpawn(_t)
    nailEntities[nextID]      = CreateEntity()
    local e                   = nailEntities[nextID]
    entityToIndex[e]          = nextID
    entityTime[e]        = 0
    entityAnimation[e]   = true

    local m = GetComponent(e, "Mesh")
    m:Load("Nail.obj")

    local t  = GetComponent(e, "Transform")
    
    t.translate.x = _t.translate.x
    t.translate.y = _t.translate.y
    t.translate.z = _t.translate.z

    t.scale.x     = _t.scale.x
    t.scale.y     = _t.scale.y
    t.scale.z     = _t.scale.z
    nextID = nextID + 1
end

function Update()
    for i = 0, nextID - 1 do
        local e = nailEntities[i]
        if entityAnimation[e] == true then
            local t  = GetComponent(e, "Transform")
            t.translate.y = t.translate.y- (t.translate.y/fallTime)
        end
    end
end

function FixedUpdate()
    for i = 0, nextID - 1 do
        local e = nailEntities[i]
        if entityAnimation[e] == true then
            entityTime[e]=entityTime[e]+ 1
            if entityTime[e] > LifeLength then
                entityAnimation[e] = false
            end
        else
            local m = GetComponent(e, "Mesh")
            m.toDraw = false
        end
    end

end
