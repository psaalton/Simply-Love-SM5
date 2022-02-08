SessionDataForStatistics = function(player)

    local totalTime = 0
    local songsPlayedThisGame = 0
    local notesHitThisGame = 0
    local restartCountThisGame = 0

    -- Use pairs here (instead of ipairs) because this player might have late-joined
    -- which will result in nil entries in the the Stats table, which halts ipairs.
    -- We're just summing total time anyway, so order doesn't matter.
    for i,stats in pairs( SL[ToEnumShortString(player)].Stages.Stats ) do
        totalTime = totalTime + (stats and stats.duration or 0)
        songsPlayedThisGame = songsPlayedThisGame + (stats and not stats.isRestart and 1 or 0)
        restartCountThisGame = restartCountThisGame + (stats and stats.isRestart and 1 or 0)

        if stats and stats.judgments then

            
            PrintTable(stats)
            PrintTable(stats.judgments)
            -- increment notesHitThisGame by the total number of tapnotes hit in this particular stepchart by using the per-column data
            -- don't rely on the engine's non-Miss judgment counts here for two reasons:
            -- 1. we want jumps/hands to count as more than 1 here
            -- 2. stepcharts can have non-1 #COMBOS parameters set which would artbitraily inflate notesHitThisGame


            for judgment, judgment_count in pairs(stats.judgments) do
                if judgment ~= "Miss" then
                    notesHitThisGame = notesHitThisGame + judgment_count
                end
            end
        end
    end

    local hours = math.floor(totalTime/3600)
    local minutes = math.floor((totalTime-(hours*3600))/60)
    local seconds = round(totalTime%60)

    return { 
        totalTime = totalTime, 
        hours = hours,
        minutes = minutes, 
        seconds = seconds, 
        songsPlayedThisGame = songsPlayedThisGame, 
        notesHitThisGame = notesHitThisGame,
        restartCountThisGame = restartCountThisGame }

end

UpdateSessionDataOnRestart = function(player)

    local TNSTypes = {
        'TapNoteScore_W1',
        'TapNoteScore_W2',
        'TapNoteScore_W3',
        'TapNoteScore_W4',
        'TapNoteScore_W5',
        'TapNoteScore_Miss'
    }

    SL[ToEnumShortString(player)].Stages.Stats[SL.Global.Stages.PlayedThisGame].duration = GetTimeSinceStart() - SL.StageStartTime

    local storage = SL[ToEnumShortString(player)].Stages.Stats[SL.Global.Stages.PlayedThisGame]
	local pss = STATSMAN:GetCurStageStats():GetPlayerStageStats(player)
    
    storage.isRestart = true
	storage.grade = pss:GetGrade()
	storage.score = pss:GetPercentDancePoints()
	storage.judgments = {
			W1 = pss:GetTapNoteScores(TNSTypes[1]),
			W2 = pss:GetTapNoteScores(TNSTypes[2]),
			W3 = pss:GetTapNoteScores(TNSTypes[3]),
			W4 = pss:GetTapNoteScores(TNSTypes[4]),
			W5 = pss:GetTapNoteScores(TNSTypes[5]),
			Miss = pss:GetTapNoteScores(TNSTypes[6])
		}
	if GAMESTATE:IsCourseMode() then
		storage.steps      = GAMESTATE:GetCurrentTrail(player)
		storage.difficulty = storage.steps:GetDifficulty()
		storage.meter      = storage.steps:GetMeter()
		storage.stepartist = GAMESTATE:GetCurrentCourse(player):GetScripter()
	else
		storage.steps      = GAMESTATE:GetCurrentSteps(player)
		storage.difficulty = pss:GetPlayedSteps()[1]:GetDifficulty()
		storage.meter      = pss:GetPlayedSteps()[1]:GetMeter()
		storage.stepartist = pss:GetPlayedSteps()[1]:GetAuthorCredit()
	end
end

