local Players = GAMESTATE:GetHumanPlayers();

local y_pos = _screen.cy - 170
local y_quad_pos = 70

local stats
local sessionStats = Def.ActorFrame {}

for player in ivalues(Players) do
    stats = SessionDataForStatistics(player)
    local x_pos = player==PLAYER_1 and 60 or _screen.w-60
    local x_quad_pos = player==PLAYER_1 and 50  or _screen.w-50

    sessionStats[#sessionStats+1] = Def.Quad {
        InitCommand=function(self)
            self:diffuse(color("#101519")):zoomto(150, 60)
            self:y(y_quad_pos)
            self:x(x_quad_pos)
        end
    }

    sessionStats[#sessionStats+1] = LoadFont("Common Normal").. {
        Name="Stats",
        Text=("Songs: %s\nNotes: %s\nPlayed: %sh %sm %ss"):format(

        stats.songsPlayedThisGame,
        stats.notesHitThisGame, 
        stats.hours,
        stats.minutes,
        stats.seconds

        ), 
        
        InitCommand=function(self)
            self:zoom(0.8)
            self:y(y_pos)
            self:x(x_pos)
        end
    }
end

return sessionStats

