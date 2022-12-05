require "AdHoc"

local this = GetThis()
local input = GetInput()
local StartTitle = false
local nextScene = "Title.scene" -- 移動先シーンの名前

function Start()


end

function Update()

 if input:GetKey(AdHoc.Key.d) then
        local m = GetComponent(this, "Material")
 
        m.albedo.x =1
        m.albedo.y = 0
        m.albedo.z =0
        m.metallicness =10
        StartTitle=true
  
        
end
      if StartTitle==true and input:GetKey(AdHoc.Key.w)then
        
        
            LoadScene(nextScene)
        end
 if input:GetKey(AdHoc.Key.a) then
        local m = GetComponent(this, "Material")
 
        m.albedo.x =0
        m.albedo.y = 0
        m.albedo.z =0
        m.metallicness =10
        StartTItle=false
end
end
