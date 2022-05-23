local player = ...

local playerStats = STATSMAN:GetCurStageStats():GetPlayerStageStats(player)
local grade = playerStats:GetGrade()
local radarvalues = playerStats:GetRadarPossible():GetValue( "RadarCategory_TapsAndHolds")

-- only run in modified stepmania build
if SYNCMAN and SYNCMAN:IsEnabled() then
	-- Broadcast final score for each player, used by syncstart-web to save scores
	if GAMESTATE:IsCourseMode() then
		SYNCMAN:BroadcastFinalCourseScore(playerStats)
	else
		SYNCMAN:BroadcastFinalScore(playerStats)
	end
end

-- "I passd with a q though."
local title = GAMESTATE:GetCurrentSong():GetDisplayFullTitle()
if title == "D" then grade = "Grade_Tier99" end

local t = Def.ActorFrame{}
t[#t+1] = LoadActor(THEME:GetPathG("", "_grades/"..grade..".lua"), playerStats)..{
	InitCommand=function(self)
		self:x(70 * (player==PLAYER_1 and -1 or 1))
		self:y(_screen.cy-134)
	end,
	OnCommand=function(self) self:zoom(0.4) end
}

return t
