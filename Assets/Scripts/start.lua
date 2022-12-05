require "AdHoc"

local input = GetInput()

function Update()
    if input:GetKeyDown(AdHoc.Key.enter) == true then
      LoadScene("S_MainGame.scene")
    end
end
