--!strict
-- ItemDesigns (shared, pure; written by tools/ui/gear_designs.py from AR6's gear_icons.json, never by hand): each
-- kind's designs at each rarity, in order. A design is a look and a name only, never a stat (docs/design.md, Regalia,
-- "An item's design"). An owned item keeps its design's index (Data.Profile, OwnedItem.Design), so a design added at
-- the end of a list never moves one. `Image` names the picture in Config.UIKit.Images.

export type Design = { Name: string, Image: string }

local ByKind: { [string]: { [string]: { Design } } } = {
	["Amulet"] = {
		Common = { { Name = "Iron Amulet", Image = "GearIronAmulet" }, { Name = "Bronze Amulet", Image = "GearBronzeAmulet" }, { Name = "Scrap Amulet", Image = "GearScrapAmulet" } },
		Uncommon = { { Name = "Lanternsteel Amulet", Image = "GearLanternsteelAmulet" }, { Name = "Rowsmith Amulet", Image = "GearRowsmithAmulet" }, { Name = "Stallguard Amulet", Image = "GearStallguardAmulet" } },
		Rare = { { Name = "Pendant of Embers", Image = "GearPendantOfEmbers" }, { Name = "Pendant of Hoarfrost", Image = "GearPendantOfHoarfrost" }, { Name = "Pendant of Gales", Image = "GearPendantOfGales" } },
		Epic = { { Name = "Stormcall Talisman", Image = "GearStormcallTalisman" }, { Name = "Gloamforge Talisman", Image = "GearGloamforgeTalisman" }, { Name = "Nightloom Talisman", Image = "GearNightloomTalisman" } },
		Legendary = { { Name = "Yakou, the Night Glow", Image = "GearYakou" }, { Name = "Akebono, the Dawn", Image = "GearAkebono" }, { Name = "Tsukigasa, the Moon Halo", Image = "GearTsukigasa" } },
	},
	["Boots"] = {
		Common = { { Name = "Iron Boots", Image = "GearIronBoots" }, { Name = "Bronze Boots", Image = "GearBronzeBoots" }, { Name = "Scrap Boots", Image = "GearScrapBoots" } },
		Uncommon = { { Name = "Lanternsteel Boots", Image = "GearLanternsteelBoots" }, { Name = "Rowsmith Boots", Image = "GearRowsmithBoots" }, { Name = "Stallguard Boots", Image = "GearStallguardBoots" } },
		Rare = { { Name = "Greaves of Embers", Image = "GearGreavesOfEmbers" }, { Name = "Greaves of Hoarfrost", Image = "GearGreavesOfHoarfrost" }, { Name = "Greaves of Gales", Image = "GearGreavesOfGales" } },
		Epic = { { Name = "Stormcall Greaves", Image = "GearStormcallGreaves" }, { Name = "Gloamforge Greaves", Image = "GearGloamforgeGreaves" }, { Name = "Nightloom Greaves", Image = "GearNightloomGreaves" } },
		Legendary = { { Name = "Komorebi, the Leaf Light", Image = "GearKomorebi" }, { Name = "Asaborake, the Dawnlight", Image = "GearAsaborake" }, { Name = "Hoshikuzu, the Stardust", Image = "GearHoshikuzu" } },
	},
	["Bracers"] = {
		Common = { { Name = "Iron Bracers", Image = "GearIronBracers" }, { Name = "Bronze Bracers", Image = "GearBronzeBracers" }, { Name = "Scrap Bracers", Image = "GearScrapBracers" } },
		Uncommon = { { Name = "Lanternsteel Bracers", Image = "GearLanternsteelBracers" }, { Name = "Rowsmith Bracers", Image = "GearRowsmithBracers" }, { Name = "Stallguard Bracers", Image = "GearStallguardBracers" } },
		Rare = { { Name = "Vambraces of Embers", Image = "GearVambracesOfEmbers" }, { Name = "Vambraces of Hoarfrost", Image = "GearVambracesOfHoarfrost" }, { Name = "Vambraces of Gales", Image = "GearVambracesOfGales" } },
		Epic = { { Name = "Stormcall Vambraces", Image = "GearStormcallVambraces" }, { Name = "Gloamforge Vambraces", Image = "GearGloamforgeVambraces" }, { Name = "Nightloom Vambraces", Image = "GearNightloomVambraces" } },
		Legendary = { { Name = "Asayake, the Red Morning", Image = "GearAsayake" }, { Name = "Hokushin, the Pole Star", Image = "GearHokushin" }, { Name = "Hakkou, the Radiance", Image = "GearHakkou" } },
	},
	["Chest Armor"] = {
		Common = { { Name = "Iron Chestplate", Image = "GearIronChestplate" }, { Name = "Bronze Chestplate", Image = "GearBronzeChestplate" }, { Name = "Scrap Chestplate", Image = "GearScrapChestplate" } },
		Uncommon = { { Name = "Lanternsteel Chestplate", Image = "GearLanternsteelChestplate" }, { Name = "Rowsmith Chestplate", Image = "GearRowsmithChestplate" }, { Name = "Stallguard Chestplate", Image = "GearStallguardChestplate" } },
		Rare = { { Name = "Cuirass of Embers", Image = "GearCuirassOfEmbers" }, { Name = "Cuirass of Hoarfrost", Image = "GearCuirassOfHoarfrost" }, { Name = "Cuirass of Gales", Image = "GearCuirassOfGales" } },
		Epic = { { Name = "Stormcall Cuirass", Image = "GearStormcallCuirass" }, { Name = "Gloamforge Cuirass", Image = "GearGloamforgeCuirass" }, { Name = "Nightloom Cuirass", Image = "GearNightloomCuirass" } },
		Legendary = { { Name = "Hinode, the Sunrise", Image = "GearHinode" }, { Name = "Tsukiyo, the Moonlit Sky", Image = "GearTsukiyo" }, { Name = "Amanogawa, the Starway", Image = "GearAmanogawa" } },
	},
	["Cloak"] = {
		Common = { { Name = "Wool Cloak", Image = "GearWoolCloak" }, { Name = "Hooded Cloak", Image = "GearHoodedCloak" }, { Name = "Scrap Cloak", Image = "GearScrapCloak" } },
		Uncommon = { { Name = "Lanternweave Cloak", Image = "GearLanternweaveCloak" }, { Name = "Rowsmith Cloak", Image = "GearRowsmithCloak" }, { Name = "Stallguard Cloak", Image = "GearStallguardCloak" } },
		Rare = { { Name = "Mantle of Embers", Image = "GearMantleOfEmbers" }, { Name = "Mantle of Hoarfrost", Image = "GearMantleOfHoarfrost" }, { Name = "Mantle of Gales", Image = "GearMantleOfGales" } },
		Epic = { { Name = "Stormcall Mantle", Image = "GearStormcallMantle" }, { Name = "Gloamforge Mantle", Image = "GearGloamforgeMantle" }, { Name = "Nightloom Mantle", Image = "GearNightloomMantle" } },
		Legendary = { { Name = "Kyokkou, the Aurora", Image = "GearKyokkou" }, { Name = "Yuuyake, the Sunset", Image = "GearYuuyake" }, { Name = "Tsukiakari, the Moonglow", Image = "GearTsukiakari" } },
	},
	["Codex"] = {
		Common = { { Name = "Iron Codex", Image = "GearIronCodex" }, { Name = "Bronze Codex", Image = "GearBronzeCodex" }, { Name = "Scrap Codex", Image = "GearScrapCodex" } },
		Uncommon = { { Name = "Lanternsteel Codex", Image = "GearLanternsteelCodex" }, { Name = "Rowsmith Codex", Image = "GearRowsmithCodex" }, { Name = "Stallguard Codex", Image = "GearStallguardCodex" } },
		Rare = { { Name = "Folio of Embers", Image = "GearFolioOfEmbers" }, { Name = "Folio of Hoarfrost", Image = "GearFolioOfHoarfrost" }, { Name = "Folio of Gales", Image = "GearFolioOfGales" } },
		Epic = { { Name = "Stormcall Folio", Image = "GearStormcallFolio" }, { Name = "Gloamforge Folio", Image = "GearGloamforgeFolio" }, { Name = "Nightloom Folio", Image = "GearNightloomFolio" } },
		Legendary = { { Name = "Kouseki, the Light Trail", Image = "GearKouseki" }, { Name = "Ryuukou, the High Spire", Image = "GearRyuukou" }, { Name = "Tenmon, the Star Watch", Image = "GearTenmon" } },
	},
	["Crystal Baton"] = {
		Common = { { Name = "Iron Crystal Baton", Image = "GearIronCrystalBaton" }, { Name = "Bronze Crystal Baton", Image = "GearBronzeCrystalBaton" }, { Name = "Scrap Crystal Baton", Image = "GearScrapCrystalBaton" } },
		Uncommon = { { Name = "Lanternsteel Baton", Image = "GearLanternsteelBaton" }, { Name = "Rowsmith Baton", Image = "GearRowsmithBaton" }, { Name = "Stallguard Baton", Image = "GearStallguardBaton" } },
		Rare = { { Name = "Sceptre of Embers", Image = "GearSceptreOfEmbers" }, { Name = "Sceptre of Hoarfrost", Image = "GearSceptreOfHoarfrost" }, { Name = "Sceptre of Gales", Image = "GearSceptreOfGales" } },
		Epic = { { Name = "Stormcall Sceptre", Image = "GearStormcallSceptre" }, { Name = "Gloamforge Sceptre", Image = "GearGloamforgeSceptre" }, { Name = "Nightloom Sceptre", Image = "GearNightloomSceptre" } },
		Legendary = { { Name = "Seikou, the Starlight", Image = "GearSeikou" }, { Name = "Gyouten, the Dawn Bloom", Image = "GearGyouten" }, { Name = "Reikou, the Twin Light", Image = "GearReikou" } },
	},
	["Dagger"] = {
		Common = { { Name = "Iron Dagger", Image = "GearIronDagger" }, { Name = "Bronze Dagger", Image = "GearBronzeDagger" }, { Name = "Scrap Dagger", Image = "GearScrapDagger" } },
		Uncommon = { { Name = "Lanternsteel Dagger", Image = "GearLanternsteelDagger" }, { Name = "Rowsmith Dagger", Image = "GearRowsmithDagger" }, { Name = "Stallguard Dagger", Image = "GearStallguardDagger" } },
		Rare = { { Name = "Fang of Embers", Image = "GearFangOfEmbers" }, { Name = "Fang of Hoarfrost", Image = "GearFangOfHoarfrost" }, { Name = "Fang of Gales", Image = "GearFangOfGales" } },
		Epic = { { Name = "Stormcall Fang", Image = "GearStormcallFang" }, { Name = "Gloamforge Fang", Image = "GearGloamforgeFang" }, { Name = "Nightloom Fang", Image = "GearNightloomFang" } },
		Legendary = { { Name = "Kougetsu, the Pale Moon", Image = "GearKougetsu" }, { Name = "Yuugure, the Nightfall", Image = "GearYuugure" }, { Name = "Bunkou, the Split Ray", Image = "GearBunkou" } },
	},
	["Earring"] = {
		Common = { { Name = "Iron Earring", Image = "GearIronEarring" }, { Name = "Bronze Earring", Image = "GearBronzeEarring" }, { Name = "Scrap Earring", Image = "GearScrapEarring" } },
		Uncommon = { { Name = "Lanternsteel Earring", Image = "GearLanternsteelEarring" }, { Name = "Rowsmith Earring", Image = "GearRowsmithEarring" }, { Name = "Stallguard Earring", Image = "GearStallguardEarring" } },
		Rare = { { Name = "Eardrop of Embers", Image = "GearEardropOfEmbers" }, { Name = "Eardrop of Hoarfrost", Image = "GearEardropOfHoarfrost" }, { Name = "Eardrop of Gales", Image = "GearEardropOfGales" } },
		Epic = { { Name = "Stormcall Eardrop", Image = "GearStormcallEardrop" }, { Name = "Gloamforge Eardrop", Image = "GearGloamforgeEardrop" }, { Name = "Nightloom Eardrop", Image = "GearNightloomEardrop" } },
		Legendary = { { Name = "Kagayaki, the Brilliance", Image = "GearKagayaki" }, { Name = "Yuzuki, the Evening Moon", Image = "GearYuzuki" }, { Name = "Hatsuhi, the First Sun", Image = "GearHatsuhi" } },
	},
	["Gloves"] = {
		Common = { { Name = "Iron Gloves", Image = "GearIronGloves" }, { Name = "Bronze Gloves", Image = "GearBronzeGloves" }, { Name = "Scrap Gloves", Image = "GearScrapGloves" } },
		Uncommon = { { Name = "Lanternsteel Gloves", Image = "GearLanternsteelGloves" }, { Name = "Rowsmith Gloves", Image = "GearRowsmithGloves" }, { Name = "Stallguard Gloves", Image = "GearStallguardGloves" } },
		Rare = { { Name = "Gauntlets of Embers", Image = "GearGauntletsOfEmbers" }, { Name = "Gauntlets of Hoarfrost", Image = "GearGauntletsOfHoarfrost" }, { Name = "Gauntlets of Gales", Image = "GearGauntletsOfGales" } },
		Epic = { { Name = "Stormcall Gauntlets", Image = "GearStormcallGauntlets" }, { Name = "Gloamforge Gauntlets", Image = "GearGloamforgeGauntlets" }, { Name = "Nightloom Gauntlets", Image = "GearNightloomGauntlets" } },
		Legendary = { { Name = "Kirameki, the Glint", Image = "GearKirameki" }, { Name = "Nagareboshi, the Meteor", Image = "GearNagareboshi" }, { Name = "Yuubae, the Evening Glow", Image = "GearYuubae" } },
	},
	["Great Axe"] = {
		Common = { { Name = "Iron Greataxe", Image = "GearIronGreataxe" }, { Name = "Bronze Greataxe", Image = "GearBronzeGreataxe" }, { Name = "Scrap Greataxe", Image = "GearScrapGreataxe" } },
		Uncommon = { { Name = "Lanternsteel Greataxe", Image = "GearLanternsteelGreataxe" }, { Name = "Rowsmith Greataxe", Image = "GearRowsmithGreataxe" }, { Name = "Stallguard Greataxe", Image = "GearStallguardGreataxe" } },
		Rare = { { Name = "Greataxe of Embers", Image = "GearGreataxeOfEmbers" }, { Name = "Greataxe of Hoarfrost", Image = "GearGreataxeOfHoarfrost" }, { Name = "Greataxe of Gales", Image = "GearGreataxeOfGales" } },
		Epic = { { Name = "Stormcall Greataxe", Image = "GearStormcallGreataxe" }, { Name = "Gloamforge Greataxe", Image = "GearGloamforgeGreataxe" }, { Name = "Nightloom Greataxe", Image = "GearNightloomGreataxe" } },
		Legendary = { { Name = "Meigetsu, the Full Moon", Image = "GearMeigetsu" }, { Name = "Gingetsu, the Silver Bow", Image = "GearGingetsu" }, { Name = "Kinsei, the Golden Star", Image = "GearKinsei" } },
	},
	["Helmet"] = {
		Common = { { Name = "Iron Helmet", Image = "GearIronHelmet" }, { Name = "Bronze Helmet", Image = "GearBronzeHelmet" }, { Name = "Scrap Helmet", Image = "GearScrapHelmet" } },
		Uncommon = { { Name = "Lanternsteel Helmet", Image = "GearLanternsteelHelmet" }, { Name = "Rowsmith Helmet", Image = "GearRowsmithHelmet" }, { Name = "Stallguard Helmet", Image = "GearStallguardHelmet" } },
		Rare = { { Name = "Helm of Embers", Image = "GearHelmOfEmbers" }, { Name = "Helm of Hoarfrost", Image = "GearHelmOfHoarfrost" }, { Name = "Helm of Gales", Image = "GearHelmOfGales" } },
		Epic = { { Name = "Stormcall Helm", Image = "GearStormcallHelm" }, { Name = "Gloamforge Helm", Image = "GearGloamforgeHelm" }, { Name = "Nightloom Helm", Image = "GearNightloomHelm" } },
		Legendary = { { Name = "Tomoshibi, the Vigil", Image = "GearTomoshibi" }, { Name = "Zansho, the Afterglow", Image = "GearZansho" }, { Name = "Kawatare, the Twilight", Image = "GearKawatare" } },
	},
	["Ring"] = {
		Common = { { Name = "Iron Ring", Image = "GearIronRing" }, { Name = "Bronze Ring", Image = "GearBronzeRing" }, { Name = "Scrap Ring", Image = "GearScrapRing" } },
		Uncommon = { { Name = "Lanternsteel Ring", Image = "GearLanternsteelRing" }, { Name = "Rowsmith Ring", Image = "GearRowsmithRing" }, { Name = "Stallguard Ring", Image = "GearStallguardRing" } },
		Rare = { { Name = "Band of Embers", Image = "GearBandOfEmbers" }, { Name = "Band of Hoarfrost", Image = "GearBandOfHoarfrost" }, { Name = "Band of Gales", Image = "GearBandOfGales" } },
		Epic = { { Name = "Stormcall Loop", Image = "GearStormcallLoop" }, { Name = "Gloamforge Loop", Image = "GearGloamforgeLoop" }, { Name = "Nightloom Loop", Image = "GearNightloomLoop" } },
		Legendary = { { Name = "Kagaribi, the Watchfire", Image = "GearKagaribi" }, { Name = "Yoiboshi, the Dusk Star", Image = "GearYoiboshi" }, { Name = "Ariake, the Pale Moon", Image = "GearAriake" } },
	},
	["Shield"] = {
		Common = { { Name = "Iron Shield", Image = "GearIronShield" }, { Name = "Bronze Shield", Image = "GearBronzeShield" }, { Name = "Scrap Shield", Image = "GearScrapShield" } },
		Uncommon = { { Name = "Lanternsteel Shield", Image = "GearLanternsteelShield" }, { Name = "Rowsmith Shield", Image = "GearRowsmithShield" }, { Name = "Stallguard Shield", Image = "GearStallguardShield" } },
		Rare = { { Name = "Bulwark of Embers", Image = "GearBulwarkOfEmbers" }, { Name = "Bulwark of Hoarfrost", Image = "GearBulwarkOfHoarfrost" }, { Name = "Bulwark of Gales", Image = "GearBulwarkOfGales" } },
		Epic = { { Name = "Stormcall Bulwark", Image = "GearStormcallBulwark" }, { Name = "Gloamforge Bulwark", Image = "GearGloamforgeBulwark" }, { Name = "Nightloom Bulwark", Image = "GearNightloomBulwark" } },
		Legendary = { { Name = "Hakuchuu, the High Noon", Image = "GearHakuchuu" }, { Name = "Kousai, the Clear Mirror", Image = "GearKousai" }, { Name = "Fuyuboshi, the Cold Star", Image = "GearFuyuboshi" } },
	},
	["Short Sword"] = {
		Common = { { Name = "Iron Short Sword", Image = "GearIronShortSword" }, { Name = "Bronze Short Sword", Image = "GearBronzeShortSword" }, { Name = "Scrap Short Sword", Image = "GearScrapShortSword" } },
		Uncommon = { { Name = "Lanternsteel Short Sword", Image = "GearLanternsteelShortSword" }, { Name = "Rowsmith Short Sword", Image = "GearRowsmithShortSword" }, { Name = "Stallguard Short Sword", Image = "GearStallguardShortSword" } },
		Rare = { { Name = "Edge of Embers", Image = "GearEdgeOfEmbers" }, { Name = "Edge of Hoarfrost", Image = "GearEdgeOfHoarfrost" }, { Name = "Edge of Gales", Image = "GearEdgeOfGales" } },
		Epic = { { Name = "Stormcall Edge", Image = "GearStormcallEdge" }, { Name = "Gloamforge Edge", Image = "GearGloamforgeEdge" }, { Name = "Nightloom Edge", Image = "GearNightloomEdge" } },
		Legendary = { { Name = "Hotaru, the Small Light", Image = "GearHotaru" }, { Name = "Yukiakari, the Snowlight", Image = "GearYukiakari" }, { Name = "Hoshiakari, the Far Star", Image = "GearHoshiakari" } },
	},
	["Shoulders"] = {
		Common = { { Name = "Iron Shoulders", Image = "GearIronShoulders" }, { Name = "Bronze Shoulders", Image = "GearBronzeShoulders" }, { Name = "Scrap Shoulders", Image = "GearScrapShoulders" } },
		Uncommon = { { Name = "Lanternsteel Shoulders", Image = "GearLanternsteelShoulders" }, { Name = "Rowsmith Shoulders", Image = "GearRowsmithShoulders" }, { Name = "Stallguard Shoulders", Image = "GearStallguardShoulders" } },
		Rare = { { Name = "Pauldrons of Embers", Image = "GearPauldronsOfEmbers" }, { Name = "Pauldrons of Hoarfrost", Image = "GearPauldronsOfHoarfrost" }, { Name = "Pauldrons of Gales", Image = "GearPauldronsOfGales" } },
		Epic = { { Name = "Stormcall Pauldrons", Image = "GearStormcallPauldrons" }, { Name = "Gloamforge Pauldrons", Image = "GearGloamforgePauldrons" }, { Name = "Nightloom Pauldrons", Image = "GearNightloomPauldrons" } },
		Legendary = { { Name = "Noroshi, the Beacon", Image = "GearNoroshi" }, { Name = "Yoake, the Daybreak", Image = "GearYoake" }, { Name = "Kaikou, the Sea Light", Image = "GearKaikou" } },
	},
	["Staff"] = {
		Common = { { Name = "Iron Staff", Image = "GearIronStaff" }, { Name = "Bronze Staff", Image = "GearBronzeStaff" }, { Name = "Scrap Staff", Image = "GearScrapStaff" } },
		Uncommon = { { Name = "Lanternsteel Staff", Image = "GearLanternsteelStaff" }, { Name = "Rowsmith Staff", Image = "GearRowsmithStaff" }, { Name = "Stallguard Staff", Image = "GearStallguardStaff" } },
		Rare = { { Name = "Stave of Embers", Image = "GearStaveOfEmbers" }, { Name = "Stave of Hoarfrost", Image = "GearStaveOfHoarfrost" }, { Name = "Stave of Gales", Image = "GearStaveOfGales" } },
		Epic = { { Name = "Stormcall Stave", Image = "GearStormcallStave" }, { Name = "Gloamforge Stave", Image = "GearGloamforgeStave" }, { Name = "Nightloom Stave", Image = "GearNightloomStave" } },
		Legendary = { { Name = "Kontengi, the Sky Sphere", Image = "GearKontengi" }, { Name = "Niji, the Rainbow Arch", Image = "GearNiji" }, { Name = "Yuuhi, the Setting Sun", Image = "GearYuuhi" } },
	},
	["Sword"] = {
		Common = { { Name = "Iron Sword", Image = "GearIronSword" }, { Name = "Bronze Sword", Image = "GearBronzeSword" }, { Name = "Scrap Sword", Image = "GearScrapSword" } },
		Uncommon = { { Name = "Lanternsteel Sword", Image = "GearLanternsteelSword" }, { Name = "Rowsmith Sword", Image = "GearRowsmithSword" }, { Name = "Stallguard Sword", Image = "GearStallguardSword" } },
		Rare = { { Name = "Blade of Embers", Image = "GearBladeOfEmbers" }, { Name = "Blade of Hoarfrost", Image = "GearBladeOfHoarfrost" }, { Name = "Brand of Gales", Image = "GearBrandOfGales" } },
		Epic = { { Name = "Stormcall Blade", Image = "GearStormcallBlade" }, { Name = "Gloamforge Blade", Image = "GearGloamforgeBlade" }, { Name = "Nightloom Brand", Image = "GearNightloomBrand" } },
		Legendary = { { Name = "Akari, the First Light", Image = "GearAkari" }, { Name = "Kiribi, the Struck Spark", Image = "GearKiribi" }, { Name = "Inabikari, the Far Flash", Image = "GearInabikari" } },
	},
	["Throwing Blades"] = {
		Common = { { Name = "Iron Throwing Blades", Image = "GearIronThrowingBlades" }, { Name = "Bronze Throwing Blades", Image = "GearBronzeThrowingBlades" }, { Name = "Scrap Throwing Blades", Image = "GearScrapThrowingBlades" } },
		Uncommon = { { Name = "Lanternsteel Blades", Image = "GearLanternsteelBlades" }, { Name = "Rowsmith Blades", Image = "GearRowsmithBlades" }, { Name = "Stallguard Blades", Image = "GearStallguardBlades" } },
		Rare = { { Name = "Talons of Embers", Image = "GearTalonsOfEmbers" }, { Name = "Talons of Hoarfrost", Image = "GearTalonsOfHoarfrost" }, { Name = "Talons of Gales", Image = "GearTalonsOfGales" } },
		Epic = { { Name = "Stormcall Talons", Image = "GearStormcallTalons" }, { Name = "Gloamforge Talons", Image = "GearGloamforgeTalons" }, { Name = "Nightloom Talons", Image = "GearNightloomTalons" } },
		Legendary = { { Name = "Shokou, the First Light", Image = "GearShokou" }, { Name = "Getsurin, the Moon Wheel", Image = "GearGetsurin" }, { Name = "Tenkou, the Sky Feather", Image = "GearTenkou" } },
	},
	["Tome"] = {
		Common = { { Name = "Iron Tome", Image = "GearIronTome" }, { Name = "Bronze Tome", Image = "GearBronzeTome" }, { Name = "Scrap Tome", Image = "GearScrapTome" } },
		Uncommon = { { Name = "Lanternsteel Tome", Image = "GearLanternsteelTome" }, { Name = "Rowsmith Tome", Image = "GearRowsmithTome" }, { Name = "Stallguard Tome", Image = "GearStallguardTome" } },
		Rare = { { Name = "Grimoire of Embers", Image = "GearGrimoireOfEmbers" }, { Name = "Grimoire of Hoarfrost", Image = "GearGrimoireOfHoarfrost" }, { Name = "Grimoire of Gales", Image = "GearGrimoireOfGales" } },
		Epic = { { Name = "Stormcall Grimoire", Image = "GearStormcallGrimoire" }, { Name = "Gloamforge Grimoire", Image = "GearGloamforgeGrimoire" }, { Name = "Nightloom Grimoire", Image = "GearNightloomGrimoire" } },
		Legendary = { { Name = "Yamiyo, the Dark Night", Image = "GearYamiyo" }, { Name = "Seiza, the Star Chart", Image = "GearSeiza" }, { Name = "Rinkou, the Pale Glow", Image = "GearRinkou" } },
	},
}

return { ByKind = ByKind }
