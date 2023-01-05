require "AdHoc"

local this = GetThis()

local start_button = FindEntity("StartButton")
local start = GetComponent(start_button, "Script")

local exit_button = FindEntity("ExitButton")
local exit = GetComponent(exit_button, "Script")

local sleep_cnt = 200

function LoadGameScene()
    LoadScene("S_MainGame.scene")
end

function Exit()
    LogMessage("Exit")
end


function Sleep()
    if sleep_cnt > 0 then
        sleep_cnt = sleep_cnt - 1
    else
        sleep_cnt = 200
        return true
    end
end


function Update()
    if start:Call("GetState") then
        if Sleep() then
            LoadGameScene()
        end
    end

    if exit:Call("GetState") then
        if Sleep() then
            Exit()
        end
    end
end

