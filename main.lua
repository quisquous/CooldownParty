PlayerTrackers = {}

-- debugging
GlobalText = {}

Debug = function(text)
	if GlobalText.Text == nil then
		return
	end
	GlobalText.Text = GlobalText.Text .. "\n" .. text
end

UI.OnLoad = function()
	Initialize()
end

UI.OnFrame = function(ticks)
	ProcessEvents(ticks)
end

CooldownIcon = {}
CooldownIcon.__index = CooldownIcon
function CooldownIcon:new(filepath, x, y, w, h, showShame)
	local self = setmetatable({}, CooldownIcon)
	
	self.ShowShame = showShame
	self._Showing = false
	
	local fontSize = 32
	local fontWeight = 400
	local fontFamily = "Sansation"
	local fontForeColor = "#FFFFFFFF"
	local fontShadowColor = "#FF000000"
	local fontShadowOffset = 1
	
	self._Icon = UI.NewTexture('Background')
	self._Icon.X = x
	self._Icon.Y = y
	self._Icon.Width = w
	self._Icon.Height = h
	self._Icon.FilePath = filepath
	
	self._ShadeRect = UI.NewRectangle('Low')
	self._ShadeRect.X = x
	self._ShadeRect.Y = y
	self._ShadeRect.Width = w
	self._ShadeRect.Height = h
	self._ShadeRect.Color = "#88000000"
	
	self._TextShadow1 = UI.NewLabel('Medium')
	self._TextShadow1.FontSize = fontSize
	self._TextShadow1.X = x + fontShadowOffset
	self._TextShadow1.Y = y + fontShadowOffset
	self._TextShadow1.Width = w
	self._TextShadow1.Height = h
	self._TextShadow1.TextAlignment = 2
	self._TextShadow1.ParagraphAlignment = 2
	self._TextShadow1.Color = fontShadowColor
	self._TextShadow1.FontFamily = fontFamily
	self._TextShadow1.FontWeight = fontWeight
	
	self._TextShadow2 = UI.NewLabel('Medium')
	self._TextShadow2.FontSize = fontSize
	self._TextShadow2.X = x - fontShadowOffset
	self._TextShadow2.Y = y - fontShadowOffset
	self._TextShadow2.Width = w
	self._TextShadow2.Height = h
	self._TextShadow2.TextAlignment = 2
	self._TextShadow2.ParagraphAlignment = 2
	self._TextShadow2.Color = fontShadowColor
	self._TextShadow2.FontFamily = fontFamily
	self._TextShadow2.FontWeight = fontWeight
	
	self._MainText = UI.NewLabel('High')
	self._MainText.FontSize = fontSize
	self._MainText.X = x
	self._MainText.Y = y
	self._MainText.Width = w
	self._MainText.Height = h
	self._MainText.TextAlignment = 2
	self._MainText.ParagraphAlignment = 2
	self._MainText.Color = fontForeColor
	self._MainText.FontFamily = fontFamily
	self._MainText.FontWeight = fontWeight
	
	self.Time = -1
	self:SetTime(0)
	
	return self
end

function CooldownIcon:SetTime(t)
	if self.Time == t then
		return
	end
	self.Time = math.max(-999, math.min(999, t))
	self:Update()
end

function CooldownIcon:Update()
	if not self._Showing then 
		return
	end
	
	if self.Time < 0 and self.ShowShame then
		self._MainText.Text = tostring(-1 * self.Time)
		self._MainText.Color = "#FFCC0000"
	elseif self.Time <= 0 then
		self._MainText.Text = ""
		self._MainText.Color = "#FFFFFFFF"
	else
		self._MainText.Text = tostring(self.Time)
		self._MainText.Color = "#FFFFFFFF"
	end
	self._TextShadow1.Text = self._MainText.Text
	self._TextShadow2.Text = self._MainText.Text
	
	if self.Time < 0 then
		self._MainText.FontSize = 20
	elseif self.Time <= 9 then
		self._MainText.FontSize = 40
	elseif self.Time <= 99 then
		self._MainText.FontSize = 30
	else
		self._MainText.FontSize = 20
	end
	self._TextShadow1.FontSize = self._MainText.FontSize
	self._TextShadow2.FontSize = self._MainText.FontSize
	
	if self.Time > 0 then
		self._ShadeRect:Show()
		self._Icon.BorderColor = "#CCCC0000"
		self._Icon.BorderWidth = 1
	else
		self._ShadeRect:Hide()
		self._Icon.BorderColor = "#CC00CC00"
		self._Icon.BorderWidth = 2
	end
end

function CooldownIcon:Show()
	self._Showing = true
	self._Icon:Show()
	self._ShadeRect:Show()
	self._TextShadow1:Show()
	self._TextShadow2:Show()
	self._MainText:Show()
	
	-- Not everything is shown, so update too
	self:Update()
end

function CooldownIcon:Hide()
	self._Showing = false
	self._Icon:Hide()
	self._ShadeRect:Hide()
	self._TextShadow1:Hide()
	self._TextShadow2:Hide()
	self._MainText:Hide()
end

PlayerTracker = {}
PlayerTracker.__index = PlayerTracker
function PlayerTracker:new(playerID, x, y, w, h)
	local self = setmetatable({}, PlayerTracker)
	self._Showing = false
	self._X = x
	self._Y = y
	self._W = w
	self._H = h
	self._Margin = 2
	self._LastUseBySkill = {}
	self._SkillMap = {}
	self._IconList = {}
	self._Job = nil
	return self
end

function PlayerTracker:UseSkill(skillID, ticks)
	self._LastUseBySkill[skillID] = ticks
	Debug("Use skill: " .. skillID)
end

function PlayerTracker:Update(ticks)
	for skillID, icon in pairs(self._IconList) do
		local lastUse = self._LastUseBySkill[skillID]
		if lastUse ~= nil then
			local cooldownSeconds = self._SkillMap[skillID].Recast
			local seconds = math.ceil((lastUse - ticks) / 1000 + cooldownSeconds)
			icon:SetTime(seconds)
		end
	end
end

function PlayerTracker:SetJob(jobName)
	if self._Job == jobName then
		return
	end

	local wasShowing = self._Showing
	self:Hide()

	self._Job = jobName
	self._IconList = {}
	self._SkillMap = {}
	-- Changing jobs is really confusing.  Some skills stay on cooldown (benediction),
	-- but others with the same skill ID may reset if in a sanctuary (swiftcast).
	-- Give up and assume everything is reset.  /o\
	self._LastUseBySkill = {}
	
	-- TODO: Make a per-job config file, i.e. whm = { "Swiftcast", "Benediction" }
	-- for both ordering and which skills are wanted to be displayed rather than
	-- just using everything in the constant list.
	local skillList = _Cooldowns[jobName]
	if skillList == nil then
		return
	end
	local x = self._X
	local y = self._Y
	for i = 1, #skillList do
		local skill = skillList[i]
		self._IconList[skill.ID] = self:_MakeIcon(skill, x, y)
		self._SkillMap[skill.ID] = skill
		Debug(tostring(i) .. ", " .. skill.Name .. ", " .. skill.ID .. ", " .. x .. ", " .. tostring(self._IconList[skill.ID]))
		x = x + self._W + self._Margin
	end

	if wasShowing then
		self:Show()
	end
end

function PlayerTracker:_MakeIcon(skill, x, y)
	local iconFolder = "Icons/"
	local shame = false -- TODO: use skill.Shame once updates take "in combat" into account
	local icon = CooldownIcon:new(iconFolder .. skill.Icon, x, y, self._W, self._H, shame)
	return icon
end

function PlayerTracker:Show()
	self._Showing = true
	for _, icon in pairs(self._IconList) do
		icon:Show()
	end
end

function PlayerTracker:Hide()
	self._Showing = false
	for _, icon in pairs(self._IconList) do
		icon:Hide()
	end
end

function Initialize()
	GlobalText = UI.NewLabel('High')
	GlobalText.FontSize = 12
	GlobalText.X = 20
	GlobalText.Y = 300
	GlobalText.Width = 500
	GlobalText.Height = 500
	GlobalText.Color = "#FFFFFFFF"
	GlobalText.FontFamily = "Sansation"
	GlobalText.FontWeight = 200
	GlobalText:Show()
end

function ProcessEvents(ticks)
	local player = FF.GetPlayer()
	if player == nil then
		return
	end

	-- Hack player in for now before finding party list
	if player and PlayerTrackers[player.ID] == nil then
		PlayerTrackers[player.ID] = PlayerTracker:new(player.ID, 100, 200, 40, 40)
		PlayerTrackers[player.ID]:Show()
	end
	if player then
		PlayerTrackers[player.ID]:SetJob(player.Job)
	end

	local combatEvents = FF.GetAllCombatEvents()
	for i = 0, combatEvents.Length - 1 do
		local event = combatEvents[i]
		if event.MessageType == "SingleAbility" then
			if PlayerTrackers[event.ActorID] then
				PlayerTrackers[event.ActorID]:UseSkill(event.SkillID, ticks)
			end
		end
	end
	for _, tracker in pairs(PlayerTrackers) do
		tracker:Update(ticks)
	end
end