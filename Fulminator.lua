Fulminator = CreateFrame("frame")
Fulminator:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)

local UpdateSeconds, DelayTime, VisibleTime, FulminationTime, LavaSurgeTime, FulminationOverlayShowing, LavaSurgeOverlayShowing, HasFulminate, HasLavaSurge = 1, 0, 3, 10, 10, false, false, false, false;
Fulminator_Fulminate, Fulminator_LavaSurge, Fulminator_StackCount = true, true, 9;

Fulminator:RegisterEvent("PLAYER_REGEN_DISABLED")

function Fulminator:PLAYER_REGEN_DISABLED()
	Fulminator:Initialize()
end

function Fulminator:HasTalent()
	local _,_,_,_, FulminateRank = GetTalentInfo(1, 13);
	local _,_,_,_, LavaSurgeRank = GetTalentInfo(1, 18);
	if ((FulminateRank ~= 0) or (LavaSurgeRank ~=0)) then
		if (FulmianteRank ~= 0) then
			HasFulminate = true;
		else
			HasFulminate = false;
		end
		if (LavaSurgeRank ~= 0) then
			HasLavaSurge = true;
		else
			HasLavaSurge = false;
		end
		return true;
	else
		HasLavaSurge = false;
		HasFulminate = false;
		return false;
	end
end

function Fulminator:CheckSpec()
	if (Fulminator:HasTalent()) then
		Fulminator:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
	else
		Fulminator:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
	end
end

function Fulminator:Initialize()
	local localizedClass, englishClass = UnitClass("player");
	if (englishClass == "SHAMAN") then
		Fulminator:CheckSpec();
		Fulminator:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED");
		Fulminator:RegisterEvent("CHARACTER_POINTS_CHANGED");
	end

	Fulminator:UnregisterEvent("PLAYER_REGEN_DISABLED");
end

function Fulminator:ACTIVE_TALENT_GROUP_CHANGED()
	Fulminator:CheckSpec();
end

function Fulminator:CHARACTER_POINTS_CHANGED()
	Fulminator:CheckSpec();
end

SlashCmdList["FULMINATOR"] = function() InterfaceOptionsFrame_OpenToCategory("Fulminator") end
SLASH_FULMINATOR1 = '/fulminator';

local Fulmination = {
	id = 403,
	texture = "TEXTURES\\SPELLACTIVATIONOVERLAYS\\MAELSTROM_WEAPON.BLP",
	positions = "TOP",
	scale = 1,
	r = 197, g = 226, b = 246,
}

local LavaSurge = { 
	id = 77762,
	texture = "TEXTURES\\SPELLACTIVATIONOVERLAYS\\BLOOD_SURGE.BLP",
	positions = "LEFT + RIGHT (FLIPPED)",
	scale = 1,
	r = 225, g = 120, b = 0,
}


function Fulminator:ON_UPDATE()
	local CurrentTime = GetTime();
	if (CurrentTime >= DelayTime) then
		DelayTime = (CurrentTime + UpdateSeconds);
		if (FulminationTime ~= 10) then
			FulminationTime = (FulminationTime + UpdateSeconds);
		end
		if (LavaSurgeTime ~= 10) then
			LavaSurgeTime = (LavaSurgeTime + UpdateSeconds);
		end
 	  	if (FulminationTime >= VisibleTime) then
			if (not LavaSurgeOverlayShowing) then
				Fulminator:SetScript("OnUpdate", nil);
			end
			FulminationOverlayShowing = false;
			FulminationTime = 10;
			Fulminator:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED");
			SpellActivationOverlay_HideOverlays(SpellActivationOverlayFrame, Fulmination.id);
		end
 	  	if (LavaSurgeTime >= VisibleTime) then
			if (not FulminationOverlayShowing) then
				Fulminator:SetScript("OnUpdate", nil);
			end
			LavaSurgeOverlayShowing = false;
			LavaSurgeTime = 10;
			SpellActivationOverlay_HideOverlays(SpellActivationOverlayFrame, LavaSurge.id);
		end
 	end
end

function Fulminator:COMBAT_LOG_EVENT_UNFILTERED(e, timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
	if (destName == UnitName("player")) then
		if ((event == "SPELL_ENERGIZE") and (Fulminator_Fulminate) and (HasFulminate)) then
			local spellId, spellName, spellSchool, amount, powerType  = ...;
			if (spellId == 88765) then
				local _,_,_, count = UnitAura("player", GetSpellInfo(324));
				if ((count == Fulminator_StackCount) and (not FulminationOverlayShowing)) then
					FulminationOverlayShowing = true;
					DelayTime, FulminationTime = 0, -1;
					Fulminator:SetScript("OnUpdate", function() Fulminator:ON_UPDATE(); end);
					Fulminator:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED");
					SpellActivationOverlay_ShowAllOverlays(SpellActivationOverlayFrame, Fulmination.id, Fulmination.texture, Fulmination.positions, Fulmination.scale, Fulmination.r, Fulmination.g, Fulmination.b);
				end
			end
		end
	end
	if (destName == nil) then
		if (event == "SPELL_CAST_SUCCESS") and (sourceName == UnitName("player") and (Fulminator_LavaSurge) and (HasLavaSurge)) then
			local spellId, spellName, spellSchool = ...;
			if (spellId == 77762) then
				if LavaSurgeOverlayShowing == false then LavaSurgeOverlayShowing = true; end
				DelayTime, LavaSurgeTime = 0, -1;
				Fulminator:SetScript("OnUpdate", function() Fulminator:ON_UPDATE(); end);
				SpellActivationOverlay_ShowAllOverlays(SpellActivationOverlayFrame, LavaSurge.id, LavaSurge.texture, LavaSurge.positions, LavaSurge.scale, LavaSurge.r, LavaSurge.g, LavaSurge.b);
			end
		end
		if (event == "SPELL_CAST_START") and (sourceName == UnitName("player") and (LavaSurgeOverlayShowing)) then
			local spellId, spellName, spellSchool = ...;
			if (spellId == 51505) then 
				LavaSurgeOverlayShowing = false;
				SpellActivationOverlay_HideOverlays(SpellActivationOverlayFrame, LavaSurge.id);
			end
		end
	end	
end

function Fulminator:UNIT_SPELLCAST_SUCCEEDED(e, unitID, spell, rank, lineID, spellId)
	if ((FulminationOverlayShowing) and (unitID == "player") and (spellId == 8042)) then
		FulminationOverlayShowing = false;
		Fulminator:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED");
		SpellActivationOverlay_HideOverlays(SpellActivationOverlayFrame, Fulmination.id);
	end	
end

--[[
	Options Panel
]]

local FulminatorPanel = CreateFrame("frame", "FulminatorPanel", UIParent);
FulminatorPanel.name = "Fulminator";
InterfaceOptions_AddCategory(FulminatorPanel);

FulminatorPanel:SetScript("OnShow", function()
	FulminatorFulminateButton:SetChecked(Fulminator_Fulminate)
	FulminatorLavaSurgeButton:SetChecked(Fulminator_LavaSurge)
	FulminatorStackSlider:SetValue(Fulminator_StackCount)
end)

local title = FulminatorPanel:CreateFontString("FulminatorConfigTitle", "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("Fulminator")

local FulminateEnable = CreateFrame("CheckButton", "FulminatorFulminateButton", FulminatorPanel)
FulminateEnable:SetWidth(26)
FulminateEnable:SetHeight(26)
FulminateEnable:SetPoint("TOPLEFT", 16, -35)
FulminateEnable:SetScript("OnClick", function(frame)
	local tick = frame:GetChecked()
	if tick then
		PlaySound("igMainMenuOptionCheckBoxOn")
		Fulminator_Fulminate = true
	else
		PlaySound("igMainMenuOptionCheckBoxOff")
		Fulminator_Fulminate = false
	end
end)
FulminateEnable:SetHitRectInsets(0, -200, 0, 0)
FulminateEnable:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
FulminateEnable:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
FulminateEnable:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
FulminateEnable:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")

local FulminateEnableText = FulminateEnable:CreateFontString("FulminatorFulminateButtonTitle", "ARTWORK", "GameFontHighlight")
FulminateEnableText:SetPoint("LEFT", FulminateEnable, "RIGHT", 0, 1)
FulminateEnableText:SetText("Enable Fulminate overlay")

local LavaSurgeEnable = CreateFrame("CheckButton", "FulminatorLavaSurgeButton", FulminatorPanel)
LavaSurgeEnable:SetWidth(26)
LavaSurgeEnable:SetHeight(26)
LavaSurgeEnable:SetPoint("TOPLEFT", 16, -57)
LavaSurgeEnable:SetScript("OnClick", function(frame)
	local tick = frame:GetChecked()
	if tick then
		PlaySound("igMainMenuOptionCheckBoxOn")
		Fulminator_LavaSurge = true
	else
		PlaySound("igMainMenuOptionCheckBoxOff")
		Fulminator_LavaSurge = false
	end
end)
LavaSurgeEnable:SetHitRectInsets(0, -200, 0, 0)
LavaSurgeEnable:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
LavaSurgeEnable:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
LavaSurgeEnable:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
LavaSurgeEnable:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")

local LavaSurgeEnableText = LavaSurgeEnable:CreateFontString("FulminatorLavaSurgeButtonTitle", "ARTWORK", "GameFontHighlight")
LavaSurgeEnableText:SetPoint("LEFT", LavaSurgeEnable, "RIGHT", 0, 1)
LavaSurgeEnableText:SetText("Enable Lava Surge overlay")

CreateFrame("Slider", "FulminatorStackSlider", FulminatorPanel, "OptionsSliderTemplate")
FulminatorStackSlider:SetWidth(335)
FulminatorStackSlider:SetHeight(16)
FulminatorStackSlider:SetPoint("TOPLEFT", 16, -100)
FulminatorStackSliderLow:SetText("4")
FulminatorStackSliderHigh:SetText("9")
FulminatorStackSlider:SetMinMaxValues(4,9)
FulminatorStackSlider:SetValueStep(1)
FulminatorStackSlider:SetScript("OnValueChanged", function(self, value)
	FulminatorStackSliderText:SetFormattedText("Show overlay at %d stacks", value)
	Fulminator_StackCount = value
end)