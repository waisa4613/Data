require "AdHoc"

local this = GetThis()
local input = GetInput()

function Start()

end

local didOneFramePass = false

function Update()
    local scrOpeningHouse = GetComponent(FindEntity("manager_openingHouse"),"Script")
    local scrCamera = GetComponent(FindEntity("Runtime Camera"),"Script")

    scrOpeningHouse:Call("CreateWalls")                                 -- 壁と天井を生成（Startの中では実行出来ない）

    if didOneFramePass == true then
        if input:GetKeyDown(AdHoc.Key.enter) then
            scrOpeningHouse:Call("StartHouseFall")                      -- 家の落下を開始
        end        
        if scrOpeningHouse:Call("IfHouseFallingIsDone") == true then    -- 家が落下し終わったか判定
            scrCamera:Call("StartShaking")                              -- カメラを揺らす処理
        end
        if scrOpeningHouse:Call("KnowIfOpeningIsDone") == true then     -- 家の展開が終わったか判定
            scrCamera:Call("StartMoving")                               -- カメラをゲーム開始時の位置まで移動させる
        end
    end

    didOneFramePass = true
end
