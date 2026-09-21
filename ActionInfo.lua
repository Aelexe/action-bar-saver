function ActionBarSaver:GetActionDisplayName(actionType, id, subType)
	if actionType == "spell" then
		return C_Spell.GetSpellName(id) or GetSpellInfo(id)
	elseif actionType == "item" then
		local itemName = C_Item.GetItemNameByID(id)
		if itemName then
			return itemName
		end

		local cachedItemName = GetItemInfo(id)
		return cachedItemName
	elseif actionType == "macro" then
		return id
	elseif actionType == "summonmount" then
		local mountName = C_MountJournal.GetMountInfoByID(id)
		return mountName
	elseif actionType == "companion" and subType == "MOUNT" then
		return C_Spell.GetSpellName(id) or GetSpellInfo(id)
	end

	return nil
end

function ActionBarSaver:GetActionIcon(actionType, id, subType)
	if actionType == "spell" then
		return C_Spell.GetSpellTexture(id)
	elseif actionType == "item" then
		return C_Item.GetItemIconByID(id) or select(10, GetItemInfo(id))
	elseif actionType == "macro" then
		local macroIndex = GetMacroIndexByName(id)
		if macroIndex and macroIndex > 0 then
			local _, icon = GetMacroInfo(macroIndex)
			return icon
		end
	elseif actionType == "summonmount" then
		local _, _, icon = C_MountJournal.GetMountInfoByID(id)
		return icon
	elseif actionType == "summonpet" then
		local _, icon = C_PetJournal.GetPetInfoByPetID(id)
		return icon
	elseif actionType == "flyout" and GetSpellTexture then
		-- Flyout icons share the spell texture lookup.
		return GetSpellTexture(id)
	elseif actionType == "companion" and subType == "MOUNT" then
		return C_Spell.GetSpellTexture(id)
	end

	return nil
end

-- Fallback icon used when rendering slot previews for unrecognized actions.
local UNKNOWN_ACTION_ICON = 134400 -- Interface\Icons\INV_Misc_QuestionMark
local EMPTY_SLOT_BACKDROP = "Interface\\Buttons\\UI-EmptySlot" -- bordered square used by empty action buttons

function ActionBarSaver:GetSlotIconInfo(details)
	if details == nil then
		return nil, nil
	elseif details == "nil" then
		return EMPTY_SLOT_BACKDROP, "Empty"
	end

	local icon = self:GetActionIcon(details.actionType, details.id, details.subType)
	local name = self:GetActionDisplayName(details.actionType, details.id, details.subType)
	return icon or UNKNOWN_ACTION_ICON, name or details.actionType
end
