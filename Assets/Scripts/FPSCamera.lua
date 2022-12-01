require "AdHoc"

local this      = GetThis()
local input     = GetInput()

local nextScene = "End.scene" -- 移動先シーンの名前

local speedSlide = 40 -- 1秒間に視線を回す角度
local speedMove  = 1 -- 1秒間に移動する距離
local check      = 0
local time       = 0
local timechange = 60 -- ボタンを押してから遷移するまでの時間（単位：秒）
local count      = true
local countTime  = 0
local shaketime  = 0
local counter    = true
local once       = false

shake = 0

function Move()
    local camera    = GetComponent(this, "Camera3D")
    if once == false then
        camera.eyePosition.x = 0
        camera.eyePosition.y = 0.5
        camera.eyePosition.z = -1
        camera.focusPosition.x = 0
        camera.focusPosition.y = 0.5
        camera.focusPosition.z = 1
        once=true
    end

    local d = 0

    if input:GetKey(AdHoc.Key.q) == true then
        d = d + 1
    end
    if input:GetKey(AdHoc.Key.e) == true then
        d = d - 1
    end

    if d == 0 then -- 何もしない
    else
        -- 移動角度を求める(ラジアン度にする)
        local angleSlide = speedSlide * d * math.pi / 180

        -- 現在の視点の角度を求める
        local vecAngle = Vector2D:new()
        vecAngle.x = camera.focusPosition.x - camera.eyePosition.x
        vecAngle.y = camera.focusPosition.z - camera.eyePosition.z

        local angleLookingAt = math.atan(vecAngle.y,vecAngle.x)

        local angleWillingToLook = angleLookingAt + angleSlide * DeltaTime()

        -- focusPositionを移動させる
        camera.focusPosition.x = camera.eyePosition.x + math.cos(angleWillingToLook)
        camera.focusPosition.z = camera.eyePosition.z + math.sin(angleWillingToLook)
    end


    local x = 0
    local z = 0
    local put = false

    -- キーの入力処理
    if input:GetKey(AdHoc.Key.d) == true then
        put = true
        x = x + 1 * DeltaTime()
    end
    if input:GetKey(AdHoc.Key.a) == true then
        put = true
        x = x - 1 * DeltaTime()
    end
    if input:GetKey(AdHoc.Key.w) == true then
        put = true
        z = z + 1 * DeltaTime()
    end
    if input:GetKey(AdHoc.Key.s) == true then
        put = true
        z = z - 1 * DeltaTime()
    end

    if put == true then
        -- 移動角度求める
        local angle = math.atan(z, x)

        -- 現在の視点の角度を求める
        local vecAngle = Vector2D:new()
        vecAngle.x = camera.focusPosition.x - camera.eyePosition.x
        vecAngle.y = camera.focusPosition.z - camera.eyePosition.z

        local angleLookingAt = math.atan(vecAngle.y,vecAngle.x)
        angleLookingAt = angleLookingAt - 90 * math.pi / 180-- 調整

        local angleMove = angle + angleLookingAt -- 最終的な移動方向

        -- 移動処理
        camera.eyePosition.x = camera.eyePosition.x + speedMove * math.cos(angleMove) * DeltaTime()
        camera.eyePosition.z = camera.eyePosition.z + speedMove * math.sin(angleMove) * DeltaTime()

        -- 合わせて注目点も移動
        camera.focusPosition.x = camera.focusPosition.x + speedMove * math.cos(angleMove) * DeltaTime()
        camera.focusPosition.z = camera.focusPosition.z + speedMove * math.sin(angleMove) * DeltaTime()
    end
end

function Update()
    local e = FindEntity("Scene Manager")
    if e ~= nil then
        local s = GetComponent(e, "Script")
        if s:Get("changeToFpsModeAvailable") == true then
            Move()
            if input:GetKeyUp(AdHoc.Key.enter) then
                LoadScene(nextScene)
            end
        else
            local camera    = GetComponent(this, "Camera3D")
            if shake == 1 then
                camera.eyePosition.x = 0 + math.sin(shaketime) / 10
                camera.eyePosition.y = 3 + math.sin(shaketime) / 10
                camera.eyePosition.z = -0.10
            else
                camera.eyePosition.x = 0
                camera.eyePosition.y = 3
                camera.eyePosition.z = -0.10
            end
        end
    end
end

function FixedUpdate()
    if shake == 1 then
        shaketime = shaketime + 1
        if shaketime > 3 then
            shaketime = 0
            shake = 0
        end
    end
end
