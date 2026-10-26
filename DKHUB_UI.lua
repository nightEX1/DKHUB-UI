-- DKHUB UI v3 (LocalScript)
-- วางใน StarterPlayer > StarterPlayerScripts
-- โมดูลส่วนใหญ่เป็น "โครง" (placeholder) กดแล้วจะขึ้นแจ้งเตือน "ยังใช้ไม่ได้"
-- ที่ใช้งานได้จริงตอนนี้: Anti-AFK, ปรับสี UI, Export/Import config, คัดลอกลิงก์ Discord

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local player = Players.LocalPlayer

---------------------------------------------------------------- ธีม
local T = {
	bg     = Color3.fromRGB(20, 20, 24),
	side   = Color3.fromRGB(26, 26, 31),
	row    = Color3.fromRGB(38, 38, 46),
	rowHov = Color3.fromRGB(48, 48, 58),
	white  = Color3.fromRGB(255, 255, 255),
	text   = Color3.fromRGB(240, 240, 245),
	sub    = Color3.fromRGB(145, 145, 158),
	on     = Color3.fromRGB(46, 204, 90),
	off    = Color3.fromRGB(70, 70, 82),
	badge  = Color3.fromRGB(60, 120, 255),
	font   = Enum.Font.SourceSansBold, -- ฟอนต์หนา
}

---------------------------------------------------------------- โลโก้ / ไอคอน
-- ใส่ ID รูปโลโก้ที่อัปโหลดไว้ (เว้นว่างจะใช้ตัวอักษร DK แทน)
local LOGO_ID = "rbxassetid://86790107799884"
-- ครอปเอาเฉพาะตัว DK ตรงกลางรูป (รูปต้นฉบับ 1024x1024)
local LOGO_RECT_OFFSET = Vector2.new(150, 140)
local LOGO_RECT_SIZE = Vector2.new(660, 660)

---------------------------------------------------------------- ข้อมูลที่แก้ได้ง่าย
local DISCORD_LINK = "https://discord.gg/nScc6x4yqQ"

-- หมวด "อัปเดตใหม่" — เพิ่มรายการใหม่ไว้บนสุด
local UPDATES = {
	{ title = "v0.3", text = "• สคริปต์เดียวรองรับหลายเกม (ตรวจจับอัตโนมัติ)\n• เพิ่มหมวด Main / Automation / Webhook / Setting\n• เพิ่ม Anti-AFK, ปรับสี UI, Export/Import config" },
	{ title = "v0.2", text = "• ขอบขาว + ฟอนต์หนา\n• ย่อเป็นไอคอนลากได้ + แอนิเมชันสมูท\n• ใส่โลโก้ DKHUB" },
	{ title = "v0.1", text = "• สร้างหน้าตา UI เริ่มต้น" },
}

-- หมวด "ประกาศ"
local ANNOUNCEMENTS = {
	{ title = "ยินดีต้อนรับ", text = "ขอบคุณที่ใช้ DKHUB Studio" },
	{ title = "สถานะโมดูล", text = "โมดูลส่วนใหญ่ยังอยู่ระหว่างพัฒนา ปุ่มที่มีป้าย \"เร็ว ๆ นี้\" จะยังกดใช้งานไม่ได้" },
	{ title = "ติดตามข่าวสาร", text = "ประกาศอัปเดตและกิจกรรมใหม่ ๆ จะแจ้งใน Discord" },
}

---------------------------------------------------------------- สถานะ / ตัวแปรกลาง
local Settings = { antiafk = false, accent = { 255, 255, 255 } } -- สิ่งที่ Export/Import config
local Controls = {} -- เก็บตัวควบคุมตาม id (textbox, toggle)
local notify -- กำหนดค่าทีหลัง (ฟังก์ชันแจ้งเตือน)

local accentGrads, accentSolids, swatchMarks = {}, {}, {}

---------------------------------------------------------------- ตัวช่วย
local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end
local function round(o, r) return new("UICorner", { CornerRadius = UDim.new(0, r) }, o) end
local function label(props, parent)
	props.BackgroundTransparency = 1
	props.Font = props.Font or T.font
	props.TextColor3 = props.TextColor3 or T.text
	props.TextSize = props.TextSize or 18
	return new("TextLabel", props, parent)
end
local function tween(o, t, props, style, dir)
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end
local function hover(o, prop, normal, over)
	o.MouseEnter:Connect(function() tween(o, 0.12, { [prop] = over }) end)
	o.MouseLeave:Connect(function() tween(o, 0.12, { [prop] = normal }) end)
end

-- ใส่รูปโลโก้ลงใน parent (คืนค่า true ถ้ามี LOGO_ID)
local function applyLogo(parent, radius)
	if LOGO_ID == "" then return false end
	local img = new("ImageLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = LOGO_ID,
		ImageRectOffset = LOGO_RECT_OFFSET, ImageRectSize = LOGO_RECT_SIZE,
	}, parent)
	round(img, radius)
	return true
end

-- ลากแบบสมูท + แยก "คลิก" ออกจาก "ลาก" (ขยับไม่เกิน 5px นับเป็นคลิก)
local function makeDraggable(handle, target, onClick)
	local dragging, moved, startMouse, startPos = false, false, nil, nil
	local function isPress(i) return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch end
	handle.InputBegan:Connect(function(i)
		if isPress(i) then
			dragging, moved = true, false
			startMouse, startPos = i.Position, target.Position
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - startMouse
			if d.Magnitude > 5 then moved = true end
			if moved then
				tween(target, 0.07, {
					Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y),
				}, Enum.EasingStyle.Sine)
			end
		end
	end)
	UIS.InputEnded:Connect(function(i)
		if dragging and isPress(i) then
			dragging = false
			if not moved and onClick then onClick() end
		end
	end)
end

---------------------------------------------------------------- สี UI (accent)
local function accentSeq(c)
	local dark = c:Lerp(Color3.new(0, 0, 0), 0.25)
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, c),
		ColorSequenceKeypoint.new(0.5, dark),
		ColorSequenceKeypoint.new(1, c),
	})
end
local function trackGrad(g) table.insert(accentGrads, g) return g end
local function trackSolid(o, prop) table.insert(accentSolids, { o, prop }) return o end

local function applyAccent(c)
	Settings.accent = { math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5) }
	for _, g in ipairs(accentGrads) do g.Color = accentSeq(c) end
	for _, t in ipairs(accentSolids) do t[1][t[2]] = c end
	for _, m in ipairs(swatchMarks) do
		local s = m.color
		local same = math.floor(s.R * 255 + 0.5) == Settings.accent[1] and math.floor(s.G * 255 + 0.5) == Settings.accent[2] and math.floor(s.B * 255 + 0.5) == Settings.accent[3]
		tween(m.stroke, 0.15, { Transparency = same and 0 or 1 })
	end
end

---------------------------------------------------------------- ฟังก์ชันที่ใช้งานได้จริง
-- Anti-AFK
local afkConn
local function setAntiAFK(on)
	Settings.antiafk = on
	if on and not afkConn then
		afkConn = player.Idled:Connect(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end)
		notify("เปิด Anti-AFK แล้ว")
	elseif not on and afkConn then
		afkConn:Disconnect()
		afkConn = nil
		notify("ปิด Anti-AFK แล้ว")
	end
end

-- คัดลอกข้อความ (ถ้าเครื่องไม่รองรับ จะบอกให้แตะค้างที่ช่องข้อความ)
local function copyText(txt)
	local ok = pcall(function() setclipboard(txt) end)
	notify(ok and "คัดลอกแล้ว" or "แตะค้างที่ช่องข้อความเพื่อคัดลอก")
end

-- Config: เก็บเป็นข้อความ JSON (คัดลอกไปเก็บ/วางกลับมาได้)
local function exportConfig()
	local box = Controls.config
	if not box then return end
	box.Text = HttpService:JSONEncode(Settings)
	notify("สร้าง config แล้ว – คัดลอกไปเก็บได้")
end
local function importConfig()
	local box = Controls.config
	if not box then return end
	local ok, data = pcall(function() return HttpService:JSONDecode(box.Text) end)
	if not ok or type(data) ~= "table" then notify("config ไม่ถูกต้อง") return end
	local a = data.accent
	if type(a) == "table" and type(a[1]) == "number" and type(a[2]) == "number" and type(a[3]) == "number" then
		applyAccent(Color3.fromRGB(math.clamp(a[1], 0, 255), math.clamp(a[2], 0, 255), math.clamp(a[3], 0, 255)))
	end
	if data.antiafk ~= nil and Controls.antiafk then Controls.antiafk.set(data.antiafk == true) end
	notify("โหลด config แล้ว")
end

---------------------------------------------------------------- ข้อมูลหมวด/โมดูล
-- type ของรายการ: "info" | "toggle" | "dropdown" | "button" | "buttonrow" | "textbox" | "swatches"
-- ready = true คือใช้งานได้จริง (ไม่ใส่ = ยังใช้ไม่ได้)

local function cards(list)
	local out = {}
	for _, c in ipairs(list) do table.insert(out, { type = "info", title = c.title, text = c.text }) end
	return out
end

-- โมดูลเฉพาะเกม: ids = GameId (Universe) หรือ PlaceId ใส่ได้หลายตัว
-- วิธีหา ID: หน้าหลักของ UI จะโชว์ GameId / PlaceId ของเกมที่เปิดอยู่
local GAMES = {
	{
		name = "เกมตัวอย่าง 1", ids = { 1111111111 },
		features = {
			{
				name = "หลัก", icon = "⌨", title = "โมดูลหลัก (เกม 1)",
				items = {
					{ type = "dropdown", name = "พื้นที่ที่จะทำงาน", options = { "ทั้งหมด", "โซน 1", "โซน 2" } },
					{ type = "dropdown", name = "ระดับที่จะทำงาน", options = { "ทุกระดับ", "ต่ำ", "กลาง", "สูง" } },
					{ type = "toggle", name = "โมดูล A", callback = function(state) end },
				},
			},
		},
	},
	{
		name = "เกมตัวอย่าง 2", ids = { 2222222222 },
		features = {
			{
				name = "หลัก", icon = "⌨", title = "โมดูลหลัก (เกม 2)",
				items = {
					{ type = "toggle", name = "โมดูล X", callback = function(state) end },
				},
			},
		},
	},
}

local function findGame()
	for _, g in ipairs(GAMES) do
		for _, id in ipairs(g.ids) do
			if id == game.GameId or id == game.PlaceId then return g end
		end
	end
	return nil
end
local currentGame = findGame()
local gameName = currentGame and currentGame.name or "ทุกเกม"
local idText = "GameId: " .. game.GameId .. "  |  PlaceId: " .. game.PlaceId
local homeText = currentGame
	and ("ตรวจพบเกม: " .. currentGame.name .. "\n" .. idText)
	or ("ยังไม่มีเกมนี้ในรายการ – ใช้โหมดทั่วไป\n" .. idText)

local PAGES = {
	{ name = "หน้าหลัก", icon = "🏠", title = "หน้าหลัก", items = {
		{ type = "info", title = "ยินดีต้อนรับสู่ DKHUB", text = homeText },
	} },
	{ name = "Discord", icon = "💬", title = "Discord", items = {
		{ type = "info", title = "เข้าร่วมชุมชน DKHUB", text = "แจ้งปัญหา ขอฟีเจอร์ และติดตามข่าวสารได้ที่ Discord" },
		{ type = "textbox", id = "discordLink", name = "ลิงก์ Discord", text = DISCORD_LINK, readonly = true },
		{ type = "button", name = "คัดลอกลิงก์", ready = true, callback = function() copyText(DISCORD_LINK) end },
	} },
	{ name = "อัปเดตใหม่", icon = "🔔", title = "อัปเดตใหม่", items = cards(UPDATES) },
	{ name = "ประกาศ", icon = "📢", title = "ประกาศ", items = cards(ANNOUNCEMENTS) },

	{ group = "Features" },
	{ name = "Main", icon = "⭐", title = "Main", items = {
		{ type = "button", name = "ฟังก์ชัน 1" },
		{ type = "button", name = "ฟังก์ชัน 2" },
		{ type = "button", name = "ฟังก์ชัน 3" },
		{ type = "button", name = "ฟังก์ชัน 4" },
	} },
	{ name = "Automation", icon = "🤖", title = "Automation", items = {
		{ type = "info", title = "เร็ว ๆ นี้", text = "หมวดนี้ยังไม่มีโมดูล จะเพิ่มในอัปเดตถัดไป" },
	} },
	{ name = "Webhook", icon = "🔗", title = "Webhook (Discord)", items = {
		{ type = "info", title = "ตั้งค่า Webhook", text = "กรอกข้อมูลไว้ล่วงหน้าได้ แต่ระบบส่งจริงยังไม่เปิดใช้งาน" },
		{ type = "textbox", id = "webhookUrl", name = "Webhook URL", placeholder = "https://discord.com/api/webhooks/..." },
		{ type = "textbox", id = "webhookName", name = "ชื่อที่แสดง", placeholder = "DKHUB" },
		{ type = "buttonrow", buttons = { { name = "บันทึก" }, { name = "ส่งข้อความทดสอบ" } } },
	} },
}

-- โมดูลเฉพาะเกมที่ตรวจพบ (ถ้ามี)
if currentGame then
	table.insert(PAGES, { group = currentGame.name })
	for _, page in ipairs(currentGame.features) do table.insert(PAGES, page) end
end

table.insert(PAGES, { group = "ระบบ" })
table.insert(PAGES, { name = "Setting", icon = "⚙", title = "Setting", items = {
	{ type = "toggle", id = "antiafk", name = "Anti-AFK (กันหลุดเมื่อไม่ขยับ)", ready = true, callback = function(state) setAntiAFK(state) end },
	{ type = "swatches", name = "สี UI", colors = {
		Color3.fromRGB(255, 255, 255), Color3.fromRGB(235, 40, 50), Color3.fromRGB(60, 140, 255), Color3.fromRGB(46, 204, 90),
		Color3.fromRGB(160, 90, 255), Color3.fromRGB(255, 90, 170), Color3.fromRGB(255, 200, 60),
	} },
	{ type = "textbox", id = "config", name = "Config (คัดลอก/วางเพื่อเก็บค่าตั้ง)", placeholder = "กด Export แล้วคัดลอกข้อความไปเก็บ" },
	{ type = "buttonrow", buttons = {
		{ name = "Export", ready = true, callback = exportConfig },
		{ name = "Import", ready = true, callback = importConfig },
	} },
} })

---------------------------------------------------------------- หน้าต่างหลัก
local gui = new("ScreenGui", { Name = "DKHUB", ResetOnSpawn = false, IgnoreGuiInset = true }, player:WaitForChild("PlayerGui"))
gui.Destroying:Connect(function() setAntiAFK(false) end)

local SIZE_NORMAL, SIZE_BIG = UDim2.fromOffset(540, 330), UDim2.fromOffset(700, 420)

local main = new("Frame", {
	Size = SIZE_NORMAL, Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = T.bg, BorderSizePixel = 0,
}, gui)
round(main, 14)
local mainScale = new("UIScale", { Scale = 0.85 }, main)

-- ขอบ (ไล่เฉด) + แสงเรืองรอบนอก
local stroke = new("UIStroke", { Color = T.white, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, main)
trackGrad(new("UIGradient", { Color = accentSeq(T.white), Rotation = 45 }, stroke))
local glow = new("Frame", {
	Size = UDim2.new(1, 10, 1, 10), Position = UDim2.fromOffset(-5, -5), BackgroundTransparency = 1, ZIndex = 0,
}, main)
round(glow, 18)
trackSolid(new("UIStroke", { Color = T.white, Thickness = 5, Transparency = 0.85 }, glow), "Color")

-- แถบชื่อ
local title = new("Frame", { Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1 }, main)
trackSolid(new("Frame", { Size = UDim2.new(1, -24, 0, 1), Position = UDim2.new(0, 12, 1, -1), BackgroundColor3 = T.white, BackgroundTransparency = 0.88, BorderSizePixel = 0 }, title), "BackgroundColor3")

local logo = new("Frame", { Size = UDim2.fromOffset(36, 36), Position = UDim2.fromOffset(10, 5), BackgroundColor3 = T.white }, title)
round(logo, 9)
if applyLogo(logo, 9) then
	logo.BackgroundColor3 = Color3.new(0, 0, 0)
else
	label({ Size = UDim2.fromScale(1, 1), Text = "DK", TextSize = 17, TextColor3 = Color3.fromRGB(20, 20, 24) }, logo)
end
label({ Size = UDim2.fromOffset(200, 22), Position = UDim2.fromOffset(52, 3), Text = "DKHUB - " .. gameName, TextXAlignment = Enum.TextXAlignment.Left, TextSize = 18, TextTruncate = Enum.TextTruncate.AtEnd }, title)
label({ Size = UDim2.fromOffset(200, 18), Position = UDim2.fromOffset(52, 24), Text = "by DK", TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = T.sub, TextSize = 14 }, title)

local badge = new("TextLabel", {
	Size = UDim2.fromOffset(76, 28), Position = UDim2.fromOffset(256, 9), BackgroundColor3 = T.badge,
	Text = "Keyless", Font = T.font, TextSize = 16, TextColor3 = T.white,
}, title)
round(badge, 9)

-- ปุ่มควบคุมหน้าต่าง
local function winBtn(text, x)
	local b = new("TextButton", {
		Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, x, 0, 9), BackgroundColor3 = T.white,
		BackgroundTransparency = 1, Text = text, Font = T.font, TextSize = 20, TextColor3 = T.text, AutoButtonColor = false,
	}, title)
	round(b, 8)
	b.MouseEnter:Connect(function() tween(b, 0.12, { BackgroundTransparency = 0.85 }) end)
	b.MouseLeave:Connect(function() tween(b, 0.12, { BackgroundTransparency = 1 }) end)
	return b
end
local btnMin, btnMax, btnClose = winBtn("–", -100), winBtn("▢", -68), winBtn("✕", -36)

local body = new("Frame", { Size = UDim2.new(1, 0, 1, -46), Position = UDim2.fromOffset(0, 46), BackgroundTransparency = 1 }, main)

makeDraggable(title, main)

---------------------------------------------------------------- ไอคอนตอนย่อ (ลากได้ / กดเพื่อเปิด UI เดิม)
local icon = new("TextButton", {
	Size = UDim2.fromOffset(56, 56), Position = UDim2.fromOffset(20, 20), BackgroundColor3 = T.bg,
	Text = "DK", Font = T.font, TextSize = 22, TextColor3 = T.white, AutoButtonColor = false, Visible = false,
}, gui)
round(icon, 16)
if applyLogo(icon, 16) then
	icon.Text = ""
	icon.BackgroundColor3 = Color3.new(0, 0, 0)
end
local iconScale = new("UIScale", { Scale = 0.01 }, icon)
local iconStroke = new("UIStroke", { Color = T.white, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, icon)
trackGrad(new("UIGradient", { Color = accentSeq(T.white), Rotation = 45 }, iconStroke))
icon.MouseEnter:Connect(function() tween(iconScale, 0.12, { Scale = 1.08 }) end)
icon.MouseLeave:Connect(function() tween(iconScale, 0.12, { Scale = 1 }) end)

local busy = false
local function openUI()
	if busy then return end
	busy = true
	tween(iconScale, 0.15, { Scale = 0.01 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	task.wait(0.15)
	icon.Visible = false
	mainScale.Scale = 0.85
	main.Visible = true
	tween(mainScale, 0.28, { Scale = 1 }, Enum.EasingStyle.Back)
	task.wait(0.28)
	busy = false
end
local function minimizeUI()
	if busy then return end
	busy = true
	-- วางไอคอนตรงมุมซ้ายบนของหน้าต่างเดิม (ไม่ให้หลุดจอ)
	local p, s = main.AbsolutePosition, gui.AbsoluteSize
	icon.Position = UDim2.fromOffset(math.clamp(p.X + 8, 8, s.X - 64), math.clamp(p.Y + 8, 8, s.Y - 64))
	tween(mainScale, 0.2, { Scale = 0.01 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	task.wait(0.2)
	main.Visible = false
	iconScale.Scale = 0.01
	icon.Visible = true
	tween(iconScale, 0.28, { Scale = 1 }, Enum.EasingStyle.Back)
	task.wait(0.28)
	busy = false
end
makeDraggable(icon, icon, openUI)

btnMin.MouseButton1Click:Connect(minimizeUI)

local big = false
btnMax.MouseButton1Click:Connect(function()
	big = not big
	tween(main, 0.25, { Size = big and SIZE_BIG or SIZE_NORMAL }, Enum.EasingStyle.Quint)
end)
btnClose.MouseButton1Click:Connect(function()
	tween(mainScale, 0.2, { Scale = 0.01 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	task.wait(0.2)
	gui:Destroy()
end)

---------------------------------------------------------------- แจ้งเตือน (toast)
local toast = new("TextLabel", {
	Size = UDim2.fromOffset(230, 32), Position = UDim2.new(0.5, 0, 1, -8), AnchorPoint = Vector2.new(0.5, 1),
	BackgroundColor3 = Color3.fromRGB(12, 12, 15), TextColor3 = T.text, Font = T.font, TextSize = 16,
	Text = "", BackgroundTransparency = 1, TextTransparency = 1, ZIndex = 10,
}, body)
round(toast, 9)
trackSolid(new("UIStroke", { Color = T.white, Transparency = 0.7, Thickness = 1 }, toast), "Color")
local toastId = 0
notify = function(msg)
	toastId += 1
	local my = toastId
	toast.Text = msg
	toast.Position = UDim2.new(0.5, 0, 1, 4)
	tween(toast, 0.2, { BackgroundTransparency = 0.05, TextTransparency = 0, Position = UDim2.new(0.5, 0, 1, -8) })
	task.delay(1.5, function()
		if my == toastId then
			tween(toast, 0.25, { BackgroundTransparency = 1, TextTransparency = 1 })
		end
	end)
end

---------------------------------------------------------------- แถบด้านข้าง + เนื้อหา
local side = new("ScrollingFrame", {
	Size = UDim2.new(0, 150, 1, 0), BackgroundColor3 = T.side, BorderSizePixel = 0,
	ScrollBarThickness = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, body)
round(side, 14)
-- ปิดมุมขวาของแถบข้างให้เรียบ
new("Frame", { Size = UDim2.new(0, 20, 1, 0), Position = UDim2.new(1, -20, 0, 0), BackgroundColor3 = T.side, BorderSizePixel = 0, ZIndex = 0 }, side)
new("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 10) }, side)
new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, side)

local content = new("Frame", { Size = UDim2.new(1, -150, 1, 0), Position = UDim2.fromOffset(150, 0), BackgroundTransparency = 1, ClipsDescendants = true }, body)

local pageFrames, tabButtons, tabBars = {}, {}, {}
local currentPage

local function showPage(name)
	if currentPage == name then return end
	currentPage = name
	for n, f in pairs(pageFrames) do
		if n == name then
			f.Position = UDim2.fromOffset(18, 0) -- สไลด์เข้า
			f.Visible = true
			tween(f, 0.25, { Position = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Quint)
		else
			f.Visible = false
		end
	end
	for n, b in pairs(tabButtons) do
		local active = (n == name)
		tween(b, 0.18, { BackgroundTransparency = active and 0.88 or 1 })
		tween(tabBars[n], 0.18, { BackgroundTransparency = active and 0 or 1, Size = UDim2.fromOffset(3, active and 18 or 6) })
	end
end

---------------------------------------------------------------- ตัวสร้างรายการในหน้า
local function makeInfo(item, parent)
	local card = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = T.row }, parent)
	round(card, 10)
	new("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }, card)
	new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, card)
	if item.title then
		label({ Size = UDim2.new(1, 0, 0, 22), Text = item.title, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1 }, card)
	end
	label({
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = item.text, TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextColor3 = T.sub, TextSize = 16, LayoutOrder = 2,
	}, card)
end

local function makeToggle(item, parent)
	local row = new("Frame", { Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = T.row }, parent)
	round(row, 10)
	hover(row, "BackgroundColor3", T.row, T.rowHov)
	label({ Size = UDim2.new(1, -140, 1, 0), Position = UDim2.fromOffset(14, 0), Text = item.name, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, row)
	if not item.ready then
		label({ Size = UDim2.fromOffset(60, 20), Position = UDim2.new(1, -128, 0.5, -10), Text = "เร็ว ๆ นี้", TextColor3 = T.sub, TextSize = 13 }, row)
	end
	local track = new("TextButton", { Size = UDim2.fromOffset(46, 24), Position = UDim2.new(1, -60, 0.5, -12), BackgroundColor3 = T.off, Text = "", AutoButtonColor = false }, row)
	round(track, 12)
	local knob = new("Frame", { Size = UDim2.fromOffset(18, 18), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = T.white }, track)
	round(knob, 9)
	local state = false
	local function setState(v)
		state = v
		tween(track, 0.18, { BackgroundColor3 = state and T.on or T.off })
		tween(knob, 0.18, { Position = UDim2.fromOffset(state and 25 or 3, 3) }, Enum.EasingStyle.Back)
		if item.callback then item.callback(state) end
	end
	track.MouseButton1Click:Connect(function()
		if not item.ready then
			-- เด้งเบา ๆ ให้รู้ว่ายังใช้ไม่ได้
			tween(knob, 0.08, { Position = UDim2.fromOffset(8, 3) })
			task.delay(0.08, function() tween(knob, 0.12, { Position = UDim2.fromOffset(3, 3) }, Enum.EasingStyle.Back) end)
			notify("ยังใช้ไม่ได้ – กำลังพัฒนา")
			return
		end
		setState(not state)
	end)
	if item.id then Controls[item.id] = { set = setState } end
end

-- ดรอปดาวน์ (กดเพื่อสลับตัวเลือก)
local function makeDropdown(item, parent)
	local row = new("Frame", { Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = T.row }, parent)
	round(row, 10)
	hover(row, "BackgroundColor3", T.row, T.rowHov)
	label({ Size = UDim2.new(1, -180, 1, 0), Position = UDim2.fromOffset(14, 0), Text = item.name, TextXAlignment = Enum.TextXAlignment.Left }, row)
	local idx = 1
	local btn = new("TextButton", {
		Size = UDim2.fromOffset(140, 30), Position = UDim2.new(1, -152, 0.5, -15), BackgroundColor3 = Color3.fromRGB(56, 56, 68),
		Text = item.options[1] .. "  ⌄", Font = T.font, TextSize = 16, TextColor3 = T.text, AutoButtonColor = false,
	}, row)
	round(btn, 8)
	hover(btn, "BackgroundColor3", Color3.fromRGB(56, 56, 68), Color3.fromRGB(72, 72, 86))
	btn.MouseButton1Click:Connect(function()
		idx = idx % #item.options + 1
		btn.Text = item.options[idx] .. "  ⌄"
		if item.callback then item.callback(item.options[idx]) end
	end)
end

local function makeButton(item, parent, size, inRow)
	local suffix = (not item.ready and not inRow) and "   (เร็ว ๆ นี้)" or ""
	local b = new("TextButton", {
		Size = size or UDim2.new(1, 0, 0, 46), BackgroundColor3 = T.row, Text = item.name .. suffix,
		Font = T.font, TextSize = 18, TextColor3 = T.text, AutoButtonColor = false,
	}, parent)
	round(b, 10)
	hover(b, "BackgroundColor3", T.row, T.rowHov)
	b.MouseButton1Click:Connect(function()
		if not item.ready then notify("ยังใช้ไม่ได้ – กำลังพัฒนา") return end
		if item.callback then item.callback() end
	end)
end

local function makeButtonRow(item, parent)
	local row = new("Frame", { Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1 }, parent)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, row)
	local n = #item.buttons
	for _, bt in ipairs(item.buttons) do
		makeButton(bt, row, UDim2.new(1 / n, -(8 * (n - 1)) / n, 1, 0), true)
	end
end

local function makeTextbox(item, parent)
	local row = new("Frame", { Size = UDim2.new(1, 0, 0, 76), BackgroundColor3 = T.row }, parent)
	round(row, 10)
	label({ Size = UDim2.new(1, -28, 0, 24), Position = UDim2.fromOffset(14, 6), Text = item.name, TextXAlignment = Enum.TextXAlignment.Left, TextSize = 17 }, row)
	local box = new("TextBox", {
		Size = UDim2.new(1, -28, 0, 34), Position = UDim2.fromOffset(14, 34), BackgroundColor3 = Color3.fromRGB(28, 28, 35),
		Text = item.text or "", PlaceholderText = item.placeholder or "", PlaceholderColor3 = T.sub,
		Font = T.font, TextSize = 15, TextColor3 = T.text, ClearTextOnFocus = false, TextEditable = not item.readonly,
		TextXAlignment = Enum.TextXAlignment.Left, ClipsDescendants = true,
	}, row)
	round(box, 8)
	new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, box)
	if item.id then Controls[item.id] = box end
end

local function makeSwatches(item, parent)
	local row = new("Frame", { Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = T.row }, parent)
	round(row, 10)
	label({ Size = UDim2.fromOffset(90, 46), Position = UDim2.fromOffset(14, 0), Text = item.name, TextXAlignment = Enum.TextXAlignment.Left }, row)
	local holder = new("Frame", {
		Size = UDim2.fromOffset(#item.colors * 30, 28), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), BackgroundTransparency = 1,
	}, row)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), VerticalAlignment = Enum.VerticalAlignment.Center }, holder)
	for _, color in ipairs(item.colors) do
		local s = new("TextButton", { Size = UDim2.fromOffset(26, 26), BackgroundColor3 = color, Text = "", AutoButtonColor = false }, holder)
		round(s, 13)
		local ring = new("UIStroke", { Color = T.white, Thickness = 2, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, s)
		table.insert(swatchMarks, { stroke = ring, color = color })
		s.MouseEnter:Connect(function() tween(s, 0.1, { Size = UDim2.fromOffset(28, 28) }) end)
		s.MouseLeave:Connect(function() tween(s, 0.1, { Size = UDim2.fromOffset(26, 26) }) end)
		s.MouseButton1Click:Connect(function() applyAccent(color) end)
	end
end

local function buildPage(p)
	local f = new("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false,
		ScrollBarThickness = 3, ScrollBarImageColor3 = T.white, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, content)
	trackSolid(f, "ScrollBarImageColor3")
	new("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingBottom = UDim.new(0, 48) }, f)
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, f)
	label({ Size = UDim2.new(1, 0, 0, 30), Text = p.title or p.name, TextXAlignment = Enum.TextXAlignment.Left, TextSize = 24 }, f)
	for _, item in ipairs(p.items or {}) do
		if item.type == "info" then makeInfo(item, f)
		elseif item.type == "toggle" then makeToggle(item, f)
		elseif item.type == "dropdown" then makeDropdown(item, f)
		elseif item.type == "button" then makeButton(item, f)
		elseif item.type == "buttonrow" then makeButtonRow(item, f)
		elseif item.type == "textbox" then makeTextbox(item, f)
		elseif item.type == "swatches" then makeSwatches(item, f) end
	end
	pageFrames[p.name] = f
end

local first
for order, p in ipairs(PAGES) do
	if p.group then
		label({ Size = UDim2.new(1, 0, 0, 24), Text = p.group, TextColor3 = T.sub, TextXAlignment = Enum.TextXAlignment.Left, TextSize = 15, TextTruncate = Enum.TextTruncate.AtEnd, LayoutOrder = order }, side)
	else
		local b = new("TextButton", {
			Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = T.white, BackgroundTransparency = 1,
			Text = "     " .. p.icon .. "  " .. p.name, Font = T.font, TextSize = 17, TextColor3 = T.text,
			TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false, LayoutOrder = order,
		}, side)
		round(b, 9)
		trackSolid(b, "BackgroundColor3")
		-- แถบบอกแท็บที่เลือก
		local bar = new("Frame", { Size = UDim2.fromOffset(3, 6), Position = UDim2.new(0, 6, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = T.white, BackgroundTransparency = 1, BorderSizePixel = 0 }, b)
		round(bar, 2)
		trackSolid(bar, "BackgroundColor3")
		tabButtons[p.name], tabBars[p.name] = b, bar
		buildPage(p)
		b.MouseEnter:Connect(function() if currentPage ~= p.name then tween(b, 0.12, { BackgroundTransparency = 0.94 }) end end)
		b.MouseLeave:Connect(function() if currentPage ~= p.name then tween(b, 0.12, { BackgroundTransparency = 1 }) end end)
		b.MouseButton1Click:Connect(function() showPage(p.name) end)
		first = first or p.name
	end
end
applyAccent(T.white) -- ตั้งสีเริ่มต้น + ไฮไลต์ swatch ที่เลือก
showPage(first)

-- เอฟเฟกต์เปิดตอนเริ่ม
tween(mainScale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
