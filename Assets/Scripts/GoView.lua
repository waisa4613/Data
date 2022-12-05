require "AdHoc"

local this = GetThis()
local ms = GetComponent(this, "Mesh")
local input = GetInput()
AdHoc.Global.End=0
local m = GetComponent(this, "Material")
function Start()
            local m = GetComponent(this, "Material")
     
            m.albedo.x =1
            m.albedo.y = 0
            m.albedo.z =0
            m.metallicness =10
    
end

function Update()
    if AdHoc.Global.Camera >=1 then
        ms.toDraw=true

        if input:GetKey(AdHoc.Key.a) or input:GetButton(AdHoc.Controller.dpad_left) then
            local m = GetComponent(this, "Material")
     
            m.albedo.x =1
            m.albedo.y = 0
            m.albedo.z =0
            m.metallicness =10
       
      
            
        end
        --   if StartGame==true and input:GetKey(AdHoc.Key.w)then
            
            
        --         --LoadScene(nextScene)
        --     end
     if input:GetKey(AdHoc.Key.d)or input:GetButton(AdHoc.Controller.dpad_right) then
            local m = GetComponent(this, "Material")
     
            m.albedo.x =0
            m.albedo.y = 0
            m.albedo.z =0
            m.metallicness =10
          

    end
end
end
