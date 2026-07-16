ActionBarSaver = LibStub("AceAddon-3.0"):NewAddon("Action Bar Saver", "AceConsole-3.0")

function ActionBarSaver:OnInitialize()
	-- Database Setup
	local default = {
		version = 1,
	}

	self.db = LibStub("AceDB-3.0"):New("ActionBarSaverDB", { profile = default }, true)

	self:RegisterChatCommand("actionbarsaver", "SlashFunc")
	self:RegisterChatCommand("abs", "SlashFunc")
end

function ActionBarSaver:SlashFunc(input)
	local command, bars = self:GetArgs(input, 5)

	-- If command is nil print an error message.
	if command == nil then
		self:Print("Invalid command.")
		return
	end

	if command == "copy" then
		if bars == nil then
			self:Print("No bars provided.")
			return
		end

		local barList = self:ParseBarList(bars)
		if barList == nil then
			self:Print("Invalid bars provided.")
			return
		end

		self:CopyBars(barList)
	elseif command == "paste" then
		if bars == nil then
			self:PasteBars()
			return
		end

		local barList = self:ParseBarList(bars)
		if barList == nil then
			self:Print("Invalid bars provided.")
			return
		end

		self:PasteBars(barList)
	elseif command == "clear" then
		if bars == nil then
			self:ClearCopiedBars()
			return
		end

		local barList = self:ParseBarList(bars)
		if barList == nil then
			self:Print("Invalid bars provided.")
			return
		end

		self:ClearCopiedBars(barList)
	elseif command == "print" then
		self:PrintCopyData()
	end
end

function ActionBarSaver:ParseBarList(bars)
	-- Split bars by comma.
	local barList = { strsplit(",", bars) }

	-- If first index is all then include all bars from 1 - 15.
	if barList[1] == "all" then
		return { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 }
	end

	-- Convert bars into numbers and validate range.
	for i, bar in ipairs(barList) do
		local barNumber = tonumber(bar)
		if barNumber == nil or barNumber < 1 or barNumber > 15 then
			return nil
		end
		barList[i] = barNumber
	end

	return barList
end

function ActionBarSaver:CopyBars(actionBars)
	print("Copying bars: " .. table.concat(actionBars, ", "))

	if type(self.db.profile.copy) ~= "table" then
		self.db.profile.copy = {}
	end

	-- For each bar copy the slots.
	for i, actionBar in pairs(actionBars) do
		local firstSlot = self:GetActionBarFirstSlot(actionBar);
		local lastSlot = firstSlot + 11;

		for slot = firstSlot, lastSlot do
			local actionType, id, subType = GetActionInfo(slot)

			if actionType then
				if (actionType == "macro") then
					id = GetActionText(slot)
				end
				self.db.profile.copy[slot] = { actionType = actionType, id = id, subType = subType }
			else
				self.db.profile.copy[slot] = "nil"
			end
		end
	end
end

function ActionBarSaver:ClearCopiedBars(actionBars)
	if actionBars == nil then
		self.db.profile.copy = {}
		self:Print("Cleared all copied action bar data.")
		return
	end

	if type(self.db.profile.copy) ~= "table" then
		self.db.profile.copy = {}
	end

	for _, actionBar in pairs(actionBars) do
		local firstSlot = self:GetActionBarFirstSlot(actionBar)
		local lastSlot = firstSlot + 11

		for slot = firstSlot, lastSlot do
			self.db.profile.copy[slot] = nil
		end
	end

	self:Print("Cleared copied data for bars: " .. table.concat(actionBars, ", "))
end

function ActionBarSaver:PasteBars(actionBars)
	if actionBars == nil then
		actionBars = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 }
	end

	if type(self.db.profile.copy) ~= "table" then
		self:Print("No copied action bar data.")
		return
	end

	print("Pasting bars: " .. table.concat(actionBars, ", "))
	ClearCursor()

	for _, actionBar in pairs(actionBars) do
		local firstSlot = self:GetActionBarFirstSlot(actionBar)
		local lastSlot = firstSlot + 11

		for slot = firstSlot, lastSlot do
			self:PasteActionToSlot(slot, self.db.profile.copy[slot])
		end
	end

	ClearCursor()
end

function ActionBarSaver:PasteActionToSlot(slot, details)
	if details == nil then
		return
	end

	if details == "nil" then
		PickupAction(slot)
	else
		local actionType = details.actionType
		local id = details.id
		local subType = details.subType

		if actionType == "spell" then
			C_Spell.PickupSpell(id)
			PlaceAction(slot)
		elseif actionType == "item" then
			C_Item.PickupItem(id)
			PlaceAction(slot)
		elseif actionType == "macro" then
			PickupMacro(id)
			PlaceAction(slot)
		elseif actionType == "summonmount" then
			local _name, spellId = C_MountJournal.GetMountInfoByID(id)
			C_Spell.PickupSpell(spellId)
			PlaceAction(slot)
		elseif actionType == "summonpet" then
			C_PetJournal.PickupPet(id)
			PlaceAction(slot)
		elseif actionType == "flyout" then
			local spellBookSlot = self:GetFlyoutSpellBookSlot(id)
			if spellBookSlot ~= nil then
				if C_SpellBook and C_SpellBook.PickupSpellBookItem and Enum and Enum.SpellBookSpellBank then
					C_SpellBook.PickupSpellBookItem(spellBookSlot, Enum.SpellBookSpellBank.Player)
				elseif PickupSpellBookItem and BOOKTYPE_SPELL then
					PickupSpellBookItem(spellBookSlot, BOOKTYPE_SPELL)
				end

				PlaceAction(slot)
			else
				self:Print("Unable to restore flyout on slot " .. slot .. ".")
			end
		elseif actionType == "companion" and subType == "MOUNT" then
			C_Spell.PickupSpell(id)
			PlaceAction(slot)
		else
			ActionBarSaver:Print("Slot: " .. slot)
			DevTools_Dump(details)
		end
	end

	ClearCursor()
end

function ActionBarSaver:GetFlyoutSpellBookSlot(flyoutID)
	if type(flyoutID) ~= "number" then
		return nil
	end

	-- Retail 11.0+ path.
	if C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines and C_SpellBook.GetSpellBookSkillLineInfo and C_SpellBook.GetSpellBookItemType and Enum and Enum.SpellBookSpellBank and Enum.SpellBookItemType then
		for skillLineIndex = 1, C_SpellBook.GetNumSpellBookSkillLines() do
			local skillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo(skillLineIndex)
			if skillLineInfo then
				local offset = skillLineInfo.itemIndexOffset or 0
				local numSlots = skillLineInfo.numSpellBookItems or 0
				for slotIndex = offset + 1, offset + numSlots do
					local itemType, actionID = C_SpellBook.GetSpellBookItemType(slotIndex, Enum.SpellBookSpellBank
					.Player)
					if itemType == Enum.SpellBookItemType.Flyout and actionID == flyoutID then
						return slotIndex
					end
				end
			end
		end
	end

	-- Legacy path.
	if GetNumSpellTabs and GetSpellTabInfo and GetSpellBookItemInfo and BOOKTYPE_SPELL then
		for tabIndex = 1, GetNumSpellTabs() do
			local _, _, offset, numSlots = GetSpellTabInfo(tabIndex)
			for slotIndex = offset + 1, offset + numSlots do
				local spellType, id = GetSpellBookItemInfo(slotIndex, BOOKTYPE_SPELL)
				if spellType == "FLYOUT" and id == flyoutID then
					return slotIndex
				end
			end
		end
	end

	return nil
end

function ActionBarSaver:GetActionBarFirstSlot(actionBar)
	-- WoW action bar slot mapping (based on https://warcraft.wiki.gg/wiki/Action_Bar)
	local actionBarSlots = {
		[1] = 1, -- Action Bar 1: slots 1-12
		[2] = 61, -- Action Bar 2: slots 61-72
		[3] = 49, -- Action Bar 3: slots 49-60
		[4] = 25, -- Action Bar 4: slots 25-36
		[5] = 37, -- Action Bar 5: slots 37-48
		[6] = 145, -- Action Bar 6: slots 145-156
		[7] = 157, -- Action Bar 7: slots 157-168
		[8] = 169, -- Action Bar 8: slots 169-180
		[9] = 73, -- Bonus Bar 1: slots 73-84
		[10] = 85, -- Bonus Bar 2: slots 85-96
		[11] = 97, -- Bonus Bar 3: slots 97-108
		[12] = 109, -- Bonus Bar 4: slots 109-120
		[13] = 121, -- Bonus Bar 5: slots 121-132
		[14] = 133, -- Bonus Bar 6: slots 133-144
		[15] = 13, -- Action Bar 1 - Page 2: slots 13-24
	}

	return actionBarSlots[actionBar] or 1
end

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

function ActionBarSaver:PrintCopyData()
	local copyData = self.db.profile.copy
	if copyData == nil then
		self:Print("No copied action bar data.")
		return
	end

	local slots = {}
	for slot, _ in pairs(copyData) do
		table.insert(slots, slot)
	end

	if #slots == 0 then
		self:Print("No copied action bar data.")
		return
	end

	table.sort(slots)
	self:Print("Copied action bar data:")

	for _, slot in ipairs(slots) do
		local details = copyData[slot]

		if details == "nil" then
			self:Print("empty")
		elseif type(details) == "table" then
			local actionType = details.actionType
			local id = details.id
			local subType = details.subType
			local actionName = self:GetActionDisplayName(actionType, id, subType)
			local displayType = tostring(actionType or "unknown")
			local displayValue = tostring(actionName or id)

			self:Print(displayType .. ": " .. displayValue)
		else
			self:Print(tostring(details))
		end
	end
end
