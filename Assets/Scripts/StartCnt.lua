require "AdHoc"

local this = GetThis()
local input = GetInput()
local Time=0
local m = GetComponent(this, "Mesh")
local a = true
local b = true
local c = true
local d= true


function Start()



end

function Update()


    Time=Time+DeltaTime()
   if a== true then 
   
        if Time >=1 then
            m.toDraw=true
           -- LogMessage(Time)
           m:Load("3.obj")
           a= false
        end
    end
    
   if b== true then 
        if Time >=2 then
            m:Load("2.obj")
            b= false
           
        end
   
    end
    if c== true then
        if Time>=3 then 
            m:Load("1.obj")
            c=false
        end
    end
 
   
    if Time >= 4 then
        AdHoc.Global.Start= 2
      

      m.toDraw=false

    end

    if Time >= 5 then 
        DestroyEntity(this)
    end

    --LogMessage(AdHoc.Global.Start)
end
function FixedUpdate()
  


    -- body
end

