local Players = GAMESTATE:GetHumanPlayers();

local y_pos = 199
local y_quad_pos = 199

local stats
local sessionStats = Def.ActorFrame {}

for player in ivalues(Players) do
    stats = SessionDataForStatistics(player)
    local x_pos = player==PLAYER_1 and 60 or _screen.w-60
    local x_quad_pos = player==PLAYER_1 and 50  or _screen.w-50

    sessionStats[#sessionStats+1] = Def.Quad {
        InitCommand=function(self)
            self:diffuse(color("#101519")):zoomto(150, 90)
            self:y(y_quad_pos)
            self:x(x_quad_pos)
        end
    }

    sessionStats[#sessionStats+1] = LoadFont("Common Normal").. {
        Name="Stats",
        Text=("Songs: %s\nNotes: %s\n%sh %sm %ss\nSong restarted: %s \nTotal restarts: %s"):format(

        stats.songsPlayedThisGame,
        stats.notesHitThisGame, 
        stats.hours,
        stats.minutes,
        stats.seconds,
        SL.RestartCounter,
        stats.restartCountThisGame

        ), 
        
        InitCommand=function(self)
            self:zoom(0.75)
            self:y(y_pos)
            self:x(x_pos)
        end
    }
end

return sessionStats

