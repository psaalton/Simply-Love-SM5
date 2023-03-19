-- per-player lower half of ScreenEvaluation

local player = ...
local NumPlayers = #GAMESTATE:GetHumanPlayers()

local stats = SessionDataForStatistics(player)
local h   = (player==PLAYER_1 and left or right)
local x   = (player==PLAYER_1 and _screen.w * -0.04 or _screen.w * 0.04)

local pane_spacing = 10
local small_pane_w = 300

-- smaller width (used when both players are joined) by default
local pane_width = 300
local pane_height  = 180

-- if only one player is joined, use more screen width to draw two
-- side-by-side panes that both belong to this player
if NumPlayers == 1 and SL.Global.GameMode ~= "Casual" then
	pane_width = (pane_width * 2) + pane_spacing
end

local af = Def.ActorFrame{
	Name=ToEnumShortString(player).."_AF_Lower",
	InitCommand=function(self)

		-- if 2 players joined, or if Casual Mode where panes are not full-width,
		-- give each player their own distinct space for a half-width pane
		if NumPlayers == 2 or SL.Global.GameMode == "Casual" then
			self:x(_screen.cx + ((small_pane_w + pane_spacing) * (player==PLAYER_1 and -0.5 or 0.5)))

		else
			self:x(_screen.cx - ((small_pane_w + pane_spacing) * 0.5))
		end
	end
}

-- -----------------------------------------------------------------------
-- background quad for player stats

af[#af+1] = Def.Quad{
	Name="LowerQuad",
	InitCommand=function(self)
		self:diffuse(color("#1E282F")):horizalign(left)
		self:xy(-small_pane_w * 0.5, _screen.cy+34)
		self:zoomto( pane_width, pane_height )

		if ThemePrefs.Get("RainbowMode") then
			self:diffusealpha(0.9)
		end
	end
}

af[#af+1] = LoadFont("Common Normal").. {
	Name="Steps",
    Text=(""),

	InitCommand=function(self)
		self:zoom(0.9)
		self:xy(x, _screen.h-15)
	end,

	ScreenChangedMessageCommand=function(self) self:playcommand("Refresh") end,

		RefreshCommand=function(self)
			stats = SessionDataForStatistics(player)

			if stats.hours < 10 then
				stats.hours = 0 .. stats.hours
			end
			if stats.minutes < 10 then
				stats.minutes = 0 .. stats.minutes
			end
			if stats.notesHitThisGame > 9999 then
				stats.notesHitThisGame = tonumber(string.format("%.1f", stats.notesHitThisGame/1000)) .. "k"
			end
			self:settext(("💿x %s ⏱%s:%s 👟x %s"):format(
				stats.songsPlayedThisGame,
				stats.hours,
				stats.minutes,
				stats.notesHitThisGame))
		end	
	
}
	
-- "Look at this graph."  –Some sort of meme on The Internet
af[#af+1] = LoadActor("./Graphs.lua", player)

-- list of modifiers used by this player for this song
af[#af+1] = LoadActor("./PlayerModifiers.lua", player)

-- was this player disqualified from ranking?
af[#af+1] = LoadActor("./Disqualified.lua", player)

-- -----------------------------------------------------------------------

return af