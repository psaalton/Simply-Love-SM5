-- a table of profile data (highscore name, most recent song, mods, etc.)
-- indexed by "ProfileIndex" (provided by engine)
local profile_data = LoadActor("../ScreenSelectProfile underlay/PlayerProfileData.lua")

local scrollers = {}
scrollers[PLAYER_1] = setmetatable({disable_wrapping=true}, sick_wheel_mt)
scrollers[PLAYER_2] = setmetatable({disable_wrapping=true}, sick_wheel_mt)

local InputHandler

-- ----------------------------------------------------

local HandleStateChange = function(self, Player)
    local frame = self:GetChild(ToEnumShortString(Player) .. 'Frame')

    local joinframe = frame:GetChild('JoinFrame')
    local scrollerframe = frame:GetChild('ScrollerFrame')
    local seltext = frame:GetChild('SelectedProfileText')
    local usbsprite = frame:GetChild('USBIcon')

    if GAMESTATE:IsHumanPlayer(Player) then
        if MEMCARDMAN:GetCardState(Player) == 'MemoryCardState_none' then
            -- using local profile
            joinframe:visible(false)
            scrollerframe:visible(true)
            seltext:visible(true)
            usbsprite:visible(false)
        else
            -- using memorycard profile
            joinframe:visible(false)
            scrollerframe:visible(false)
            seltext:visible(true):settext(MEMCARDMAN:GetName(Player))
            usbsprite:visible(true)
        end
    else
        joinframe:visible(true)
        scrollerframe:visible(false)
        seltext:visible(false)
        usbsprite:visible(false)
    end
end

-- ----------------------------------------------------

local invalid_count = 0

local t = Def.ActorFrame {
    Name = "ChangeProfiles",

    -- hide at start
    InitCommand=function(self) t = self:visible(false) end,

    ChangeProfilesMessageCommand=function(self)
        self:queuecommand("Show")
    end,

    ShowCommand=function(self)
        local topscreen = SCREENMAN:GetTopScreen()
        if topscreen then
            -- prevent the MusicWheel from continually scrolling in the background because the last
            -- input event before disabling the engine's input handling was a MenuRight
            topscreen:GetMusicWheel():Move(0)

            -- activate our Lua InputHandler
            InputHandler = LoadActor("./ChangeProfilesInput.lua", {af=self, Scrollers=scrollers, ProfileData=profile_data})
            topscreen:AddInputCallback(InputHandler)

            -- disable the engine's input handling
            for player in ivalues(PlayerNumber) do
                SCREENMAN:set_input_redirected(player, true)
            end

            -- make this actor frame visible
            self:visible(true)
        end
    end,

    CancelCommand=function(self)
        local topscreen = SCREENMAN:GetTopScreen()
        if topscreen then
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

    -- the SelectProfilesCommand will have been queued, when it is appropriate, from ./ChangeProfilesInput.lua
    -- sleep for 0.5 seconds to give the PlayerFrames time to tween out
    -- and queue a call to Finish() so that the engine can wrap things up
    SelectProfilesCommand=function(self)
        self:sleep(0.5):queuecommand("Finish")
    end,

    FinishCommand=function(self)
        -- If either/both human players want to *not* use a local profile
        -- (that is, they've chosen the first option, "[Guest]"), ScreenSelectProfile
        -- will not let us leave. The screen's Finish() method expects all human players
        -- to have local profiles they want to use. So, this gets tricky.
        --
        -- Loop through the enum for PlayerNumber that the engine has exposed to Lua.
        for player in ivalues(PlayerNumber) do
            -- check if this player is joined in
            if GAMESTATE:IsHumanPlayer(player) then
                -- this player was joined in, so get the index of their profile scroller as it is now
                local info = scrollers[player]:get_info_at_focus_pos()
                -- if there were no local profiles, there won't be any info
                -- set index to 0 if so to indicate that "[Guest]" was chosen (because it was the only choice)
                local index = type(info)=="table" and info.index or 0

                if index == 0 then
                    GAMESTATE:UnjoinPlayer(player)
                elseif index > 0 then
                    -- in lua Guest profile is index 0, so we need to subtract 1 to get the actual index
                    PROFILEMAN:SetLocalProfileForPlayer(player, index - 1)
                end
            end
        end

        self:queuecommand("Cancel")

        -- reload the Select Music screen to make sure nothing breaks
        SCREENMAN:SetNewScreen("ScreenSelectMusic")
    end,

    WhatMessageCommand=function(self)
        self:runcommandsonleaves(function(subself) if subself.distort then subself:distort(0.5) end end):sleep(4):queuecommand("Undistort")
    end,

    UndistortCommand=function(self)
        self:runcommandsonleaves(function(subself) if subself.distort then subself:distort(0) end end)
    end,

    -- various events can occur that require us to reassess what we're drawing
    OnCommand=function(self) self:queuecommand('Update') end,
    StorageDevicesChangedMessageCommand=function(self) self:queuecommand('Update') end,
    PlayerJoinedMessageCommand=function(self, params) self:playcommand('Update', {player=params.Player}) end,
    PlayerUnjoinedMessageCommand=function(self, params) self:playcommand('Update', {player=params.Player}) end,

    -- there are several ways to get here, but if we're here, we'll just
    -- punt to HandleStateChange() to reassess what is being drawn
    UpdateCommand=function(self, params)
        if params and params.player then
            HandleStateChange(self, params.player)
            return
        end

        HandleStateChange(self, PLAYER_1)
        HandleStateChange(self, PLAYER_2)
    end,

    -- sounds
    LoadActor( THEME:GetPathS("Common", "start") )..{
        StartButtonMessageCommand=function(self) self:play() end
    },
    LoadActor( THEME:GetPathS("ScreenSelectMusic", "select down") )..{
        BackButtonMessageCommand=function(self) self:play() end
    },
    LoadActor( THEME:GetPathS("ScreenSelectMaster", "change") )..{
        DirectionButtonMessageCommand=function(self)
            self:play()
            if invalid_count then invalid_count = 0 end
        end
    },
    LoadActor( THEME:GetPathS("Common", "invalid") )..{
        InvalidChoiceMessageCommand=function(self)
            self:play()
            if invalid_count then
                invalid_count = invalid_count + 1
                if invalid_count >= 10 then MESSAGEMAN:Broadcast("What"); invalid_count = nil end
            end
        end
    },
    LoadActor( THEME:GetPathS("", "what.ogg") )..{
        WhatMessageCommand=function(self) self:play() end
    }
}

-- darkened background
t[#t+1] = Def.Quad{ InitCommand=function(self) self:FullScreen():diffuse(0,0,0,0.925) end }

-- get table of player avatar paths
local avatars = {}
for profile in ivalues(profile_data) do
    if profile.dir and profile.displayname then
        avatars[profile.index] = GetAvatarPath(profile.dir, profile.displayname)
    end
end

-- load PlayerFrames for both players
t[#t+1] = LoadActor("../ScreenSelectProfile underlay/PlayerFrame.lua", {Layer="Overlay", Player=PLAYER_1, Scroller=scrollers[PLAYER_1], ProfileData=profile_data, Avatars=avatars})
t[#t+1] = LoadActor("../ScreenSelectProfile underlay/PlayerFrame.lua", {Layer="Overlay", Player=PLAYER_2, Scroller=scrollers[PLAYER_2], ProfileData=profile_data, Avatars=avatars})

LoadActor("../ScreenSelectProfile underlay/JudgmentGraphicPreviews.lua", {af=t, profile_data=profile_data})
LoadActor("../ScreenSelectProfile underlay/NoteSkinPreviews.lua", {af=t, profile_data=profile_data})

return t
