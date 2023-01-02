if AZP == nil then AZP = {} end
if AZP.VersionControl == nil then AZP.VersionControl = {} end

AZP.VersionControl["FishingNets"] = 1        -- Change to meta data stuff!!
if AZP.FishinNets == nil then AZP.FishinNets = {} end

local EventFrame = CreateFrame("Frame")
local AddOnLoaded, VarsLoaded = false, false
local ZonesInWhichAddonIsActive = {2022, 2023, 2024, 2025, 2112}
local FishingNetFrame = CreateFrame("Frame", nil, UIParent, "BasicFrameTemplateWithInset")
local TimeSinceLastUpdate = 0
local AllZoneFrames, AllLocFrames, AllStatusBars = {}, {}, {}
local InRightZone = false

function AZP.FishinNets.OnLoad()
    EventFrame:RegisterEvent("ADDON_LOADED")
    EventFrame:RegisterEvent("VARIABLES_LOADED")
    EventFrame:RegisterEvent("ZONE_CHANGED")
    EventFrame:SetScript("OnEvent", function(...) AZP.FishinNets:OnEvent(...) end)

    FishingNetFrameHeight = 30
    FishingNetFrame:SetSize(350, FishingNetFrameHeight)
    FishingNetFrame:SetPoint("CENTER", 600, 350)
    FishingNetFrame.TitleText:SetText(string.format("|cff00ffffAzerPUG's Fishing Nets - v%d|r", AZP.VersionControl["FishingNets"]))

    for curZoneID, curZone in pairs(AZP.FishinNets.NetLocations) do
        local curZoneFrame = CreateFrame("Frame", nil, FishingNetFrame)
        local curZoneFrameHeight = 20
        AllZoneFrames[curZoneID] = curZoneFrame
        if AZP.FishinNets.NetLocations[curZoneID - 1] == nil then  curZoneFrame:SetPoint("TOPLEFT", FishingNetFrame, "TOPLEFT", 0, -25)
        else curZoneFrame:SetPoint("TOPLEFT", AllZoneFrames[curZoneID - 1], "BOTTOMLEFT", 0, 0) end

        FishingNetFrameHeight = FishingNetFrameHeight + 22

        for curLocID, curLocation in pairs(curZone) do
            local curLocFrame = CreateFrame("Frame", nil, curZoneFrame)
            local curLocFrameHeight = 20
            AllLocFrames[curLocID] = curLocFrame
            if AZP.FishinNets.NetLocations[curZoneID][curLocID - 1] == nil then  curLocFrame:SetPoint("TOPLEFT", curZoneFrame, "TOPLEFT", 0, 0)
            else curLocFrame:SetPoint("TOPLEFT", AllLocFrames[curLocID - 1], "BOTTOMLEFT", 0, 0) end
            curLocFrame.Header = curLocFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
            curLocFrame.Header:SetText(string.format("%s - %s", AZP.FishinNets.ZoneNames[curZoneID], AZP.FishinNets.LocationNames[curZoneID][curLocID]))
            curLocFrame.Header:SetSize(FishingNetFrame:GetWidth(), 20)
            curLocFrame.Header:SetPoint("TOPLEFT", 0, 0)

            curZoneFrameHeight = curZoneFrameHeight + 22
            FishingNetFrameHeight = FishingNetFrameHeight + 22

            local i = 1
            for _, curNet in pairs(curLocation) do
                local curName = curLocFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
                curName:SetSize(100, 20)
                curName:SetPoint("TOPLEFT", 7, -22 * i)
                curName:SetText(string.format("[%.2f, %.2f]", curNet.Position.X * 100, curNet.Position.Y * 100))
                local curStatusBar = CreateFrame("StatusBar", nil, curLocFrame)
                AllStatusBars[curNet.ID] = curStatusBar
                curStatusBar:SetSize(FishingNetFrame:GetWidth() - curName:GetWidth() - 25, 20)
                curStatusBar:SetPoint("LEFT", curName, "RIGHT", 5, 0)
                curStatusBar:SetMinMaxValues(0, 36000)
                curStatusBar:SetValue(0)
                curStatusBar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar")
                curStatusBar:SetStatusBarColor(0, 0.5, 1)

                curStatusBar.BG = curStatusBar:CreateTexture(nil, "BACKGROUND")
                curStatusBar.BG:SetTexture("Interface/TARGETINGFRAME/UI-StatusBar")
                curStatusBar.BG:SetAllPoints()
                curStatusBar.BG:SetVertexColor(1, 0, 0)

                curStatusBar.Time = curStatusBar:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
                curStatusBar.Time:SetText("N/A")
                curStatusBar.Time:SetPoint("CENTER", 0, 0)
                curStatusBar.Time:SetSize(180, 20)

                curZoneFrameHeight = curZoneFrameHeight + 22
                curZoneFrame:SetSize(FishingNetFrame:GetWidth(), curZoneFrameHeight)

                curLocFrameHeight = curLocFrameHeight + 22
                curLocFrame:SetSize(FishingNetFrame:GetWidth(), curLocFrameHeight)

                FishingNetFrameHeight = FishingNetFrameHeight + 22
                FishingNetFrame:SetSize(FishingNetFrame:GetWidth(), FishingNetFrameHeight)

                i = i + 1
            end
        end
    end
end

function AZP.FishinNets:ZoneChanged()
    CurrentZone = C_Map.GetBestMapForUnit("PLAYER")
    InRightZone = tContains(ZonesInWhichAddonIsActive, CurrentZone)
end

function AZP.FishinNets:GetTimeLeft(curNet)
    curStats = AZPTimeLeftSpamps[curNet.ID]
    if curStats == nil or curStats.StartTime + curStats.TimeLeft < time() then
        if InRightZone == true then 
            curTimerInfo = C_UIWidgetManager.GetStatusBarWidgetVisualizationInfo(curNet.ID)
            if curTimerInfo ~= nil then
                AZPTimeLeftSpamps[curNet.ID] = {StartTime = time(), TimeLeft = curTimerInfo.barValue}
                return curTimerInfo.barValue
            end
        end
    else
        return curStats.TimeLeft - (time() - curStats.StartTime)
    end

    return nil
end

function AZP.FishinNets:CheckTimers()
    for curZoneID, curZone in pairs(AZP.FishinNets.NetLocations) do
        for curLocID, curLocation in pairs(curZone) do
            for _, curNet in pairs(curLocation) do
                local TimeLeft = AZP.FishinNets:GetTimeLeft(curNet)
                if TimeLeft == nil then
                    local curStatusBar = AllStatusBars[curNet.ID]
                    curStatusBar:SetValue(0)
                    curStatusBar.Time:SetText("Data Unavailable")
                else
                    local curStatusBar = AllStatusBars[curNet.ID]
                    curStatusBar:SetValue(TimeLeft)

                    local curHours = math.floor(TimeLeft / 3600)
                    local curMinutes = math.floor((TimeLeft - (curHours * 3600)) / 60)
                    local curSeconds = math.floor(TimeLeft - (curHours * 3600) - (curMinutes * 60))

                    local curTimeText = string.format("%02d:%02d:%02d", curHours, curMinutes, curSeconds)
                    curStatusBar.Time:SetText(curTimeText)
                end
            end
        end
    end
end

function AZP.FishinNets:OnUpdate(Elapsed)
    local Interval = 1
    TimeSinceLastUpdate = TimeSinceLastUpdate + Elapsed
    if (TimeSinceLastUpdate > Interval) then
        TimeSinceLastUpdate = 0
        AZP.FishinNets:CheckTimers()
    end
end

function AZP.FishinNets:VarsAndAddOnLoaded()
    if AZPTimeLeftSpamps == nil then
        AZPTimeLeftSpamps = {}
    end
    AZP.FishinNets:ZoneChanged()
    FishingNetFrame:SetScript("OnUpdate", function(_, ...) AZP.FishinNets:OnUpdate(...) end)
end

function AZP.FishinNets:OnEvent(_, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "AzerPUGsFishingNets" then
            if VarsLoaded == true then
                AZP.FishinNets:VarsAndAddOnLoaded()
            else
                AddOnLoaded = true
            end
        end
    elseif event == "VARIABLES_LOADED" then
        
        if AddOnLoaded == true then
            AZP.FishinNets:VarsAndAddOnLoaded()
        else
            VarsLoaded = true
        end
    elseif event == "ZONE_CHANGED" then
        AZP.FishinNets:ZoneChanged()
    end
end

AZP.FishinNets.OnLoad()