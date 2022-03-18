if not PREFSMAN:GetPreference("EventMode") then return end

local active_index = 0
local choice_actors = {}
local sfx = {}
local af

local InputHandler = function(event)
	if not event.PlayerNumber or not event.button then return false end

	if event.type == "InputEventType_FirstPress" then
		if event.GameButton == "MenuRight" or event.GameButton == "MenuDown" then
			af:queuecommand("MoveRight")

		elseif event.GameButton == "MenuLeft" or event.GameButton == "MenuUp" then
			af:queuecommand("MoveLeft")

		-- cancel out of this prompt overlay and return to selecting a song
		elseif event.GameButton == "Back" or event.GameButton == "Select" or (event.GameButton == "Start" and active_index == 0) then
			af:queuecommand("Cancel")

		elseif event.GameButton == "Start" and active_index == 1 then
			af:queuecommand("ChangeProfiles")

		-- back out of ScreenSelectMusic and head to either EvaluationSummary (if stages were played) or TitleMenu
		elseif event.GameButton == "Start" and active_index == 2 then
			af:queuecommand("YourFinished")
		end
	end
end


af = Def.ActorFrame{
	-- hide at start
	InitCommand=function(self) af = self:visible(false) end,

	MenuBackPressedCommand=function(self)
		self:queuecommand("Show")
	end,

	-- show the overlay
	ShowCommand=function(self)
		local topscreen = SCREENMAN:GetTopScreen()
		if topscreen then
			-- ensure that the first choice (no) will be active when the prompt overlay first appears
			active_index = 0
			-- make "back" the active_choice
			choice_actors[0]:stoptweening():diffuse(PlayerColor(PLAYER_2)):zoom(0.7)
			-- ensure that other choices are not the active_choice
			choice_actors[1]:stoptweening():diffuse(1,1,1,1):zoom(0.5)
			choice_actors[2]:stoptweening():diffuse(1,1,1,1):zoom(0.5)

			-- prevent the MusicWheel from continually scrolling in the background because the last
			-- input event before disabling the engine's input handling was a MenuRight
			topscreen:GetMusicWheel():Move(0)

			-- activate our Lua InputHandler
			topscreen:AddInputCallback(InputHandler)

			-- disable the engine's input handling
			for player in ivalues(PlayerNumber) do
				SCREENMAN:set_input_redirected(player, true)
			end
			-- make this overlay visible
			self:visible(true)
		end
	end,

	MoveLeftCommand=function(self)
		-- old active_choice loses focus
		choice_actors[active_index]:diffuse(1,1,1,1):stoptweening():linear(0.1):zoom(0.5)

		-- update active_index
		active_index = active_index - 1

		if active_index < 0 then
			active_index = #choice_actors
		end

		-- new active_choice gains focus
		choice_actors[active_index]:diffuse(PlayerColor(PLAYER_2)):stoptweening():linear(0.1):zoom(0.7)
		--play sound effect
		sfx.change:play()
	end,
	MoveRightCommand=function(self)
		-- old active_choice loses focus
		choice_actors[active_index]:diffuse(1,1,1,1):stoptweening():linear(0.1):zoom(0.5)

		-- update active_index
		active_index = active_index + 1

		if active_index > #choice_actors then
			active_index = 0
		end

		-- new active_choice gains focus
		choice_actors[active_index]:diffuse(PlayerColor(PLAYER_2)):stoptweening():linear(0.1):zoom(0.7)
		--play sound effect
		sfx.change:play()
	end,
	CancelCommand=function(self)
		local topscreen = SCREENMAN:GetTopScreen()
		if topscreen then
			-- play the start sound effect
			sfx.start:play()
			-- deactivate the Lua InputHandler
			topscreen:RemoveInputCallback(InputHandler)
			-- return input handling to the SM5 engine so players can continue choosing a song
			for player in ivalues(PlayerNumber) do
				SCREENMAN:set_input_redirected(player, false)
			end
			-- hide this overlay
			self:visible(false)
		end
	end,
	ChangeProfilesCommand=function(self)
		local topscreen = SCREENMAN:GetTopScreen()
		if topscreen then
			-- play the start sound effect
			sfx.start:play()
			-- deactivate the Lua InputHandler
			topscreen:RemoveInputCallback(InputHandler)
			-- return input handling to the SM5 engine so players can continue choosing a song
			for player in ivalues(PlayerNumber) do
				SCREENMAN:set_input_redirected(player, false)
			end
			-- hide this overlay
			self:visible(false)
			MESSAGEMAN:Broadcast("ChangeProfiles")
		end
	end,
	-- quit session
	YourFinishedCommand=function(self)
		local topscreen = SCREENMAN:GetTopScreen()
		if topscreen then
			-- play the start sound effect
			sfx.start:play()
			-- return input handling to the SM5 engine before leaving ScreenSelectMusic
			for player in ivalues(PlayerNumber) do
				SCREENMAN:set_input_redirected(player, false)
			end
			-- exit from song wheel, this is what pressing back in the song wheel did before
			topscreen:GoBack()
		end
	end
}

-- sound effects
af[#af+1] = Def.Sound{ File=THEME:GetPathS("ScreenSelectMaster", "change"), InitCommand=function(self) sfx.change = self end }
af[#af+1] = Def.Sound{ File=THEME:GetPathS("Common", "Start"), InitCommand=function(self) sfx.start = self end }

-- darkened background
af[#af+1] = Def.Quad{ InitCommand=function(self) self:FullScreen():diffuse(0,0,0,0.925) end }

-- -------------------------------
-- choices

local choices_af = Def.ActorFrame{
	InitCommand=function(self) self:diffusealpha(0) end,
	OnCommand=function(self) self:sleep(0.333):linear(0.15):diffusealpha(1) end,
}

local back = Def.ActorFrame{
	InitCommand=function(self)
		choice_actors[0] = self
		self:x(_screen.cx)
		self:y(_screen.cy - 40)
	end,

	LoadFont("Common Bold")..{
		Text="Back to Select Music",
		InitCommand=function(self) self:zoom(0.7) end
	},
}

local changeProfiles = Def.ActorFrame{
	InitCommand=function(self)
		choice_actors[1] = self
		self:x(_screen.cx)
		self:y(_screen.cy)
	end,

	LoadFont("Common Bold")..{
		Text="Change profiles",
		InitCommand=function(self) self:zoom(0.7) end
	},
}

local quit = Def.ActorFrame{
	InitCommand=function(self)
		choice_actors[2] = self
		self:x(_screen.cx)
		self:y(_screen.cy + 40)
	end,

	LoadFont("Common Bold")..{
		Text="Quit session",
		InitCommand=function(self) self:zoom(0.7) end
	},
}
-- -------------------------------

table.insert(choices_af, quit)
table.insert(choices_af, changeProfiles)
table.insert(choices_af, back)
table.insert(af, choices_af)

return af
