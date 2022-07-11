return Def.ActorFrame{
	CodeMessageCommand=function(self, params)
		if params.Name == "Restart" then
			SL.RestartCounter = SL.RestartCounter + 1 
			SL.Global.Stages.PlayedThisGame = SL.Global.Stages.PlayedThisGame + 1
			for player in ivalues(GAMESTATE:GetHumanPlayers()) do
				UpdateSessionDataOnRestart(player)
			end

			SCREENMAN:SetNewScreen("ScreenGameplay")
		end
	end
}
