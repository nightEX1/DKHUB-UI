-- DKHUB UI (LocalScript)
-- วางใน StarterPlayer > StarterPlayerScripts
-- โมดูลทั้งหมดเป็น "โครง" (placeholder) ยังไม่มีฟังก์ชันจริง กดแล้วจะขึ้นแจ้งเตือน "ยังใช้ไม่ได้"

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

---------------------------------------------------------------- ธีม
local T = {
	bg     = Color3.fromRGB(22, 22, 26),
	side   = Color3.fromRGB(28, 28, 33),
	row    = Color3.fromRGB(40, 40, 48),
	text   = Color3.fromRGB(235, 235, 240),
	sub    = Color3.fromRGB(140, 140, 152),
	accent = Color3.fromRGB(235, 40, 50),
	on     = Color3.fromRGB(46, 204, 90),
	off    = Color3.fromRGB(70, 70, 82),
	badge  = Color3.fromRGB(60, 120, 255),
	font   = Enum.Font.SourceSansSemibold,
}

---------------------------------------------------------------- ข้อมูลหน้า/โมดูล
-- type: "toggle" | "dropdown" | "button"
-- เมื่อทำฟังก์ชันจริงเสร็จ ให้ใส่ ready = true และเขียนโค้ดใน callback
local PAGES = {
	{ name = "หน้าหลัก", icon = "🏠", info = "ยินดีต้อนรับสู่ DKHUB\nโมดูลต่าง ๆ อยู่ระหว่างพัฒนา" },
	{ name = "Discord", icon = "💬", info = "ลิงก์ Discord: (ใส่ภายหลัง)" },
	{ name = "อัปเดตใหม่", icon = "🔔", info = "v0.1 - สร้างหน้าตา UI" },
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
local function round(o, r) new("UICorner", { CornerRadius = UDim.new(0, r) }, o) end
local function label(props, parent)
	props.BackgroundTransparency = 1
	props.Font = props.Font or T.font
	props.TextColor3 = props.TextColor3 or T.text
	props.TextSize = props.TextSize or 18
	return new("TextLabel", props, parent)
end

---------------------------------------------------------------- หน้าต่างหลัก
local gui = new("ScreenGui", { Name = "DKHUB", ResetOnSpawn = false, IgnoreGuiInset = true }, player:WaitForChild("PlayerGui"))

local main = new("Frame", {
	Size = UDim2.fromOffset(540, 330), Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = T.bg, BorderSizePixel = 0,
}, gui)
round(main, 12)
new("UIStroke", { Color = T.accent, Thickness = 2 }, main) -- ขอบเรืองแสงสีแดง

-- แถบชื่อ
local title = new("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1 }, main)
local logo = new("Frame", { Size = UDim2.fromOffset(32, 32), Position = UDim2.fromOffset(10, 6), BackgroundColor3 = T.accent }, title)
round(logo, 8)
label({ Size = UDim2.fromScale(1, 1), Text = "DK", TextSize = 16 }, logo)
label({ Size = UDim2.fromOffset(200, 22), Position = UDim2.fromOffset(50, 2), Text = "DKHUB - ชื่อเกม", TextXAlignment = Enum.TextXAlignment.Left, TextSize = 17 }, title)
label({ Size = UDim2.fromOffset(200, 18), Position = UDim2.fromOffset(50, 22), Text = "by DK", TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = T.sub, TextSize = 14 }, title)

local badge = new("TextLabel", {
	Size = UDim2.fromOffset(74, 28), Position = UDim2.fromOffset(250, 8), BackgroundColor3 = T.badge,
	Text = "Keyless", Font = T.font, TextSize = 16, TextColor3 = Color3.new(1, 1, 1),
}, title)
round(badge, 8)

-- ปุ่มควบคุมหน้าต่าง
local function winBtn(text, x)
	local b = new("TextButton", {
		Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, x, 0, 8), BackgroundTransparency = 1,
		Text = text, Font = T.font, TextSize = 20, TextColor3 = T.text,
	}, title)
	return b
end
local btnMin, btnMax, btnClose = winBtn("–", -96), winBtn("▢", -64), winBtn("✕", -32)

-- ลากหน้าต่าง
do
	local dragging, startPos, startMouse
	title.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging, startMouse, startPos = true, i.Position, main.Position
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - startMouse
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
	UIS.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)
end

local body = new("Frame", { Size = UDim2.new(1, 0, 1, -44), Position = UDim2.fromOffset(0, 44), BackgroundTransparency = 1 }, main)
btnMin.MouseButton1Click:Connect(function() body.Visible = not body.Visible end)
btnClose.MouseButton1Click:Connect(function() gui:Destroy() end)

---------------------------------------------------------------- แจ้งเตือน (toast)
local toast = new("TextLabel", {
	Size = UDim2.fromOffset(220, 30), Position = UDim2.new(0.5, 0, 1, -16), AnchorPoint = Vector2.new(0.5, 1),
	BackgroundColor3 = Color3.fromRGB(15, 15, 18), TextColor3 = T.text, Font = T.font, TextSize = 16,
	Text = "", BackgroundTransparency = 1, TextTransparency = 1, ZIndex = 10,
}, body)
round(toast, 8)
local function notify(msg)
	toast.Text = msg
	toast.BackgroundTransparency, toast.TextTransparency = 0.1, 0
	task.delay(1.4, function()
		TweenService:Create(toast, TweenInfo.new(0.3), { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
	end)
end

---------------------------------------------------------------- แถบด้านข้าง + เนื้อหา
local side = new("ScrollingFrame", {
	Size = UDim2.new(0, 150, 1, 0), BackgroundColor3 = T.side, BorderSizePixel = 0,
	ScrollBarThickness = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, body)
new("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, side)
new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, side)

local content = new("Frame", { Size = UDim2.new(1, -150, 1, 0), Position = UDim2.fromOffset(150, 0), BackgroundTransparency = 1 }, body)

local pageFrames, tabButtons = {}, {}
local function showPage(name)
	for n, f in pairs(pageFrames) do f.Visible = (n == name) end
	for n, b in pairs(tabButtons) do b.BackgroundTransparency = (n == name) and 0 or 1 end
end

-- สวิตช์เปิด/ปิด
local function makeToggle(item, parent)
	local row = new("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = T.row }, parent)
	round(row, 8)
	label({ Size = UDim2.new(1, -130, 1, 0), Position = UDim2.fromOffset(12, 0), Text = item.name, TextXAlignment = Enum.TextXAlignment.Left }, row)
	label({ Size = UDim2.fromOffset(60, 20), Position = UDim2.new(1, -124, 0.5, -10), Text = "เร็ว ๆ นี้", TextColor3 = T.sub, TextSize = 13 }, row)
	local track = new("TextButton", { Size = UDim2.fromOffset(46, 24), Position = UDim2.new(1, -58, 0.5, -12), BackgroundColor3 = T.off, Text = "", AutoButtonColor = false }, row)
	round(track, 12)
	local knob = new("Frame", { Size = UDim2.fromOffset(18, 18), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = Color3.new(1, 1, 1) }, track)
	round(knob, 9)
	local state = false
	track.MouseButton1Click:Connect(function()
		if not item.ready then notify("ยังใช้ไม่ได้ – กำลังพัฒนา") return end
		state = not state
		TweenService:Create(track, TweenInfo.new(0.15), { BackgroundColor3 = state and T.on or T.off }):Play()
		TweenService:Create(knob, TweenInfo.new(0.15), { Position = UDim2.fromOffset(state and 25 or 3, 3) }):Play()
		if item.callback then item.callback(state) end
	end)
end

-- ดรอปดาวน์ (กดเพื่อสลับตัวเลือก)
local function makeDropdown(item, parent)
	local row = new("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = T.row }, parent)
	round(row, 8)
	label({ Size = UDim2.new(1, -170, 1, 0), Position = UDim2.fromOffset(12, 0), Text = item.name, TextXAlignment = Enum.TextXAlignment.Left }, row)
	local idx = 1
	local btn = new("TextButton", {
		Size = UDim2.fromOffset(140, 28), Position = UDim2.new(1, -150, 0.5, -14), BackgroundColor3 = Color3.fromRGB(55, 55, 66),
		Text = item.options[1] .. "  ⌄", Font = T.font, TextSize = 16, TextColor3 = T.text,
	}, row)
	round(btn, 6)
	btn.MouseButton1Click:Connect(function()
		idx = idx % #item.options + 1
		btn.Text = item.options[idx] .. "  ⌄"
		if item.callback then item.callback(item.options[idx]) end
	end)
end

local function makeButton(item, parent)
	local b = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = T.row, Text = item.name .. "   (เร็ว ๆ นี้)",
		Font = T.font, TextSize = 18, TextColor3 = T.text,
	}, parent)
	round(b, 8)
	b.MouseButton1Click:Connect(function()
		if not item.ready then notify("ยังใช้ไม่ได้ – กำลังพัฒนา") return end
		if item.callback then item.callback() end
	end)
end

local function buildPage(p)
	local f = new("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false,
		ScrollBarThickness = 3, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, content)
	new("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 40) }, f)
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, f)
	label({ Size = UDim2.new(1, 0, 0, 30), Text = p.title or p.name, TextXAlignment = Enum.TextXAlignment.Left, TextSize = 22 }, f)
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
			Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Color3.fromRGB(50, 50, 60), BackgroundTransparency = 1,
			Text = "  " .. p.icon .. "  " .. p.name, Font = T.font, TextSize = 17, TextColor3 = T.text,
			TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false, LayoutOrder = order,
		}, side)
		round(b, 8)
		tabButtons[p.name] = b
		buildPage(p)
		b.MouseButton1Click:Connect(function() showPage(p.name) end)
		first = first or p.name
	end
end
showPage(first)
