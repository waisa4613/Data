require "AdHoc"

function Start()
    local e = FindEntity("Entity") -- tag name
    if e ~= nil then
        local s = GetComponent(e, "Script")
        s:Set("value", 99)
        s:Call("PrintValue")
    end
end