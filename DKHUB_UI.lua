-- DKHUB UI v3 (LocalScript)
-- วางใน StarterPlayer > StarterPlayerScripts
-- โมดูลทั้งหมดเป็น "โครง" (placeholder) ยังไม่มีฟังก์ชันจริง กดแล้วจะขึ้นแจ้งเตือน "ยังใช้ไม่ได้"

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
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
-- 1) อัปโหลดรูปโลโก้ที่ Roblox Creator Hub (Assets > Images/Decals) หรือ Asset Manager ใน Studio
-- 2) เอา ID ที่ได้มาใส่ตรงนี้ เช่น "rbxassetid://1234567890"  (ถ้าเว้นว่างจะใช้ตัวอักษร DK แทน)
local LOGO_ID = "rbxassetid://86790107799884"
-- ครอปเอาเฉพาะตัว DK ตรงกลางรูป (รูปต้นฉบับ 1024x1024) ปรับได้ถ้าอยากเห็นกว้าง/แคบกว่านี้
local LOGO_RECT_OFFSET = Vector2.new(150, 140)
local LOGO_RECT_SIZE = Vector2.new(660, 660)

---------------------------------------------------------------- ข้อมูลหน้า/โมดูล
-- type: "toggle" | "dropdown" | "button"
-- เมื่อทำฟังก์ชันจริงเสร็จ ให้ใส่ ready = true และเขียนโค้ดใน callback
local PAGES = {
	{ name = "หน้าหลัก", icon = "🏠", info = "ยินดีต้อนรับสู่ DKHUB\nโมดูลต่าง ๆ อยู่ระหว่างพัฒนา" },
	{ name = "Discord", icon = "💬", info = "ลิงก์ Discord: (ใส่ภายหลัง)" },
	{ name = "อัปเดตใหม่", icon = "🔔", info = "v0.3 - เพิ่มโลโก้ภาพและอัปเดต UI" },
	{ name = "สนับสนุน", icon = "❤", info = "ขอบคุณที่สนับสนุน DKHUB" },
	{ group = "Features" },
	{
		name = "หลัก", icon = "⌨", title = "โมดูลหลัก",
		items = {
			{ type = "dropdown", name = "พื้นที่ที่จะทำงาน", options = { "ทั้งหมด", "โซน 1", "โซน 2" } },
			{ type = "dropdown", name = "ระดับที่จะทำงาน", options = { "ทุกระดับ", "ต่ำ", "กลาง", "สูง" } },
			{ type = "toggle", name = "โมดูล A (อัตโนมัติ)", callback = function(state) end },
			{ type = "toggle", name = "โมดูล B (อัตโนมัติ)", callback = function(state) end },
			{ type = "button", name = "โมดูล C", callback = function() end },
		},
	},
	{
		name = "อื่น ๆ", icon = "⚙", title = "โมดูลอื่น ๆ",
		items = {
			{ type = "toggle", name = "โมดูล D", callback = function(state) end },
			{ type = "toggle", name = "โมดูล E", callback = function(state) end },
			{ type = "dropdown", name = "โหมด", options = { "ปกติ", "เร็ว", "ช้า" } },
		},
	},
}

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

---------------------------------------------------------------- หน้าต่างหลัก
local gui = new("ScreenGui", { Name = "DKHUB", ResetOnSpawn = false, IgnoreGuiInset = true }, player:WaitForChild("PlayerGui"))

local SIZE_NORMAL, SIZE_BIG = UDim2.fromOffset(540, 330), UDim2.fromOffset(700, 420)

local main = new("Frame", {
	Size = SIZE_NORMAL, Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = T.bg, BorderSizePixel = 0,
}, gui)
round(main, 14)
local mainScale = new("UIScale", { Scale = 0.85 }, main)

-- ขอบขาว (ไล่เฉด) + แสงเรืองรอบนอก
local stroke = new("UIStroke", { Color = T.white, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, main)
new("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(190, 190, 205)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
	}),
	Rotation = 45,
}, stroke)
local glow = new("Frame", {
	Size = UDim2.new(1, 10, 1, 10), Position = UDim2.fromOffset(-5, -5), BackgroundTransparency = 1, ZIndex = 0,
}, main)
round(glow, 18)
new("UIStroke", { Color = T.white, Thickness = 5, Transparency = 0.85 }, glow)

-- แถบชื่อ
local title = new("Frame", { Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1 }, main)
new("Frame", { Size = UDim2.new(1, -24, 0, 1), Position = UDim2.new(0, 12, 1, -1), BackgroundColor3 = T.white, BackgroundTransparency = 0.88, BorderSizePixel = 0 }, title)

local logo = new("Frame", { Size = UDim2.fromOffset(36, 36), Position = UDim2.fromOffset(10, 5), BackgroundColor3 = T.white }, title)
round(logo, 9)
if applyLogo(logo, 9) then
	logo.BackgroundColor3 = Color3.new(0, 0, 0)
else
	label({ Size = UDim2.fromScale(1, 1), Text = "DK", TextSize = 17, TextColor3 = Color3.fromRGB(20, 20, 24) }, logo)
end
label({ Size = UDim2.fromOffset(200, 22), Position = UDim2.fromOffset(52, 3), Text = "DKHUB - ชื่อเกม", TextXAlignment = Enum.TextXAlignment.Left, TextSize = 18 }, title)
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
new("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(190, 190, 205)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
	}),
	Rotation = 45,
}, iconStroke)
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
new("UIStroke", { Color = T.white, Transparency = 0.7, Thickness = 1 }, toast)
local toastId = 0
local function notify(msg)
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
-- ปิดมุมขวาของแถบข้าง/มุมบนให้เรียบ
new("Frame", { Size = UDim2.new(0, 20, 1, 0), Position = UDim2.new(1, -20, 0, 0), BackgroundColor3 = T.side, BorderSizePixel = 0, ZIndex = 0 }, side)
new("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, side)
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

-- สวิตช์เปิด/ปิด
local function makeToggle(item, parent)
	local row = new("Frame", { Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = T.row }, parent)
	round(row, 10)
	hover(row, "BackgroundColor3", T.row, T.rowHov)
	label({ Size = UDim2.new(1, -140, 1, 0), Position = UDim2.fromOffset(14, 0), Text = item.name, TextXAlignment = Enum.TextXAlignment.Left }, row)
	if not item.ready then
		label({ Size = UDim2.fromOffset(60, 20), Position = UDim2.new(1, -128, 0.5, -10), Text = "เร็ว ๆ นี้", TextColor3 = T.sub, TextSize = 13 }, row)
	end
	local track = new("TextButton", { Size = UDim2.fromOffset(46, 24), Position = UDim2.new(1, -60, 0.5, -12), BackgroundColor3 = T.off, Text = "", AutoButtonColor = false }, row)
	round(track, 12)
	local knob = new("Frame", { Size = UDim2.fromOffset(18, 18), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = T.white }, track)
	round(knob, 9)
	local state = false
	track.MouseButton1Click:Connect(function()
		if not item.ready then
			-- เด้งเบา ๆ ให้รู้ว่ายังใช้ไม่ได้
			tween(knob, 0.08, { Position = UDim2.fromOffset(8, 3) })
			task.delay(0.08, function() tween(knob, 0.12, { Position = UDim2.fromOffset(3, 3) }, Enum.EasingStyle.Back) end)
			notify("ยังใช้ไม่ได้ – กำลังพัฒนา")
			return
		end
		state = not state
		tween(track, 0.18, { BackgroundColor3 = state and T.on or T.off })
		tween(knob, 0.18, { Position = UDim2.fromOffset(state and 25 or 3, 3) }, Enum.EasingStyle.Back)
		if item.callback then item.callback(state) end
	end)
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

local function makeButton(item, parent)
	local b = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = T.row, Text = item.name .. "   (เร็ว ๆ นี้)",
		Font = T.font, TextSize = 18, TextColor3 = T.text, AutoButtonColor = false,
	}, parent)
	round(b, 10)
	hover(b, "BackgroundColor3", T.row, T.rowHov)
	b.MouseButton1Click:Connect(function()
		if not item.ready then notify("ยังใช้ไม่ได้ – กำลังพัฒนา") return end
		if item.callback then item.callback() end
	end)
end

local function buildPage(p)
	local f = new("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false,
		ScrollBarThickness = 3, ScrollBarImageColor3 = T.white, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, content)
	new("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingBottom = UDim.new(0, 48) }, f)
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, f)
	label({ Size = UDim2.new(1, 0, 0, 30), Text = p.title or p.name, TextXAlignment = Enum.TextXAlignment.Left, TextSize = 24 }, f)
	if p.info then
		label({ Size = UDim2.new(1, 0, 0, 60), Text = p.info, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextColor3 = T.sub, TextWrapped = true }, f)
	end
	for _, item in ipairs(p.items or {}) do
		if item.type == "toggle" then makeToggle(item, f)
		elseif item.type == "dropdown" then makeDropdown(item, f)
		elseif item.type == "button" then makeButton(item, f) end
	end
	pageFrames[p.name] = f
end

local first
for order, p in ipairs(PAGES) do
	if p.group then
		label({ Size = UDim2.new(1, 0, 0, 24), Text = p.group, TextColor3 = T.sub, TextXAlignment = Enum.TextXAlignment.Left, TextSize = 15, LayoutOrder = order }, side)
	else
		local b = new("TextButton", {
			Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = T.white, BackgroundTransparency = 1,
			Text = "     " .. p.icon .. "  " .. p.name, Font = T.font, TextSize = 17, TextColor3 = T.text,
			TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false, LayoutOrder = order,
		}, side)
		round(b, 9)
		-- แถบสีขาวบอกแท็บที่เลือก
		local bar = new("Frame", { Size = UDim2.fromOffset(3, 6), Position = UDim2.new(0, 6, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = T.white, BackgroundTransparency = 1, BorderSizePixel = 0 }, b)
		round(bar, 2)
		tabButtons[p.name], tabBars[p.name] = b, bar
		buildPage(p)
		b.MouseEnter:Connect(function() if currentPage ~= p.name then tween(b, 0.12, { BackgroundTransparency = 0.94 }) end end)
		b.MouseLeave:Connect(function() if currentPage ~= p.name then tween(b, 0.12, { BackgroundTransparency = 1 }) end end)
		b.MouseButton1Click:Connect(function() showPage(p.name) end)
		first = first or p.name
	end
end
showPage(first)

-- เอฟเฟกต์เปิดตอนเริ่ม
tween(mainScale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
