ActionBarSaver = LibStub("AceAddon-3.0"):NewAddon("Action Bar Saver", "AceConsole-3.0")

function ActionBarSaver:OnInitialize()
	-- Database Setup
	local default = {
		version = 1,
		characterSpecific = false,
		global = { copy = {} },
		characters = {},
	}

	self.db = LibStub("AceDB-3.0"):New("ActionBarSaverDB", { profile = default }, true)

	self:RegisterChatCommand("actionbarsaver", "SlashFunc")
	self:RegisterChatCommand("abs", "SlashFunc")
end

function ActionBarSaver:GetCharacterKey()
	return UnitGUID("player")
end

-- Returns the copy table to read/write, based on the Character Specific setting.
function ActionBarSaver:GetCopyStore()
	if self.db.profile.characterSpecific then
		if type(self.db.profile.characters) ~= "table" then
			self.db.profile.characters = {}
		end

		local key = self:GetCharacterKey()
		if type(self.db.profile.characters[key]) ~= "table" then
			self.db.profile.characters[key] = {}
		end

		return self.db.profile.characters[key]
	end

	if type(self.db.profile.global) ~= "table" then
		self.db.profile.global = {}
	end

	return self.db.profile.global
end

function ActionBarSaver:SlashFunc(input)
	local command, bars = self:GetArgs(input, 5)

	-- If command is nil open the UI instead of printing an error.
	if command == nil then
		self:OpenUI()
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

function ActionBarSaver:HasCopiedData(actionBar)
	local copy = self:GetCopyStore().copy
	if type(copy) ~= "table" then
		return false
	end

	if actionBar == "all" then
		return next(copy) ~= nil
	end

	local firstSlot = self:GetActionBarFirstSlot(actionBar)
	local lastSlot = firstSlot + 11

	for slot = firstSlot, lastSlot do
		if copy[slot] ~= nil then
			return true
		end
	end

	return false
end
