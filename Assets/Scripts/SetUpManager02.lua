
-- 先に壁四つだけ作って、天井とドアは最後に着けるバージョン     --
-- 自分自身をグローバルに登録しておいて関数は外部から呼び出す   --

require "AdHoc"

local this = GetThis()

-- 自分自身をグローバルに登録
if AdHoc.Global.Ar_objects == nil then
    AdHoc.Global.Ar_objects = {}
end
AdHoc.Global.Ar_objects.setupManager = this

-- フラグ
local isCreated = false
local isSetupDone = false

-- グローバル関数に登録して外部から読みだせるようにする
if AdHoc.Global.Fs_SetUp == nil then
    AdHoc.Global.Fs_SetUp = {}      -- 配列にまとめて関数をデリゲーションする
end

------ 普通の壁関係 ------
-- 壁のエンティティ
local walls = {}

-- 壁のtransformに関する情報
local hWall = 0.8    -- 壁の高さ
local wWall = 0    -- 壁の幅（floorの大きさに合わせる）
local zWall = 0.1   -- 壁の太さ

-- 壁回転実行関数の配列
if AdHoc.Global.WallFs02 == nil then
    AdHoc.Global.WallFs02 = {}
end

-- 壁にアタッチするスクリプト
local scrRotate = [[
    require "AdHoc"

    local this = GetThis()
    local trans

    -- フラグ
    local doRotate = false
    local ifRotateIsDone = false

    -- 時間関係の変数
    local timeTillRotateIsDone = 0.3
    local timePast = 0

    -- 関数 DoRotate 用の変数
    local angleTarget = 0
    local angleOrigin = 0   -- ラジアン度だから注意

    -- 関数 DoSinCos 用の変数
    local angleSinCosTarget = 90
    local angleSinCosOrigin = 0
    local angleYSinCos = 0
    local disSinCos
    local posOrigin = Vector3D:new()
    local posCenter = Vector3D:new()

    -- デバッグ用
    local debugNum = 0

    -- 問題     何故か4つ目の壁しか回転しない
    -- 原因判明 全部が同じtransformにアクセスしてしまっている（4つ目の壁がtransを上書きしている）
    -- 解決策   Updateの中でその都度Transformを取得する

    function Start()
        ------ rotationいじりの情報獲得 ------
        trans = GetComponent(this,"Transform")

        angleOrigin = trans.rotation.x
        angleTarget = math.rad(angleTarget)             -- 角度をラジアン度に変換

        posOrigin.x = trans.translate.x
        posOrigin.y = trans.translate.y
        posOrigin.z = trans.translate.z

        ------ transformいじりの情報獲得 ------
        -- 回転の中心を求める
        disSinCos = trans.scale.y

        posCenter.x = trans.translate.x                 -- translateの値をコピー
        posCenter.y = trans.translate.y
        posCenter.z = trans.translate.z

        local angleTemp = -1 * trans.rotation.y + math.rad(90)
        posCenter.x = trans.translate.x + disSinCos * math.cos(angleTemp)
        posCenter.z = trans.translate.z + disSinCos * math.sin(angleTemp)

        angleYSinCos = angleTemp + math.rad(180)        -- xyの回転方向
        
        angleSinCosTarget = math.rad(angleSinCosTarget) -- 角度をラジアン度に変換
        angleSinCosOrigin = math.rad(angleSinCosOrigin)
    end

    local function DoRotate()
        trans = GetComponent(this,"Transform")

        trans.rotation.x = angleOrigin + (angleTarget - angleOrigin) * (timePast / timeTillRotateIsDone)

        if timePast >= timeTillRotateIsDone then
            trans.rotation.x = angleTarget
            doRotate = false
            ifRotateIsDone = true
        end
    end

    local function DoSinCos()
        trans = GetComponent(this,"Transform")

        -- xyz全部いじる必要があるな
        -- yxでまず横から計算 → xの値を角度でぐるっと回してsincos計算で行けるか？

        -- y方向を計算
        local angleTemp = angleSinCosOrigin + (angleSinCosTarget - angleSinCosOrigin) * (timePast / timeTillRotateIsDone)
        trans.translate.y = posCenter.y + disSinCos * math.sin(angleTemp)

        -- xy以外の計算
        local disTemp = disSinCos * math.cos(angleTemp)

        trans.translate.x = posCenter.x + disTemp * math.cos(angleYSinCos)
        trans.translate.z = posCenter.z + disTemp * math.sin(angleYSinCos)

        if timePast >= timeTillRotateIsDone then
            trans.translate.y = posCenter.y + disSinCos
            trans.translate.x = posCenter.x
            trans.translate.z = posCenter.z
        end
    end

    function Update()
        if doRotate == true then
            timePast = timePast + DeltaTime()

            DoRotate()
            DoSinCos()
        end
    end

    function StartRotate()
        doRotate = true
    end

    function KnowIfRotateIsDone()
        return ifRotateIsDone
    end

    -- 関数群みたいにできるのかテスト（実現できれば楽そう）
    AdHoc.Global.WallFs02[#AdHoc.Global.WallFs02 + 1] = {}
    AdHoc.Global.WallFs02[#AdHoc.Global.WallFs02].StartRotate = StartRotate
    AdHoc.Global.WallFs02[#AdHoc.Global.WallFs02].KnowIfRotateIsDone = KnowIfRotateIsDone

    debugNum = #AdHoc.Global.WallFs02
]]

------ ドアがある面の壁関係、ここに書くことでオブジェクトを一つに統一出来る ------
-- 回転させるスクリプト
local scrRotate02 = [[
    require "AdHoc"

    local this = GetThis()
    local trans

    -- フラグ
    local doRotate = false
    local ifRotateIsDone = false

    -- 時間関係の変数
    local timeTillRotateIsDone = 0.3
    local timePast = 0

    -- 関数 DoRotate 用の変数
    local angleTarget = 0
    local angleOrigin = 0   -- ラジアン度だから注意

    -- 関数 DoSinCos 用の変数
    local angleSinCosTarget = 90
    local angleSinCosOrigin = 0
    local angleYSinCos = 0
    local disSinCos
    local posOrigin = Vector3D:new()
    local posCenter = Vector3D:new()

    -- デバッグ用
    local debugNum = 0

    -- 問題     何故か4つ目の壁しか回転しない
    -- 原因判明 全部が同じtransformにアクセスしてしまっている（4つ目の壁がtransを上書きしている）
    -- 解決策   Updateの中でその都度Transformを取得する

    function Start()
        ------ rotationいじりの情報獲得 ------
        trans = GetComponent(this,"Transform")

        angleOrigin = trans.rotation.x
        angleTarget = math.rad(angleTarget)             -- 角度をラジアン度に変換

        posOrigin.x = trans.translate.x
        posOrigin.y = trans.translate.y
        posOrigin.z = trans.translate.z

        ------ transformいじりの情報獲得 ------
        -- 回転の中心を求める
        disSinCos = trans.scale.y

        posCenter.x = trans.translate.x                 -- translateの値をコピー
        posCenter.y = trans.translate.y
        posCenter.z = trans.translate.z

        local angleTemp = -1 * trans.rotation.y + math.rad(90)
        posCenter.x = trans.translate.x + disSinCos * math.cos(angleTemp)
        posCenter.z = trans.translate.z + disSinCos * math.sin(angleTemp)

        angleYSinCos = angleTemp + math.rad(180)        -- xyの回転方向
        
        angleSinCosTarget = math.rad(angleSinCosTarget) -- 角度をラジアン度に変換
        angleSinCosOrigin = math.rad(angleSinCosOrigin)
    end

    local function DoRotate()
        trans = GetComponent(this,"Transform")

        trans.rotation.x = angleOrigin + (angleTarget - angleOrigin) * (timePast / timeTillRotateIsDone)

        if timePast >= timeTillRotateIsDone then
            trans.rotation.x = angleTarget
            doRotate = false
            ifRotateIsDone = true
        end
    end

    local function DoSinCos()
        trans = GetComponent(this,"Transform")

        -- y方向を計算
        local angleTemp = angleSinCosOrigin + (angleSinCosTarget - angleSinCosOrigin) * (timePast / timeTillRotateIsDone)
        trans.translate.y = posCenter.y + disSinCos * math.sin(angleTemp)

        -- xy以外の計算
        local disTemp = disSinCos * math.cos(angleTemp)

        trans.translate.x = posCenter.x + disTemp * math.cos(angleYSinCos)
        trans.translate.z = posCenter.z + disTemp * math.sin(angleYSinCos)

        if timePast >= timeTillRotateIsDone then
            trans.translate.y = posCenter.y + disSinCos
            trans.translate.x = posCenter.x
            trans.translate.z = posCenter.z
        end
    end

    function Update()
        if doRotate == true then
            timePast = timePast + DeltaTime()

            DoRotate()
            DoSinCos()
        end
    end

    function StartRotate()
        doRotate = true
    end

    function KnowIfRotateIsDone()
        return ifRotateIsDone
    end

    function ChangeRotateCenter(hikisuuY)
        trans = GetComponent(this,"Transform")

        disSinCos = hikisuuY

        posCenter.x = trans.translate.x                 -- translateの値をコピー
        posCenter.y = trans.translate.y
        posCenter.z = trans.translate.z

        local angleTemp = -1 * trans.rotation.y + math.rad(90)
        posCenter.x = trans.translate.x + disSinCos * math.cos(angleTemp)
        posCenter.z = trans.translate.z + disSinCos * math.sin(angleTemp)

        angleYSinCos = angleTemp + math.rad(180)        -- xyの回転方向
    end

    -- 関数群として登録
    debugNum = #AdHoc.Global.EntranceFs02 + 1

    AdHoc.Global.EntranceFs02[debugNum] = {}
    AdHoc.Global.EntranceFs02[debugNum].StartRotate = StartRotate
    AdHoc.Global.EntranceFs02[debugNum].KnowIfRotateIsDone = KnowIfRotateIsDone
    AdHoc.Global.EntranceFs02[debugNum].ChangeRotateCenter = ChangeRotateCenter
]]

if AdHoc.Global.Ar_Scripts == nil then
    AdHoc.Global.Ar_Scripts = {}
end
AdHoc.Global.Ar_Scripts.scr_rotateDoor02 = scrRotate02

-- ドア作成のスクリプト
local scrCreateDoor = [[
    require "AdHoc"

    -- 自分自身をグローバルに登録
    if AdHoc.Global.Ar_objects == nil then
        AdHoc.Global.Ar_objects = {}
    end
    AdHoc.Global.Ar_objects.doorManager = GetThis()

    -- 関数配列
    if AdHoc.Global.Fs_SetUp == nil then
        AdHoc.Global.Fs_SetUp = {}
    end

    -- 時間関係の変数
    local timeTillRotateIsDone = 0.5
    local timePast = 0

    -- 壁の配列
    local namesWall = {}
    namesWall[#namesWall + 1] = "Entrance_Below"
    namesWall[#namesWall + 1] = "Entrance_Up"
    namesWall[#namesWall + 1] = "SideWall_Left"
    namesWall[#namesWall + 1] = "SideWall_Right"

    local walls = {}

    -- 扉の大きさに関する情報
    local scaDoor = Vector3D:new()
    scaDoor.x = 5   -- 扉の幅、壁の幅より大きくならないようチェックを入れる
    scaDoor.y = 5   -- 扉の高さ、壁の高さより大きくならないようチェックを入れる

    local marginDoor = Vector3D:new()   -- 壁に残しておくべき余白
    marginDoor.x = 0.5
    marginDoor.y = 1

    -- 生成に必要な情報
    AdHoc.Global.EntranceFs02 = {}
        
    function CreateDoorWall(hWall, wWall, zWall)
        -- ドアの大きさチェック
        if scaDoor.x > wWall - marginDoor.x * 2 then
            scaDoor.x = wWall - marginDoor.x * 2
        end
        if scaDoor.x < 0 then
            scaDoor.x = 0
        end
        if scaDoor.y > hWall - marginDoor.y * 2 then
            scaDoor.y = hWall - marginDoor.y * 2
        end
        if scaDoor.y < 0 then
            scaDoor.y = 0
        end

        -- 壁の位置などに必要な情報を取得
        local transFloor = GetComponent(FindEntity(AdHoc.Global.Ar_texts.nameFloor),"Transform")
        
        local posFloor = Vector3D:new()
        posFloor.x = transFloor.translate.x
        posFloor.y = transFloor.translate.y
        posFloor.z = transFloor.translate.z

        local scaFloor = Vector3D:new()
        scaFloor.x = transFloor.scale.x
        scaFloor.y = transFloor.scale.y
        scaFloor.z = transFloor.scale.z

        for i = 1, #namesWall ,1 do
            walls[namesWall[i] ] = CreateEntity()

            local tempTrans = GetComponent(walls[namesWall[i] ],"Transform")
            local posTemp = tempTrans.translate
            local scaTemp = tempTrans.scale

            posTemp.y = posFloor.y - scaFloor.y

            local tag = GetComponent(walls[namesWall[i] ],"Tag")
            tag:Set("Wall 1_"..namesWall[i])

            if namesWall[i] == "Entrance_Below" then
                scaTemp.x = scaDoor.x
                scaTemp.y = scaFloor.y
                scaTemp.z = zWall

                posTemp.x = posFloor.x
                posTemp.z = posFloor.z - scaFloor.z - scaTemp.y - zWall
            end
            if namesWall[i] == "Entrance_Up" then
                scaTemp.x = scaDoor.x
                scaTemp.y = hWall - (scaDoor.y + scaFloor.y)
                scaTemp.z = zWall

                posTemp.x = posFloor.x
                posTemp.z = posFloor.z - scaFloor.z - scaDoor.y * 2 - 
                GetComponent(walls["Entrance_Below"],"Transform").scale.y * 2 - scaTemp.y - zWall

            end
            if namesWall[i] == "SideWall_Left" then
                scaTemp.x = (wWall - scaDoor.x) / 2
                scaTemp.y = hWall
                scaTemp.z = zWall

                posTemp.x = posFloor.x - scaDoor.x - scaTemp.x
                posTemp.z = posFloor.z - scaFloor.z - scaTemp.y - zWall
            end
            if namesWall[i] == "SideWall_Right" then
                scaTemp.x = (wWall - scaDoor.x) / 2
                scaTemp.y = hWall
                scaTemp.z = zWall

                posTemp.x = posFloor.x + scaDoor.x + scaTemp.x
                posTemp.z = posFloor.z - scaFloor.z - scaTemp.y - zWall
            end

            -- 90度倒しておく
            tempTrans.rotation.x = math.rad(-90)

            -- スクリプトのアタッチ
            AddComponent(walls[namesWall[i] ],"Script",AdHoc.Global.Ar_Scripts.scr_rotateDoor02)

            -- 問題         登録したはずの関数を呼び出すことが出来ない（attempt to call table value と出る）
            -- 原因（多分） スクリプトをアタッチしてすぐは初期化が終わっていない？
            -- 解決策       時間をおいて（1フレーム以上おいてから）関数を実行する

            -- if namesWall[i] == "Entrance_Up" then
            --     local disTemp = scaTemp.y + scaDoor.y * 2 + GetComponent(walls["Entrance_Below"],"Transform").scale.y * 2

            --     if AdHoc.Global.EntranceFs02[2].ChangeRotateCenter ~= nil then
            --         AdHoc.Global.EntranceFs02[2].ChangeRotateCenter(disTemp)
            --     else
            --     end 
            -- end
        end

    end

    local tempDebug = false -- 初回実行時にchangerotatecenterを一回だけ実行

    function StartRotate()

        if tempDebug == false then
            local disTemp = GetComponent(walls["Entrance_Up"],"Transform").scale.y + 
            scaDoor.y * 2 + GetComponent(walls["Entrance_Below"],"Transform").scale.y * 2

            AdHoc.Global.EntranceFs02[2].ChangeRotateCenter(disTemp)
            tempDebug = true
        end

        for i = 1,#AdHoc.Global.EntranceFs02,1 do
            AdHoc.Global.EntranceFs02[i].StartRotate()
        end
    end

    function KnowIfRotateIsDone()
        for i = 1,#namesWall,1 do       -- 1つでもfalseなら即return
            if AdHoc.Global.EntranceFs02[i].KnowIfRotateIsDone() == false then
                return false
            end
        end

        return true
    end

    -- 関数をデリゲーション
    if AdHoc.Global.Fs_SetUp == nil then
        AdHoc.Global.Fs_SetUp = {}
    end

    AdHoc.Global.Fs_SetUp.F_CreateDoorWall02 = CreateDoorWall
]]

------ 屋根関係 ------
local roof                      -- 屋根のエンティティ

local colorRoof = Vector3D:new()    -- 屋根の色
colorRoof.x = 0.5
colorRoof.y = 0
colorRoof.z = 1

local scaRoof = Vector3D:new()  -- 屋根の大きさ
scaRoof.x = 16                  -- 部屋の大きさより小さくならないよう、チェックを入れる
scaRoof.y = 10

local disFromRoom = 50          -- 部屋からどれだけ上に生成するか

-- 時間関係の変数
local timeTillFall = 0          -- 壁が出来てから落ちてくるまでの時間

-- 屋根関数配列
if AdHoc.Global.Fs_Roof_forSet == nil then
    AdHoc.Global.Fs_Roof_forSet = {}
end

local scrRoofFall = [[
    require "AdHoc"

    this = GetThis()
    local trans = GetComponent(this,"Transform")

    -- フラグ
    local doFall = false
    local isFallDone = false

    local vectorY = 0           -- Y方向の速さ
    local gravityProv = 9.8     -- 重力
    local speedAdjust = 50      -- スピード調整（そのままだともったりしてた）

    -- 位置関係の変数
    local yStop = 0
    
    ------ 内部で呼び出す関数 ------
    local function FallRoof()   -- 落下処理（update内で実行）
        trans.translate.y = trans.translate.y - vectorY * DeltaTime()

        if trans.translate.y <= yStop then
            trans.translate.y = yStop

            isFallDone = true   -- 終了フラグ
        end
    end

    ------ 外部から呼び出す関数 ------
    function SetYStop(argY)     -- 停止位置を外部からセット
        yStop = argY
    end

    function FallStart()        -- 落下を外部からスタートさせる
        doFall = true
    end

    function KnowIfFallIsDone()
        return isFallDone
    end

    function Start()
        
    end

    function Update()
        if doFall == false and isFallDone == false then
            return
        end

        vectorY = vectorY + gravityProv * speedAdjust * DeltaTime()   -- 重力を加算

        FallRoof()
    end

    -- 関数をデリゲーション
    AdHoc.Global.Fs_Roof_forSet.F_FallStart = FallStart
    AdHoc.Global.Fs_Roof_forSet.F_SetYStop = SetYStop
    AdHoc.Global.Fs_Roof_forSet.F_KnowIfFallIsDone = KnowIfFallIsDone
]]

local isRoofCreated = false

function CreateRoof() -- 屋根を作る関数
    if isRoofCreated == true then
        return
    end

    isRoofCreated = true

    roof = CreateEntity()
    local trans = GetComponent(roof,"Transform")

    -- 名前を変更
    local tag = GetComponent(roof,"Tag")
    tag:Set("Roof")

    -- モデル読み込み
    local mesh = GetComponent(roof,"Mesh")
    mesh:Load("roof.fbx")

    -- カラー変更
    local mate = GetComponent(roof,"Material")
    mate.albedo = colorRoof

    -- モデルが90度傾いてるので調整
    trans.rotation.x = math.rad(-90)

    -- サイズ設定
    trans.scale.x = scaRoof.x
    trans.scale.z = scaRoof.y
    trans.scale.y = scaRoof.x

    --　位置設定
    local transFloor = GetComponent(FindEntity(AdHoc.Global.Ar_texts.nameFloor),"Transform")

    trans.translate.x = transFloor.translate.x
    trans.translate.z = transFloor.translate.z

    local yStop = transFloor.translate.y - transFloor.scale.y + hWall * 2
    trans.translate.y = yStop + disFromRoom

    -- スクリプトをアタッチ
    AddComponent(roof,"Script",scrRoofFall)
end

-- ドアと天井以外を生成
function CreateWalls_first()
    if isCreated == true then
        return    
    end

    -- 壁の位置などに必要な情報を取得
    local transFloor = GetComponent(FindEntity(AdHoc.Global.Ar_texts.nameFloor),"Transform")
    
    local posFloor = Vector3D:new()
    posFloor.x = transFloor.translate.x
    posFloor.y = transFloor.translate.y
    posFloor.z = transFloor.translate.z

    local scaFloor = Vector3D:new()
    scaFloor.x = transFloor.scale.x
    scaFloor.y = transFloor.scale.y
    scaFloor.z = transFloor.scale.z

    wWall = transFloor.scale.x

    -- 壁を4つ作る
    for i = 1, 3 , 1 do
        walls[i] = CreateEntity()

        local trans = GetComponent(walls[i],"Transform")
        trans.scale.x = wWall
        trans.scale.y = hWall
        trans.scale.z = zWall

        if i % 2 == 1 then  -- 左右の壁は長さを足して家が完全なキューブになるようにする
            trans.scale.x = wWall + zWall * 2
        end

        if AdHoc.Global.Ar_texts.nameFloor == "Stage" then  -- plane.objを使っていると位置がずれる
            trans.translate.y = posFloor.y
        else
            trans.translate.y = posFloor.y - scaFloor.y
        end
        trans.rotation.x = math.rad(-90) -- 最初は-90度回転させておいて、後で0度に戻していく

        -- 名前を変える（デバッグしやすくするため）
        local tag = GetComponent(walls[i],"Tag")
        tag:Set("Wall "..tostring(i))
        
        -- 壁の位置（yの半分）、回転設定
        if i == 1 then -- 右の壁
            trans.translate.x = posFloor.x + scaFloor.x + trans.scale.y + zWall
            trans.translate.z = posFloor.z

            trans.rotation.y = math.rad(-90)
        end
        if i == 2 then -- 奥の壁
            trans.translate.x = posFloor.x
            trans.translate.z = posFloor.z + scaFloor.z + trans.scale.y + zWall
            
            trans.rotation.y = math.rad(-180)
        end
        if i == 3 then -- 左の壁 
            trans.translate.x = posFloor.x - scaFloor.x - trans.scale.y - zWall
            trans.translate.z = posFloor.z
            
            trans.rotation.y = math.rad(-270)
        end
        -- スクリプトをアタッチ
        AddComponent(walls[i],"Script",scrRotate)
    end
    -- 壁が何度も生成されないようにする
    isCreated = true
end

-- フラグ
local isDoorCreated = false

function CreateDoor()
    if isDoorCreated == true then
        return
    end

    AdHoc.Global.Fs_SetUp.F_CreateDoorWall02(hWall,wWall,zWall)

    isDoorCreated = true
end

------ 組み立てる処理（外部から読みだす）------
local doOnce = false
local isEnd = false
local idWall = 1

-- 屋根用変数
local timeSinceWallSetUp = 0    -- 壁が出来てからの経過時間
local isRoofFallStarted = false -- 落下が実行されたかどうか

function SetUp()
    doOnce = true
end

function Update()
    if doOnce == true then
        if isEnd == false then
            if idWall == 1 then -- 1つ目の壁を動かすときの処理
                AdHoc.Global.WallFs02[idWall].StartRotate()
            end
    
            if AdHoc.Global.WallFs02[idWall].KnowIfRotateIsDone() == true then    -- 2個め以降
                if idWall < #AdHoc.Global.WallFs02 then
                    idWall = idWall + 1
                    AdHoc.Global.WallFs02[idWall].StartRotate()
                else
                end
            end
        end
    end

end

-- 最初の組み立てが終わったかどうか外部から知る関数
function KnowIfFirstSetupIsDone()
    return isSetupDone
end

------ 入口の組み立てに関連する関数 -------
local isEntranceSetupDone = false

function SetupEntrance()
    if isEntranceSetupDone == true then
        return  
    end
    isEntranceSetupDone = true

    local scrEntrance = GetComponent(AdHoc.Global.Ar_objects.doorManager,"Script")
    scrEntrance:Call("StartRotate")
end

function KnowIfEntranceSetupIsDone()
    local scrEntrance = GetComponent(AdHoc.Global.Ar_objects.doorManager,"Script")
    return scrEntrance:Call("KnowIfRotateIsDone")
end

------- 屋根の動作に関する関数 ------
local isRoofSetupIsDone = false
function SetupRoof()
    if isRoofSetupIsDone == true then
        return  
    end
    isRoofSetupIsDone = true
    
    -- 落下地点を渡す
    local transFloor = GetComponent(FindEntity(AdHoc.Global.Ar_texts.nameFloor),"Transform")
    local yStop = transFloor.translate.y - transFloor.scale.y + hWall * 2
    AdHoc.Global.Fs_Roof_forSet.F_SetYStop(yStop)

    -- 落下実行
    AdHoc.Global.Fs_Roof_forSet.F_FallStart()
end

function KnowIfRoofSetupIsDone()
    return AdHoc.Global.Fs_Roof_forSet.F_KnowIfFallIsDone()
end

-- ドアマネージャーを作成
local doorManager = CreateEntity()
AddComponent(doorManager,"Script",scrCreateDoor)    -- ドア作成スクリプトをアタッチ
GetComponent(doorManager,"Tag"):Set("DoorManager")  -- 名前を設定
GetComponent(doorManager,"Mesh").toDraw = false     -- メッシュを見えなくする
