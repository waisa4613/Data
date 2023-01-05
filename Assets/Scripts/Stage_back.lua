
-- 床が裏から見ると透けちゃうのを防ぐ処理 --

require "AdHoc"

local this = GetThis()

function Update()
    local stageFront = FindEntity(AdHoc.Global.Ar_texts.nameFloor)
    GetComponent(this,"Transform").translate = GetComponent(stageFront,"Transform").translate
end
