
-- ゲーム開始時の、部屋が落ちてくる演出 --

require "AdHoc"

local this = GetThis()

-- 自分自身をグローバルに登録（FindEntityが実装されたのでいらないかもしれない）
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
local hWall = 7    -- 壁の高さ
local wWall = 0    -- 壁の幅（floorの大きさに合わせる）
local zWall = 1.0   -- 壁の太さ

-- 壁回転実行関数の配列
if AdHoc.Global.WallFs == nil then
    AdHoc.Global.WallFs = {}
end

-- 家が落下してから家が展開するまでの時間
local timeTillOpenFromLanding = 1
local timePastFromLanding = 0

-- ドアマネージャーを作成
local doorManager = CreateEntity()

-- 生成したオブジェクトの内部で使用する数値
local timeTillWallDestroyed = 1

function GetTimeTillWallBeingDestroyed()
    return timeTillWallDestroyed
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

    local timePastForDestroy = 0    -- 倒れた後の経過時間

    -- 関数 DoRotate 用の変数
    local angleTarget = -90
    local angleOrigin = 0   -- ラジアン度だから注意

    -- 関数 DoSinCos 用の変数
    local angleSinCosTarget = 0
    local angleSinCosOrigin = 90
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
        -- 床の情報取得
        local transFloor = GetComponent(FindEntity("floor"),"Transform")

        -- 回転の中心を求める
        disSinCos = trans.scale.y

        posCenter.x = trans.translate.x                 -- translateの値をコピー
        posCenter.y = trans.translate.y - trans.translate.y - transFloor.scale.y
        posCenter.z = trans.translate.z

        -- -- デバッグ用
        -- LogMessage(debugNum)
        -- LogMessage(posCenter.x)
        -- LogMessage(posCenter.y)
        -- LogMessage(posCenter.z)
        -- LogMessage("- end -")

        local angleTemp = -1 * trans.rotation.y + math.rad(90)

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
            trans.translate.y = posCenter.y + disSinCos * math.sin(angleSinCosTarget)
            trans.translate.x = posCenter.x + disSinCos * math.cos(angleYSinCos)
            trans.translate.z = posCenter.z + disSinCos * math.sin(angleYSinCos)
        end
    end

    function Update()
        if doRotate == true then
            timePast = timePast + DeltaTime()

            DoRotate()
            DoSinCos()
        end
        if ifRotateIsDone == true then
            timePastForDestroy = timePastForDestroy + DeltaTime()

            if timePastForDestroy >= GetComponent(FindEntity("manager_openingHouse"),"Script"):Call("GetTimeTillWallBeingDestroyed") then
                DestroyEntity(this)
            end
        end
    end

    function StartRotate()
        doRotate = true
    end

    function KnowIfRotateIsDone()
        return ifRotateIsDone
    end

    -- 関数群みたいにできるのかテスト（実現できれば楽そう）
    AdHoc.Global.WallFs[#AdHoc.Global.WallFs + 1] = {}
    AdHoc.Global.WallFs[#AdHoc.Global.WallFs].StartRotate = StartRotate
    AdHoc.Global.WallFs[#AdHoc.Global.WallFs].KnowIfRotateIsDone = KnowIfRotateIsDone

    debugNum = #AdHoc.Global.WallFs
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

    local timePastForDestroy = 0    -- 壁が壊れるまでの経過時間

    -- 関数 DoRotate 用の変数
    local angleTarget = -90
    local angleOrigin = 0   -- ラジアン度だから注意

    -- 関数 DoSinCos 用の変数
    local angleSinCosTarget = 0
    local angleSinCosOrigin = 90
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
        -- floorの情報取得
        local transFloor = GetComponent(FindEntity("floor"),"Transform")

        -- 回転の中心を求める
        disSinCos = trans.scale.y                       -- 回転の半径

        posCenter.x = trans.translate.x                 -- translateの値をコピー
        posCenter.y = transFloor.translate.y - transFloor.scale.y
        posCenter.z = trans.translate.z

        local angleTemp = -1 * trans.rotation.y + math.rad(90)

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
            trans.translate.y = posCenter.y
            trans.translate.x = posCenter.x + disSinCos * math.cos(angleYSinCos)
            trans.translate.z = posCenter.z + disSinCos * math.sin(angleYSinCos)
        end
    end

    function Update()
        if doRotate == true then
            timePast = timePast + DeltaTime()

            DoRotate()
            DoSinCos()
        end
        if ifRotateIsDone == true then
            timePastForDestroy = timePastForDestroy + DeltaTime()

            if timePastForDestroy >= GetComponent(FindEntity("manager_openingHouse"),"Script"):Call("GetTimeTillWallBeingDestroyed") then
                DestroyEntity(this)
            end
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
        local transFloor = GetComponent(FindEntity("floor"),"Transform")

        disSinCos = hikisuuY

        posCenter.x = trans.translate.x                 -- translateの値をコピー
        posCenter.y = transFloor.translate.y - transFloor.scale.y
        posCenter.z = trans.translate.z

        local angleTemp = -1 * trans.rotation.y + math.rad(90)

        angleYSinCos = angleTemp + math.rad(180)        -- xyの回転方向
    end

    function ReCulculate()
        trans = GetComponent(this,"Transform")
        local transFloor = GetComponent(FindEntity("floor"),"Transform")
        
        posCenter.x = trans.translate.x                 -- translateの値をコピー
        posCenter.y = transFloor.translate.y - transFloor.scale.y
        posCenter.z = trans.translate.z

        local angleTemp = -1 * trans.rotation.y + math.rad(90)

        angleYSinCos = angleTemp + math.rad(180)        -- xyの回転方向
    end

    -- 関数群として登録
    debugNum = #AdHoc.Global.EntranceFs + 1

    AdHoc.Global.EntranceFs[debugNum] = {}
    AdHoc.Global.EntranceFs[debugNum].StartRotate = StartRotate
    AdHoc.Global.EntranceFs[debugNum].KnowIfRotateIsDone = KnowIfRotateIsDone
    AdHoc.Global.EntranceFs[debugNum].ChangeRotateCenter = ChangeRotateCenter
]]

if AdHoc.Global.Ar_Scripts == nil then
    AdHoc.Global.Ar_Scripts = {}
end
AdHoc.Global.Ar_Scripts.scr_rotateDoor = scrRotate02

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
    AdHoc.Global.EntranceFs = {}
        
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
        local floor = FindEntity("floor")
        local transFloor = GetComponent(floor,"Transform")
        
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

            posTemp.z = posFloor.z - scaFloor.z - zWall     -- zの位置は共通している

            local tag = GetComponent(walls[namesWall[i] ],"Tag")
            tag:Set("Wall 1_"..namesWall[i])

            if namesWall[i] == "Entrance_Below" then
                scaTemp.x = scaDoor.x
                scaTemp.y = scaFloor.y
                scaTemp.z = zWall

                posTemp.x = posFloor.x
                posTemp.y = posFloor.y
            end
            if namesWall[i] == "Entrance_Up" then
                scaTemp.x = scaDoor.x
                scaTemp.y = hWall - (scaDoor.y + scaFloor.y)
                scaTemp.z = zWall

                posTemp.x = posFloor.x
                posTemp.y = posFloor.y - scaFloor.y + scaDoor.y * 2 + 
                GetComponent(walls["Entrance_Below"],"Transform").scale.y * 2 + scaTemp.y

            end
            if namesWall[i] == "SideWall_Left" then
                scaTemp.x = (wWall - scaDoor.x) / 2
                scaTemp.y = hWall
                scaTemp.z = zWall

                posTemp.x = posFloor.x - scaDoor.x - scaTemp.x
                posTemp.y = posFloor.y - scaFloor.y + scaTemp.y
            end
            if namesWall[i] == "SideWall_Right" then
                scaTemp.x = (wWall - scaDoor.x) / 2
                scaTemp.y = hWall
                scaTemp.z = zWall

                posTemp.x = posFloor.x + scaDoor.x + scaTemp.x
                posTemp.y = posFloor.y - scaFloor.y + scaTemp.y
            end

            -- スクリプトのアタッチ
            AddComponent(walls[namesWall[i] ],"Script",AdHoc.Global.Ar_Scripts.scr_rotateDoor)

            -- 問題         登録したはずの関数を呼び出すことが出来ない（attempt to call table value と出る）
            -- 原因（多分） スクリプトをアタッチしてすぐは初期化が終わっていない？
            -- 解決策       時間をおいて（1フレーム以上おいてから）関数を実行する
        end

    end

    local tempDebug = false -- 初回実行時にchangerotatecenterを一回だけ実行

    function StartRotate()

        if tempDebug == false then
            local disTemp = GetComponent(walls["Entrance_Up"],"Transform").scale.y + 
            scaDoor.y * 2 + GetComponent(walls["Entrance_Below"],"Transform").scale.y * 2

            AdHoc.Global.EntranceFs[2].ChangeRotateCenter(disTemp)
            tempDebug = true
        end

        for i = 1,#AdHoc.Global.EntranceFs,1 do
            AdHoc.Global.EntranceFs[i].StartRotate()
        end
    end

    function KnowIfRotateIsDone()
        for i = 1,#namesWall,1 do       -- 1つでもfalseなら即return
            if AdHoc.Global.EntranceFs[i].KnowIfRotateIsDone() == false then
                return false
            end
        end

        return true
    end

    function FallMove(argYMinus)
        for i = 1, #namesWall ,1 do
            local temp_trans = GetComponent(walls[namesWall[i] ],"Transform")
            temp_trans.translate.y = temp_trans.translate.y - argYMinus
        end
    end

    function ReCulculate()
        for i = 1, #namesWall ,1 do
            local temp_scr = GetComponent(walls[namesWall[i] ],"Script")
            temp_scr:Call("ReCulculate")
        end
    end

    -- 関数をデリゲーション
    if AdHoc.Global.Fs_SetUp == nil then
        AdHoc.Global.Fs_SetUp = {}
    end

    AdHoc.Global.Fs_SetUp.F_CreateDoorWall = CreateDoorWall

    AdHoc.Global.WallFs[#AdHoc.Global.WallFs + 1] = {}
    AdHoc.Global.WallFs[#AdHoc.Global.WallFs].StartRotate = StartRotate
    AdHoc.Global.WallFs[#AdHoc.Global.WallFs].KnowIfRotateIsDone = KnowIfRotateIsDone
]]

------ 屋根関係 ------
local roof                      -- 屋根のエンティティ

local colorRoof = Vector3D:new()    -- 屋根の色
colorRoof.x = 0.5
colorRoof.y = 0
colorRoof.z = 1

local scaRoof = Vector3D:new()  -- 屋根の大きさ
scaRoof.x = 30                  -- 部屋の大きさより小さくならないよう、チェックを入れる
scaRoof.y = 20

local disFromRoom = 50          -- 部屋からどれだけ上に生成するか

-- 時間関係の変数
local timeTillFall = 0          -- 壁が出来てから落ちてくるまでの時間

-- 屋根関数配列
if AdHoc.Global.Fs_Roof == nil then
    AdHoc.Global.Fs_Roof = {}
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
    AdHoc.Global.Fs_Roof.F_FallStart = FallStart
    AdHoc.Global.Fs_Roof.F_SetYStop = SetYStop
    AdHoc.Global.Fs_Roof.F_KnowIfFallIsDone = KnowIfFallIsDone
]]

local isRoofCreated = false

local function CreateRoof() -- 屋根を作る関数

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
    local floor = FindEntity("floor")
    local transFloor = GetComponent(floor,"Transform")

    trans.translate.x = transFloor.translate.x
    trans.translate.z = transFloor.translate.z

    local yStop = transFloor.translate.y - transFloor.scale.y + hWall * 2
    trans.translate.y = yStop

    -- スクリプトをアタッチ
    AddComponent(roof,"Script",scrRoofFall)
end

-- フラグ
local isDoorCreated = false

local function CreateDoor()
    if isDoorCreated == true then
        return
    end

    AdHoc.Global.Fs_SetUp.F_CreateDoorWall(hWall,wWall,zWall)

    isDoorCreated = true
end

-- 壁、天井を生成
function CreateWalls()
    if isCreated == true then
        return
    end

    -- 壁の位置などに必要な情報を取得
    local floor = FindEntity("floor")
    local transFloor = GetComponent(floor,"Transform")
    
    local posFloor = Vector3D:new()
    posFloor.x = transFloor.translate.x
    posFloor.y = transFloor.translate.y
    posFloor.z = transFloor.translate.z

    local scaFloor = Vector3D:new()
    scaFloor.x = transFloor.scale.x
    scaFloor.y = transFloor.scale.y
    scaFloor.z = transFloor.scale.z

    wWall = transFloor.scale.x
    
    -- 壁を4つ作る（すでに箱になっている状態）
    for i = 1, 4 , 1 do
        if i == 1 then
            CreateDoor()
        else
            walls[i] = CreateEntity()

            local trans = GetComponent(walls[i],"Transform")
            trans.scale.x = wWall
            trans.scale.y = hWall
            trans.scale.z = zWall
    
            if i % 2 == 0 then  -- 左右の壁は長さを足して家が完全なキューブになるようにする
                trans.scale.x = wWall + zWall * 2
            end
    
            trans.translate.y = posFloor.y - scaFloor.y + hWall
    
            -- 名前を変える（デバッグしやすくするため）
            local tag = GetComponent(walls[i],"Tag")
            tag:Set("Wall "..tostring(i))
            
            -- 壁の位置（yの半分）、回転設定
            if i == 2 then -- 右の壁
                trans.translate.x = posFloor.x + scaFloor.x + zWall
                trans.translate.z = posFloor.z

                trans.rotation.y = math.rad(-90)
            end
            if i == 3 then -- 奥の壁
                trans.translate.x = posFloor.x
                trans.translate.z = posFloor.z + scaFloor.z + zWall

                trans.rotation.y = math.rad(-180)
            end
            if i == 4 then -- 左の壁 
                trans.translate.x = posFloor.x - scaFloor.x - zWall
                trans.translate.z = posFloor.z

                trans.rotation.y = math.rad(-270)
            end
            -- スクリプトをアタッチ
            AddComponent(walls[i],"Script",scrRotate)
        end
    end
    -- 天井を生成する
    CreateRoof()

    -- 壁が何度も生成されないようにする
    isCreated = true
end

------                                      ------
------ 家を展開する処理（外部から読みだす） ------
------                                      ------
local doOnce = false
local isEnd = false
local idWall = 1

-- 屋根用変数
local timeSinceWallSetUp = 0    -- 壁が出来てからの経過時間
local isRoofFallStarted = false -- 落下が実行されたかどうか

function OpenHouse()
    doOnce = true
end

------                          ------
------- 屋根の動作に関する関数 ------
------                          ------

-- 吹き飛んでいくときの速度
local speedBlownAway = Vector3D:new()
speedBlownAway.x = -20 
speedBlownAway.y = 150
speedBlownAway.z = -20

local angleXRotateBlownPS = 360 * 0.5

local isBlowAwayDone = false

local timeTillBlownisDone = 3
local timePastBlown = 0

local function BlowAwayRoof()
    if isBlowAwayDone == true then
        return
    end
    timePastBlown = timePastBlown + DeltaTime()

    local transRoof = GetComponent(roof,"Transform")
    transRoof.translate.x = transRoof.translate.x + speedBlownAway.x * DeltaTime()
    transRoof.translate.y = transRoof.translate.y + speedBlownAway.y * DeltaTime()
    transRoof.translate.z = transRoof.translate.z + speedBlownAway.z * DeltaTime()

    transRoof.rotation.x = transRoof.rotation.x + math.rad(angleXRotateBlownPS) * DeltaTime()

    if timePastBlown >= timeTillBlownisDone then
        isBlowAwayDone = true
        DestroyEntity(roof)
    end
end

local function KnowIfRoofBlowAwayIsDone()

end

--                      --
-- 家を落下させる処理   --
--                      --

-- フラグ
local didHouseFallStart = false
local isHouseFallDone = false

-- 微調整変数
-- 床の情報取得 --
local yFloorFirst = 70 -- 床の最初の位置
local yFloorEnd = 0     -- 落下した後の位置

local timeTillHouseFall = 0.5
local speedHouseFall = yFloorFirst / timeTillHouseFall

function StartHouseFall()
    didHouseFallStart = true
end

local function HouseFall()
    if isHouseFallDone == true then
        return
    end

    local temp_disMove = speedHouseFall * DeltaTime()   -- このフレームでの移動量を求める

    -- 床を移動
    local floor = FindEntity("floor")
    local temp_y = GetComponent(floor,"Transform").translate.y

    if temp_y - temp_disMove <= yFloorEnd then          -- 着地チェック処理
        temp_disMove = temp_y - yFloorEnd
        isHouseFallDone = true
    end
    GetComponent(floor,"Transform").translate.y = temp_y - temp_disMove

    -- ドアを移動
    local scrDoor = GetComponent(doorManager,"Script")
    scrDoor:Call("FallMove",temp_disMove)
    if isHouseFallDone == true then
        scrDoor:Call("ReCulculate")
    end

    -- ドア以外の壁を移動
    local j = 1

    for i = 1,100 do
        if walls[i] ~= nil then
            j = j + 1

            local trans = GetComponent(walls[i],"Transform")
            trans.translate.y = trans.translate.y - temp_disMove
        end
        if j >= #walls then
            break
        end
    end

    -- 屋根を移動
    local trans = GetComponent(roof,"Transform")
    trans.translate.y = trans.translate.y - temp_disMove
end

function IfHouseFallingIsDone()
    return isHouseFallDone
end

--                  --
-- StartとUpdate    --
--                  --

local isOpeningDone = false

function Start()
    local floor = FindEntity("floor")
    GetComponent(floor,"Transform").translate.y = yFloorFirst
end

function Update()
    if didHouseFallStart == true then
        HouseFall()
    end

    if isHouseFallDone == true then
        -- 屋根を吹き飛ばす
        BlowAwayRoof()

        timePastFromLanding = timePastFromLanding + DeltaTime()

        if timePastFromLanding >= timeTillOpenFromLanding and isEnd == false then
            if idWall == 1 then -- 1つ目の壁を動かすときの処理
                AdHoc.Global.WallFs[idWall].StartRotate()
            end
    
            if AdHoc.Global.WallFs[idWall].KnowIfRotateIsDone() == true then    -- 2個め以降$
                if idWall < #AdHoc.Global.WallFs then
                    idWall = idWall + 1
                    AdHoc.Global.WallFs[idWall].StartRotate()
                else
                    isOpeningDone = true
                end
            end
        end
    end

end

-- 最初の組み立てが終わったかどうか外部から知る関数
function KnowIfOpeningIsDone()
    return isOpeningDone
end

-- ドアマネージャーにスクリプトをアタッチ（訳合ってここでやってる）
AddComponent(doorManager,"Script",scrCreateDoor)    -- ドア作成スクリプトをアタッチ
GetComponent(doorManager,"Tag"):Set("DoorManager")  -- 名前を設定
GetComponent(doorManager,"Mesh").toDraw = false     -- メッシュを見えなくする