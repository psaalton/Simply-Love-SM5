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

if ThemePrefs.Get("VisualStyle") == "Unicorn" then
	t[#t+1] = Def.Quad {
		InitCommand=function(self)
			self:diffuse(color("#101519")):zoomto(160, 150)
			self:y(112)
			self:x(70)
			self:diffusealpha(0.40)
			if player == PLAYER_1 then
				self:x( self:GetX() * -1 )
			end
		end
	}
end

t[#t+1] = LoadActor(THEME:GetPathG("", "_grades/"..grade..".lua"), playerStats)..{
	InitCommand=function(self)
		self:x(70 * (player==PLAYER_1 and -1 or 1))
		self:y(_screen.cy-134)
	end,
	OnCommand=function(self) self:zoom(0.4) end
}


if ThemePrefs.Get("VisualStyle") == "Unicorn" then
	t[#t+1] = Def.Quad {
		InitCommand=function(self)
			self:diffuse(color("#101519")):zoomto(150, 30)
			self:y(_screen.cy-71)
			self:x(220)
			self:diffusealpha(0.65)
			if player == PLAYER_1 then
				self:x( self:GetX() * -1 )
			end
		end
	}

	t[#t+1] = Def.BitmapText{
		Font="Wendy/_wendy white",
		Text="Normal Score",
		InitCommand=function(self)
			self:x(-210)
			self:y(_screen.cy-79)
			self:zoom(0.175)
			if player == PLAYER_2 then
				self:x( self:GetX() * -1 )
			end
		end
	}

	t[#t+1] = Def.BitmapText{
		Font="Wendy/_wendy white",
		Text=("%.2f"):format(CalculateITGScore(player)),
		InitCommand=function(self)
			self:zoom(0.175)
			self:x(-210)
			self:y(_screen.cy-65)
			if player == PLAYER_2 then
				self:x( self:GetX() * -1 )
			end
		end
	}
end



return t
