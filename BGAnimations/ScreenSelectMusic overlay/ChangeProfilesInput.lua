local args = ...
local af = args.af
local scrollers = args.Scrollers
local profile_data = args.ProfileData

-- a simple boolean flag we'll use to ignore input once profiles have been
-- selected and the screen's OffCommand has been queued.
local finished = false

-- we need to calculate how many dummy rows the scroller was "padded" with
-- (to achieve the desired transform behavior since I am not mathematically
-- perspicacious enough to have done so otherwise).
-- we'll use index_padding to get the correct info out of profile_data.
local index_padding = 0

for profile in ivalues(profile_data) do
    if profile.index == nil or profile.index <= 0 then
        index_padding = index_padding + 1
    end
end

local Handle = {}

Handle.Start = function(event)
    -- if the input event came from a side that is not currently registered as a human player, we'll either
    -- want to reject the input (we're in Pay mode and there aren't enough credits to join the player),
    -- or we'll join the player.
    if not GAMESTATE:IsHumanPlayer(event.PlayerNumber) then
        -- IsArcade() is defined in _fallback/Scripts/02 Utilities.lua
        -- in CoinMode_Free, EnoughCreditsToJoin() will always return true
        -- thankfully, EnoughCreditsToJoin() factors in Premium settings
        if IsArcade() and not GAMESTATE:EnoughCreditsToJoin() then
            -- play the InvalidChoice sound and don't go any further
            MESSAGEMAN:Broadcast("InvalidChoice", {PlayerNumber=event.PlayerNumber})
            return
        end

        -- join the player
        GAMESTATE:JoinInput(event.PlayerNumber)
    else
        -- we only bother checking scrollers to see if both players are
        -- trying to choose the same profile if there are scrollers because
        -- there are local profiles. If there are no local profiles, there are
        -- no scrollers to compare.
        if PROFILEMAN:GetNumLocalProfiles() > 0
                -- and if both players have joined and neither is using a memorycard
                and #GAMESTATE:GetHumanPlayers() > 1 and not GAMESTATE:IsAnyHumanPlayerUsingMemoryCard() then
            -- and both players are trying to choose the same profile
            if scrollers[PLAYER_1]:get_info_at_focus_pos().index == scrollers[PLAYER_2]:get_info_at_focus_pos().index
                    -- and that profile they are both trying to choose isn't [GUEST]
                    and scrollers[PLAYER_1]:get_info_at_focus_pos().index ~= 0 then
                -- broadcast an InvalidChoice message to play the "Common invalid" sound
                -- and "shake" the playerframe for the player that just pressed start
                MESSAGEMAN:Broadcast("InvalidChoice", {PlayerNumber=event.PlayerNumber})
                return
            end
        end

        finished = true

        -- play the StartButton sound
        MESSAGEMAN:Broadcast("StartButton")

        af:queuecommand("SelectProfiles")
    end
end

Handle.Center = Handle.Start


Handle.MenuLeft = function(event)
    if GAMESTATE:IsHumanPlayer(event.PlayerNumber) and MEMCARDMAN:GetCardState(event.PlayerNumber) == 'MemoryCardState_none' then
        local info = scrollers[event.PlayerNumber]:get_info_at_focus_pos()
        local index = type(info)=="table" and info.index or 0

        if index - 1 >= 0 then
            MESSAGEMAN:Broadcast("DirectionButton")
            scrollers[event.PlayerNumber]:scroll_by_amount(-1)

            local data = profile_data[index+index_padding-1]
            local frame = af:GetChild(ToEnumShortString(event.PlayerNumber) .. 'Frame')
            frame:GetChild("SelectedProfileText"):settext(data and data.displayname or "")
            frame:playcommand("Set", data)
        end
    end
end

Handle.MenuUp = Handle.MenuLeft
Handle.DownLeft = Handle.MenuLeft

Handle.MenuRight = function(event)
    if GAMESTATE:IsHumanPlayer(event.PlayerNumber) and MEMCARDMAN:GetCardState(event.PlayerNumber) == 'MemoryCardState_none' then
        local info = scrollers[event.PlayerNumber]:get_info_at_focus_pos()
        local index = type(info)=="table" and info.index or 0

        if index+1 <= PROFILEMAN:GetNumLocalProfiles() then
            MESSAGEMAN:Broadcast("DirectionButton")
            scrollers[event.PlayerNumber]:scroll_by_amount(1)

            local data = profile_data[index+index_padding+1]
            local frame = af:GetChild(ToEnumShortString(event.PlayerNumber) .. 'Frame')
            frame:GetChild("SelectedProfileText"):settext(data and data.displayname or "")
            frame:playcommand("Set", data)
        end
    end
end

Handle.MenuDown = Handle.MenuRight
Handle.DownRight = Handle.MenuRight

Handle.Back = function(event)
    af:queuecommand("Cancel")
end

local InputHandler = function(event)
    if finished then return false end
    if not event or not event.button then return false end

    if event.type ~= "InputEventType_Release" then
        if Handle[event.GameButton] then Handle[event.GameButton](event) end
    end
end

return InputHandler
