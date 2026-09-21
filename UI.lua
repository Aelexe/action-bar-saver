function ActionBarSaver:OpenUI()
	local AceGUI = LibStub("AceGUI-3.0")

	local frame = AceGUI:Create("Frame")
	frame:SetTitle("Action Bar Saver")
	frame:SetStatusText("Copy, paste or clear saved action bars.")
	frame:SetLayout("Fill")

	-- Rows for "All" plus every individual action bar.
	local rows = { { label = "All", key = "all", bars = self:ParseBarList("all") } }
	for i = 1, 15 do
		table.insert(rows, { label = tostring(i), key = i, bars = { i } })
	end

	frame:SetWidth(400)
	frame:SetHeight(500)

	local scroll = AceGUI:Create("ScrollFrame")
	scroll:SetLayout("List")
	frame:AddChild(scroll)

	-- Rebuilds all rows from scratch so bars without copied data don't reserve icon-row space.
	local function RebuildRows()
		scroll:ReleaseChildren()

		local copy = self:GetCopyStore().copy

		for _, row in ipairs(rows) do
			local group = AceGUI:Create("SimpleGroup")
			group:SetLayout("Flow")
			group:SetFullWidth(true)

			local label = AceGUI:Create("Label")
			label:SetText(row.label)
			label:SetWidth(50)
			group:AddChild(label)

			local copyButton = AceGUI:Create("Button")
			copyButton:SetText("Copy")
			copyButton:SetWidth(70)
			copyButton:SetCallback("OnClick", function()
				self:CopyBars(row.bars)
				RebuildRows()
			end)
			group:AddChild(copyButton)

			local hasData = self:HasCopiedData(row.key)

			local pasteButton = AceGUI:Create("Button")
			pasteButton:SetText("Paste")
			pasteButton:SetWidth(70)
			pasteButton:SetDisabled(not hasData)
			pasteButton:SetCallback("OnClick", function()
				self:PasteBars(row.bars)
				RebuildRows()
			end)
			group:AddChild(pasteButton)

			local clearButton = AceGUI:Create("Button")
			clearButton:SetText("Clear")
			clearButton:SetWidth(70)
			clearButton:SetDisabled(not hasData)
			clearButton:SetCallback("OnClick", function()
				self:ClearCopiedBars(row.bars)
				RebuildRows()
			end)
			group:AddChild(clearButton)

			scroll:AddChild(group)

			-- Icon preview of the 12 saved slots, only shown for individual bars that have data.
			if row.key ~= "all" and hasData then
				local iconRow = AceGUI:Create("SimpleGroup")
				iconRow:SetLayout("Flow")
				iconRow:SetFullWidth(true)

				local firstSlot = self:GetActionBarFirstSlot(row.key)
				for slotOffset = 0, 11 do
					local slot = firstSlot + slotOffset
					local details = copy and copy[slot]
					local iconTexture, tooltip = self:GetSlotIconInfo(details)

					local icon = AceGUI:Create("Icon")
					icon:SetImageSize(20, 20)
					icon:SetLabel()
					icon:SetWidth(24)
					icon:SetImage(iconTexture)
					icon:SetUserData("tooltip", tooltip)
					icon:SetCallback("OnEnter", function(widget)
						local widgetTooltip = widget:GetUserData("tooltip")
						if widgetTooltip then
							GameTooltip:SetOwner(widget.frame, "ANCHOR_TOP")
							GameTooltip:SetText(widgetTooltip)
							GameTooltip:Show()
						end
					end)
					icon:SetCallback("OnLeave", function()
						GameTooltip:Hide()
					end)

					iconRow:AddChild(icon)
				end

				scroll:AddChild(iconRow)
			end
		end

		local checkboxGroup = AceGUI:Create("SimpleGroup")
		checkboxGroup:SetLayout("Flow")
		checkboxGroup:SetFullWidth(true)

		local spacer = AceGUI:Create("Label")
		spacer:SetRelativeWidth(0.55)
		checkboxGroup:AddChild(spacer)

		local checkbox = AceGUI:Create("CheckBox")
		checkbox:SetLabel("Character Specific")
		checkbox:SetValue(self.db.profile.characterSpecific)
		checkbox:SetCallback("OnValueChanged", function(_, _, value)
			self.db.profile.characterSpecific = value
			RebuildRows()
		end)
		checkboxGroup:AddChild(checkbox)

		scroll:AddChild(checkboxGroup)
	end

	RebuildRows()
end
