require "AdHoc"

--adhoc 
local this  = GetThis()
local input = GetInput()

--move
local transform = GetComponent(this, "Transform")
local speed = 1

--select 
local downVector = Vector3D:new()
downVector.x = 0
downVector.y = 0
downVector.z = 1

--fixme:コントローラ追加
function Move()
    if input:GetKey(AdHoc.Key.a) then
        transform.translate.x = transform.translate.x - speed * DeltaTime()
    end
    if input:GetKey(AdHoc.Key.d) then
        transform.translate.x = transform.translate.x + speed * DeltaTime()
    end
    if input:GetKey(AdHoc.Key.w) then
        transform.translate.y = transform.translate.y + speed * DeltaTime()
    end
    if input:GetKey(AdHoc.Key.s) then
        transform.translate.y = transform.translate.y - speed * DeltaTime()
    end
end

--色変える
function Search()
    local entity = Raycast(transform.translate, downVector, 10)

    local start_button_material = GetComponent(FindEntity("StartButton"), "Material")
    start_button_material.albedo.x = 1
    start_button_material.albedo.y = 0
    start_button_material.albedo.z = 0

    local exit_button_material = GetComponent(FindEntity("ExitButton"), "Material")
    exit_button_material.albedo.x = 0
    exit_button_material.albedo.y = 0
    exit_button_material.albedo.z = 1

    if entity ~= nil then
        if entity == FindEntity("StartButton") then
            local start_button_material = GetComponent(entity, "Material")
            start_button_material.albedo.x = 1
            start_button_material.albedo.y = 1
            start_button_material.albedo.z = 1

            --ボタン
            if input:GetKey(AdHoc.Key.space) then
                local start_button_script = GetComponent(entity, "Script")
                start_button_script:Set("Start", true)
            end

        elseif entity == FindEntity("ExitButton") then
            local exit_button_material = GetComponent(entity, "Material")
            exit_button_material.albedo.x = 1
            exit_button_material.albedo.y = 1
            exit_button_material.albedo.z = 1

            --ボタン
            if input:GetKey(AdHoc.Key.space) then
                local exit_button_script = GetComponent(entity, "Script")
                exit_button_script:Set("Exit", true)
            end
        end
    end
end

function Update()
    Move()
    Search()
end
