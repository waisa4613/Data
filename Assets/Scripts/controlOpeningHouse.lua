require "AdHoc"

local this = GetThis()

function Start()

end

local didOneFramePass = false
local didOneFramePass_forEnd = false

function Update()
    local scrOpeningHouse = GetComponent(FindEntity(AdHoc.Global.Ar_texts.nameOpeningHouse),"Script")
    local scrStagingCamera = GetComponent(FindEntity("cameraStaging"),"Script")

    ------ 最初の演出とカメラ移動まで ------
    if didOneFramePass == false then
    scrOpeningHouse:Call("CreateWalls")                                 -- 壁と天井を生成（Startの中では実行出来ない）

        local runCamera = GetComponent(FindEntity("Runtime Camera"),"Camera3D")
        scrStagingCamera:Call("SetFinalPos",runCamera.eyePosition.x,runCamera.eyePosition.y,runCamera.eyePosition.z)
    else
        scrOpeningHouse:Call("StartHouseFall")                          -- 家の落下を開始

        if scrOpeningHouse:Call("IfHouseFallingIsDone") == true then    -- 家が落下し終わったか判定
    scrStagingCamera:Call("StartShaking")                               -- カメラを揺らす処理
        end
        if scrOpeningHouse:Call("KnowIfOpeningIsDone") == true then     -- 家の展開が終わったか判定
    scrStagingCamera:Call("StartMoving")                                -- カメラをゲーム開始時の位置まで移動させる
        end
        if scrStagingCamera:Call("KnowIsMovingDone") == true then
            GetComponent(FindEntity("cameraStaging"),"Camera3D").isGameCamera = false
            GetComponent(FindEntity("Runtime Camera"),"Camera3D").isGameCamera = true
        end
    end

    didOneFramePass = true

    -- ------ ゲーム終了後の演出 ------
    -- local sm = FindEntity("Scene Manager")
    -- if sm ~= nil then
    --     -- 家具の生成が終わったか判定
    --     if GetComponent(sm,"Script"):Call("StopSpawn") == true then
    --         local scrSetupHouse = GetComponent(FindEntity("manager_setupHouse"),"Script")

    --         LogMessage("Working")

    --         if didOneFramePass_forEnd == false then
    --             -- 家を生成する
    --             scrSetupHouse:Call("CreateWalls_first")
    --             scrSetupHouse:Call("CreateDoor")
                
    --             didOneFramePass_forEnd = true
    --         else
    --             -- 回転処理を実行

    --         end
    --     end
    -- end


end
