local ADDON_VERSION = "1.1.1"
local SLOT_NAMES = {
  [1]="Head",[2]="Neck",[3]="Shoulder",[5]="Chest",[6]="Waist",[7]="Legs",
  [8]="Feet",[9]="Wrist",[10]="Hands",[11]="Finger 1",[12]="Finger 2",
  [13]="Trinket 1",[14]="Trinket 2",[15]="Back",[16]="Main Hand",
  [17]="Off Hand",[18]="Ranged"
}

local function jsonEscape(value)
  value = tostring(value or "")
  value = value:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t")
  return '"' .. value .. '"'
end

local function safeNumber(value, fallback)
  value = tonumber(value)
  if value == nil then return fallback or 0 end
  return value
end

local function itemLevel(link)
  if not link then return 0 end
  if C_Item and C_Item.GetDetailedItemLevelInfo then
    return safeNumber(C_Item.GetDetailedItemLevelInfo(link), 0)
  end
  if GetDetailedItemLevelInfo then return safeNumber(GetDetailedItemLevelInfo(link), 0) end
  local _, _, _, level = GetItemInfo(link)
  return safeNumber(level, 0)
end

local function itemId(link)
  return safeNumber(link and link:match("item:(%d+)") or 0, 0)
end

local function itemName(link)
  return link and (link:match("%[(.-)%]") or "") or ""
end

local function talentData()
  local rows, bestName, bestPoints = {}, "", -1
  if GetNumTalentTabs and GetTalentTabInfo then
    for i=1,safeNumber(GetNumTalentTabs(),0) do
      local a,b,c,d,e = GetTalentTabInfo(i)
      local name, points = tostring(a or b or ("Tree "..i)), 0
      if type(c)=="number" then points=c elseif type(e)=="number" then points=e end
      rows[#rows+1] = {name=name,points=points}
      if points>bestPoints then bestName,bestPoints=name,points end
    end
  end
  if GetSpecialization and GetSpecializationInfo then
    local index=GetSpecialization()
    if index then
      local _,name=GetSpecializationInfo(index)
      if name and name~="" then bestName=name end
    end
  end
  return rows,bestName
end

local function tableRowsJson(rows)
  local out={}
  for _,row in ipairs(rows) do
    out[#out+1] = "{"..jsonEscape("name")..":"..jsonEscape(row.name)..","..jsonEscape("points")..":"..safeNumber(row.points,0).."}"
  end
  return "["..table.concat(out,",").."]"
end

local function equipmentJson()
  local out,total,count={},0,0
  for slot=1,18 do
    local label=SLOT_NAMES[slot]
    if label then
      local link=GetInventoryItemLink("player",slot)
      if link then
        local level=itemLevel(link)
        if level>0 then total=total+level;count=count+1 end
        out[#out+1] = "{"..
          jsonEscape("slot")..":"..slot..","..
          jsonEscape("slotName")..":"..jsonEscape(label)..","..
          jsonEscape("itemId")..":"..itemId(link)..","..
          jsonEscape("name")..":"..jsonEscape(itemName(link))..","..
          jsonEscape("itemLevel")..":"..level..","..
          jsonEscape("link")..":"..jsonEscape(link).."}"
      end
    end
  end
  return "["..table.concat(out,",").."]",(count>0 and total/count or 0)
end

local function buildExport()
  local version,build,buildDate,toc=GetBuildInfo()
  local name,realm=UnitName("player"),GetRealmName()
  local guid=(UnitGUID and UnitGUID("player")) or ""
  local race,raceFile=UnitRace("player")
  local class,classFile=UnitClass("player")
  local talents,spec=talentData()
  local equipment,calculatedAverage=equipmentJson()
  local equippedAverage=calculatedAverage
  if GetAverageItemLevel then
    local _,equipped=GetAverageItemLevel()
    if safeNumber(equipped,0)>0 then equippedAverage=equipped end
  end
  local portal=(GetCVar and GetCVar("portal")) or ""
  local now=(GetServerTime and GetServerTime()) or time()
  return "{"..
    jsonEscape("schemaVersion")..":1,"..
    jsonEscape("addonVersion")..":"..jsonEscape(ADDON_VERSION)..","..
    jsonEscape("capturedAt")..":"..safeNumber(now,0)..","..
    jsonEscape("clientVersion")..":"..jsonEscape(version)..","..
    jsonEscape("clientBuild")..":"..jsonEscape(build)..","..
    jsonEscape("clientBuildDate")..":"..jsonEscape(buildDate)..","..
    jsonEscape("interfaceVersion")..":"..safeNumber(toc,0)..","..
    jsonEscape("projectId")..":"..safeNumber(WOW_PROJECT_ID,0)..","..
    jsonEscape("portal")..":"..jsonEscape(portal)..","..
    jsonEscape("character")..":{"..
      jsonEscape("name")..":"..jsonEscape(name)..","..
      jsonEscape("realm")..":"..jsonEscape(realm)..","..
      jsonEscape("guid")..":"..jsonEscape(guid)..","..
      jsonEscape("level")..":"..safeNumber(UnitLevel("player"),0)..","..
      jsonEscape("race")..":"..jsonEscape(race)..","..
      jsonEscape("raceFile")..":"..jsonEscape(raceFile)..","..
      jsonEscape("class")..":"..jsonEscape(class)..","..
      jsonEscape("classFile")..":"..jsonEscape(classFile)..","..
      jsonEscape("activeSpec")..":"..jsonEscape(spec).."},"..
    jsonEscape("averageItemLevel")..":"..string.format("%.2f",safeNumber(equippedAverage,0))..","..
    jsonEscape("talents")..":"..tableRowsJson(talents)..","..
    jsonEscape("equipment")..":"..equipment..
  "}"
end

local frame=CreateFrame("Frame","VexGuildSyncFrame",UIParent,"BasicFrameTemplateWithInset")
frame:SetSize(720,430);frame:SetPoint("CENTER");frame:SetMovable(true);frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton");frame:SetScript("OnDragStart",frame.StartMoving);frame:SetScript("OnDragStop",frame.StopMovingOrSizing)
frame:Hide()
frame.title=frame:CreateFontString(nil,"OVERLAY","GameFontHighlight")
frame.title:SetPoint("TOP",0,-6);frame.title:SetText("Vex Guild Sync")
local help=frame:CreateFontString(nil,"OVERLAY","GameFontNormal")
help:SetPoint("TOPLEFT",16,-34);help:SetPoint("RIGHT",-16,0);help:SetJustifyH("LEFT")
help:SetText("Press Ctrl+C, then paste this snapshot into My Characters on chatgptguild.com.")
local scroll=CreateFrame("ScrollFrame",nil,frame,"UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT",16,-58);scroll:SetPoint("BOTTOMRIGHT",-34,42)
local edit=CreateFrame("EditBox",nil,scroll)
edit:SetMultiLine(true);edit:SetAutoFocus(false);edit:SetFontObject(ChatFontNormal);edit:SetWidth(650)
edit:SetHeight(320)
edit:SetScript("OnEscapePressed",function() frame:Hide() end)
scroll:SetScrollChild(edit)
local refresh=CreateFrame("Button",nil,frame,"UIPanelButtonTemplate")
refresh:SetSize(120,24);refresh:SetPoint("BOTTOMLEFT",16,12);refresh:SetText("Refresh Snapshot")
refresh:SetScript("OnClick",function() edit:SetText(buildExport());edit:HighlightText();edit:SetFocus() end)

local function showExport()
  edit:SetText(buildExport());frame:Show();edit:HighlightText();edit:SetFocus()
end

SLASH_VEXGUILDSYNC1="/vexsync"
SLASH_VEXGUILDSYNC2="/vgs"
SlashCmdList.VEXGUILDSYNC=showExport

print("|cff67f5c3Vex Guild Sync|r loaded. Type |cffffffff/vexsync|r to export your gear.")
