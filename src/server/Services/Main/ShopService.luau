--!strict
-- ShopService (server): the Void Shop (AR38; Rules.Shop; Config.Shop; docs/design.md, "The Void Shop").
-- The salt every server draws a shelf with lives in a DataStore key of its own, made once by the first server that needs
-- it (UpdateAsync keeps the first, written back as it is: Rules.Shop.Salt), so every server agrees with no messaging,
-- and no client, nor any copy of the code, can foresee a stock. Until the salt is read the Shop is closed. Studio's
-- playtests use their own store, as the saves do (DataService's "Test"); with no API access in Studio, a fixed salt
-- stands in.
--   Net "Shop"      () -> { Ok, Shelf?, Left?, Error? }: the standing stock's shelf, and its seconds left
--   Act "ShopBuy"   { Stock, Line, Count } -> Rules.Shop.Buy's answer, in one transaction with its op id
--   workspace's ShopStock and ShopFeatured attributes: the standing stock, and whether it holds a piece (the crown)

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Log = require(Shared.Util.Log)
local Net = require(Shared.Net)
local Profile = require(Shared.Data.Profile)
local ShopConfig = require(Shared.Config.Shop)
local Shop = require(Shared.Rules.Shop)
local Core = script.Parent.Parent.Core
local DataService = require(Core.DataService)
local DebugService = require(Core.DebugService)

local ShopService = {
	Priority = 20, -- after DataService
}

local PREFIX = if RunService:IsStudio() then "Test" else "Live"
local STUDIO_SALT = 20261119 -- Studio without API access: a playtest still has a shop
local RETRY = 15 -- seconds before a failed read of the salt is tried again

local salt: number? = nil
local offset = 0 -- Studio only: stocks ahead of the clock, so a test can stand on a featured one
local cached: Shop.Shelf? = nil

local function now(): number
	return workspace:GetServerTimeNow()
end

-- The standing stock's shelf, or nil while the salt is unread. One shelf a stock, drawn once.
function ShopService.Shelf(): Shop.Shelf?
	local held = salt
	if held == nil then
		return nil
	end
	local stock = Shop.Stock(now()) + offset
	if cached == nil or cached.Stock ~= stock then
		cached = Shop.Shelf(stock, held)
	end
	if offset ~= 0 and cached then
		cached.Ends = Shop.Ends(Shop.Stock(now())) -- a test's stock ahead keeps the clock's time left
	end
	return cached
end

-- Seconds until the standing stock gives way.
local function left(): number
	return math.max(0, Shop.Ends(Shop.Stock(now())) - now())
end

local function readSalt()
	local store = DataStoreService:GetDataStore(`{PREFIX}Shop`)
	while salt == nil do
		local ok, result = pcall(function(): any
			return store:UpdateAsync("Salt", function(old: any): any
				return Shop.Salt(old, Random.new():NextInteger(1, 2 ^ 31 - 1)) -- the first's kept, written back as it is
			end)
		end)
		if ok and type(result) == "number" then
			salt = result
		elseif RunService:IsStudio() then
			Log.Warn("ShopService", "no salt from the store in Studio, a fixed one stands in:", result)
			salt = STUDIO_SALT
		else
			Log.Warn("ShopService", "the salt's read failed, the Shop stays closed:", result)
			task.wait(RETRY)
		end
	end
end

-- The world's signs of the standing stock: the crown reads ShopFeatured.
local function sign()
	local shelf = ShopService.Shelf()
	if shelf then
		workspace:SetAttribute("ShopStock", shelf.Stock)
		workspace:SetAttribute("ShopFeatured", shelf.Featured)
	end
end

function ShopService.Init()
	DataService.Action("ShopBuy", function(draft: Profile.Data, args: any): { [string]: any }
		local shelf = ShopService.Shelf()
		if shelf == nil then
			return { Ok = false, Error = "Closed" }
		end
		return Shop.Buy(draft, shelf, args)
	end)
end

function ShopService.Start()
	Net.Server.Handle("Shop", function(): { [string]: any }
		local shelf = ShopService.Shelf()
		if shelf == nil then
			return { Ok = false, Error = "Closed" }
		end
		return { Ok = true, Shelf = shelf, Left = left() }
	end)
	task.spawn(function()
		readSalt()
		while true do
			sign()
			task.wait(math.clamp(left() + 0.05, 0.05, ShopConfig.Period))
		end
	end)
	if RunService:IsStudio() then
		-- Stands on the next featured stock (or `ahead` stocks on, or back on the clock's with 0), till the next such call.
		DebugService.Register("ShopStock", function(_who: any, ahead: any): any
			local held = salt
			if held == nil then
				return { Ok = false, Error = "Closed" }
			end
			local real = Shop.Stock(now())
			if type(ahead) == "number" then
				offset = math.floor(ahead)
			else
				local stock = real + 1
				while not Shop.Shelf(stock, held).Featured do
					stock += 1
				end
				offset = stock - real
			end
			sign()
			local shelf = ShopService.Shelf() :: Shop.Shelf
			return { Ok = true, Stock = shelf.Stock, Ahead = offset, Featured = shelf.Featured }
		end)
		-- Forgets what the player bought this stock, so a test can buy each line out again.
		DebugService.Register("ShopForget", function(who: any): any
			local player = DebugService.ResolvePlayer(who)
			if not player then
				return { Ok = false, Error = "BadArgs" }
			end
			return DataService.Change(player, "ShopForget", function(draft: Profile.Data): { [string]: any }
				draft.Shop = { Stock = 0, Bought = {} }
				return { Ok = true }
			end)
		end)
	end
end

return ShopService
