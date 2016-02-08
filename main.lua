PlayerMap = {}
Icons = {}

GlobalIcon = {}
GlobalText = {}

TempLastTick = 0
TempCooldown = 60

UI.OnLoad = function()
	Initialize()
end

UI.OnFrame = function(ticks)
	ProcessEvents(ticks)
	
	local t = math.ceil((TempLastTick - ticks) / 1000 + TempCooldown)
	GlobalIcon:SetTime(t)
end

CooldownIcon = {}
function CooldownIcon:new(o, filepath, x, y, w, h)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	self.ShowShame = true
	
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
	self:SetTime(56)
	
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

function Initialize()
	GlobalIcon = CooldownIcon:new(nil, "Icons/000000/000461.png", 100, 100, 40, 40)
	GlobalIcon:Show()
	
	GlobalText = UI.NewLabel('High')
	GlobalText.FontSize = 12
	GlobalText.X = 20
	GlobalText.Y = 300
	GlobalText.Width = 500
	GlobalText.Height = 500
	GlobalText.Color = "#FFFFFFFF"
	GlobalText.FontFamily = "Sansation"
	GlobalText.FontWeight = 200
	GlobalText.Text = "foobar"
	GlobalText:Show()
end

function ProcessEvents(ticks)
	local player = FF.GetPlayer()
	local combatEvents = FF.GetAllCombatEvents()
	local i
	for i = 0, combatEvents.Length - 1 do
		local event = combatEvents[i]
		if event.ActorID == player.ID and event.MessageType == "SingleAbility" then
			if event.SkillID == 150 then
				TempLastTick = ticks
			end
			GlobalText.Text = tostring(event.SkillID)
		end
	end
end