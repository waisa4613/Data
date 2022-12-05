require "AdHoc"

function OnCollisionEnter(rhs)
    local s = GetComponent(rhs, "Script")
    LogMessage(s:Get("value"))
    LogMessage(s:Call("GetValue", 2))
end