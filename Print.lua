function ActionBarSaver:PrintCopyData(actionBars)
	local copyData = self:GetCopyStore().copy
	if copyData == nil then
		self:Print("No copied action bar data.")
		return
	end

	-- Restrict to the slot ranges of the given bars, if provided.
	local allowedSlots = nil
	if actionBars ~= nil then
		allowedSlots = {}
		for _, actionBar in pairs(actionBars) do
			local firstSlot = self:GetActionBarFirstSlot(actionBar)
			local lastSlot = firstSlot + 11
			for slot = firstSlot, lastSlot do
				allowedSlots[slot] = true
			end
		end
	end

	local slots = {}
	for slot, _ in pairs(copyData) do
		if allowedSlots == nil or allowedSlots[slot] then
			table.insert(slots, slot)
		end
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
