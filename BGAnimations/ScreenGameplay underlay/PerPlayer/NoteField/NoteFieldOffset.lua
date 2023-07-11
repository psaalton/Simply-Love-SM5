local player = ...
local pn = ToEnumShortString(player)
local mods = SL[pn].ActiveModifiers

return Def.Actor{
  OnCommand=function(self)
    local multiplier = pn == "P1" and -1 or 1
    SCREENMAN:GetTopScreen():GetChild("Player"..pn):GetChild("NoteField"):addx(mods.NoteFieldOffsetX * multiplier)
    SCREENMAN:GetTopScreen():GetChild("Player"..pn):GetChild("NoteField"):addy(mods.NoteFieldOffsetY)
  end,
}
