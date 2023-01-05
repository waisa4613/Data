require "AdHoc"

local this = GetThis()

local camera = GetComponent(this,"Camera3D")

local posOrigin = Vector3D:new()
posOrigin.x = camera.eyePosition.x
posOrigin.y = camera.eyePosition.y
posOrigin.z = camera.eyePosition.z

local focusOrigin = Vector3D:new()
focusOrigin.x = camera.focusPosition.x
focusOrigin.y = camera.focusPosition.y
focusOrigin.z = camera.focusPosition.z

-- カメラを揺らす演出
local speedShake = 10
local YShake = 1        -- 減衰させながら使用
local YShakeMinus = 0.8
local YThresholdStop = 3 / 5
local isGoingUp = true
local YOrigin
local didShakeStart = false
local isShakeDone = false

local YThisFrame = 0

-- カメラを移動させるための変数
local posCameraEnd = Vector3D:new()
posCameraEnd.x = 0
posCameraEnd.y = 70 
posCameraEnd.z = -1

local posFocusEnd = Vector3D:new()
posFocusEnd.x = 0
posFocusEnd.y = 0
posFocusEnd.z = 0

function Start()
    YOrigin = camera.eyePosition.y
end

-- 経過時間と制限時間の情報をもつタイマー
Timer = {}
Timer.New = function(argTime)
    local obj = {}
    obj.past = 0
    if argTime == nil then
        obj.till = 0
    else
        obj.till = argTime
    end
                -- 時間を加算する
    obj.Watch = function(self)
                    self.past = self.past + DeltaTime()
                end
                -- 時間が経過していたらtrue、していなければfalseを返す
    obj.IfOver = function(self)
                    if self.past >= self.till then
                        return true
                    end
                    return false
                end
                -- 時間がオーバーする分を考慮
    obj.Reset = function(self)
                    self.past = self.past - self.till
                end
                -- 完全にゼロからリセット
    obj.ResetTo0 = function(self)
                    self.past = 0
                end
    return obj
end

-- 数値の線形補間
local function LinerIP_num(argOri,argTar,argTimeEnd,argTimePast)
    local ratio = argTimePast / argTimeEnd
    if ratio > 1 then
        ratio = 1
    end
    return argOri + (argTar - argOri) * ratio
end

-- 三次元ベクトルの線形補間
local function LinerIP_vec3(vecOri,vecTar,argTimeEnd,argTimePast)
    local tempVec3 = Vector3D:new()
    tempVec3.x = LinerIP_num(vecOri.x,vecTar.x,argTimeEnd,argTimePast)
    tempVec3.y = LinerIP_num(vecOri.y,vecTar.y,argTimeEnd,argTimePast)
    tempVec3.z = LinerIP_num(vecOri.z,vecTar.z,argTimeEnd,argTimePast)
    return tempVec3
end

function StartShaking()
    didShakeStart = true
end

local function Shake()
    if isShakeDone == true then
        YThisFrame = 0
        return    
    end
    -- このフレームの移動量
    YThisFrame = speedShake * DeltaTime()

    if isGoingUp == true then    -- 上
        camera.eyePosition.y = camera.eyePosition.y + YThisFrame

        if camera.eyePosition.y >= YOrigin + YShake then
            camera.eyePosition.y = YOrigin + YShake
            isGoingUp = false
            YShake = YShake * YShakeMinus
        end
    else                            -- 下
        camera.eyePosition.y = camera.eyePosition.y - YThisFrame

        if camera.eyePosition.y <= YOrigin - YShake then
            camera.eyePosition.y = YOrigin - YShake
            isGoingUp = true
            YShake = YShake * YShakeMinus
        end

        YThisFrame = YThisFrame * -1
    end

    -- 停止処理
    if YShake <= YThresholdStop then
        camera.eyePosition.y = YOrigin
        isShakeDone = true
    end
end

-- カメラを直上に移動させる処理
local didStartMoving = false
local isMovingDone = false

local timerMove = Timer.New(1.2)

function SetFinalPos(argX,argY,argZ)
    posCameraEnd.x = argX
    posCameraEnd.y = argY
    posCameraEnd.z = argZ
end

function StartMoving()
    didStartMoving = true
end

function KnowIsMovingDone()
    return isMovingDone
end

local function Moving()
    if isMovingDone == true then
        return
    end
    timerMove:Watch()

    camera.eyePosition = LinerIP_vec3(posOrigin,posCameraEnd,timerMove.till,timerMove.past)
    camera.focusPosition = LinerIP_vec3(focusOrigin,posFocusEnd,timerMove.till,timerMove.past)

    if timerMove:IfOver() == true then
        camera.eyePosition = posCameraEnd
        camera.focusPosition = posFocusEnd

        isMovingDone = true
    end
end

function Update()
    if didShakeStart == true then
        Shake()
    end
    if didStartMoving == true then
        Moving()
    end

    local transFloor = GetComponent(FindEntity(AdHoc.Global.Ar_texts.nameFloor),"Transform")

    camera.focusPosition.x = transFloor.translate.x
    camera.focusPosition.y = transFloor.translate.y + YThisFrame
    camera.focusPosition.z = transFloor.translate.z
end
