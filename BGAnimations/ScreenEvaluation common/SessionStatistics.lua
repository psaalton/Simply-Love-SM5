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
            self:diffuse(color("#101519")):zoomto(150, 60)
            self:y(y_quad_pos)
            self:x(x_quad_pos)
        end
    }

    if stats.hours < 10 then
        stats.hours = 0 .. stats.hours
    end
    if stats.minutes < 10 then
        stats.minutes = 0 .. stats.minutes
    end
    if stats.notesHitThisGame > 9999 then
        stats.notesHitThisGame = tonumber(string.format("%.1f", stats.notesHitThisGame/1000)) .. "k"
    end

    sessionStats[#sessionStats+1] = LoadFont("Common Normal").. {
        Name="Stats",
        Text=("%s:%s\nSongs: %s\nNotes: %s"):format(

        stats.hours,
        stats.minutes,
        stats.songsPlayedThisGame,
        stats.notesHitThisGame

        ), 
        
        InitCommand=function(self)
            self:zoom(0.8)
            self:y(y_pos)
            self:x(x_pos)
        end
    }
end

return sessionStats

