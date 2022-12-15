require "AdHoc"

local this = GetThis()
local ScoreEntities      = {}
local Score = {0,0,0,0,0,0,0,0}


PosX = 0.9
PosY = 0
PosZ = 1.2
RotX = 180
RotY = 0
RotZ = 0
ScaleX = 0.3
ScaleY = 0.3
ScaleZ = 0.3
scoreDistance = 0.15

SerializeField("PosX", PosX)
SerializeField("PosY", PosY)
SerializeField("PosZ", PosZ)
SerializeField("RotX", RotX)
SerializeField("RotY", RotY)
SerializeField("RotZ", RotZ)
SerializeField("ScaleX", ScaleX)
SerializeField("ScaleY", ScaleY)
SerializeField("ScaleZ", ScaleZ)
SerializeField("scoreDistance", scoreDistance)

function AddScore(cnt,score)
    Score[cnt] =  Score[cnt]+score
    for i = 8,1,-1 do
        if Score[i]>9 then
            Score[i-1] = Score[i-1]+1
            Score[i] = Score[i] - 10
        end
    end
    for i = 1,8 do
        local e                   = ScoreEntities[i]
        local m = GetComponent(e, "Mesh")
        if Score[i] == 0 then
            m:Load("0.obj")
        elseif Score[i] == 1 then
            m:Load("1.obj")
        elseif Score[i] == 2 then
            m:Load("2.obj")
        elseif Score[i] == 3 then
            m:Load("3.obj")
        elseif Score[i] == 4 then
            m:Load("4.obj")
        elseif Score[i] == 5 then
            m:Load("5.obj")
        elseif Score[i] == 6 then
            m:Load("6.obj")
        elseif Score[i] == 7 then
            m:Load("7.obj")
        elseif Score[i] == 8 then
            m:Load("8.obj")
        elseif Score[i] == 9 then
            m:Load("9.obj")
        end
    end

end


function Start()
    for i = 1,8 do
        Score[i] = 0
        ScoreEntities[i]      = CreateEntity()
        local e               = ScoreEntities[i]
        local m = GetComponent(e, "Mesh")
        m:Load("0.obj")
        local t  = GetComponent(e, "Transform")

        t.translate.x = PosX+scoreDistance*i
        t.translate.y = PosY
        t.translate.z = PosZ

        t.rotation.x = math.rad(RotX)
        t.rotation.y = math.rad(RotY)
        t.rotation.z = math.rad(RotZ)

        t.scale.x     = ScaleX
        t.scale.y     = ScaleY
        t.scale.z     = ScaleZ
    end
end

function Update()
    -- for i = 1,8 do
    --     local e                   = ScoreEntities[i]
        
    --     local t  = GetComponent(e, "Transform")

    --     t.translate.x = PosX+scoreDistance*i
    --     t.translate.y = PosY
    --     t.translate.z = PosZ

    --     t.rotation.x = math.rad(RotX)
    --     t.rotation.y = math.rad(RotY)
    --     t.rotation.z = math.rad(RotZ)

    --     t.scale.x     = ScaleX
    --     t.scale.y     = ScaleY
    --     t.scale.z     = ScaleZ
    -- end
end
