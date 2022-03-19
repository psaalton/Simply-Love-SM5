local audio_file = "serenity in ruin.ogg"

local style = ThemePrefs.Get("VisualStyle")
if style == "SRPG5" then
	audio_file = "dreams of will arrange.ogg"
end

if style == "Unicorn" then
	audio_file = "PikkuKakkonen.ogg"
end

return THEME:GetPathS("", audio_file)
