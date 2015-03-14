-- Our list of prefab files that this mod includes
PrefabFiles = {
	"pickleit_veggies",
	"pickled_foods",
	"world_plants",

	"pickle_barrel",
	"mush_pickled",

	"pigs_foot",
	"pigs_foot_cooked",
	
	"pickle_sword",
}

local assets=
{
    Asset("ATLAS", "images/inventoryimages/pickle_barrel.xml"),
    Asset("IMAGE", "images/inventoryimages/pickle_barrel.tex"),
}

local require = GLOBAL.require
require "pickleit_strings"

AddMinimapAtlas("images/inventoryimages/pickle_barrel.xml")

-- Add the pickleit action (Controller support!)
local Action = GLOBAL.Action
local ActionHandler = GLOBAL.ActionHandler
local Pickleit = Action()
Pickleit.str = "Pickle"
Pickleit.id = "PICKLEIT"
Pickleit.fn = function(act)
	if act.target.components.pickler ~= nil then
       if not act.target.components.pickler:CanPickle() then
           return false
       end

       act.target.components.pickler:StartPickling()

       return true
	end

	return false
end 
AddAction(Pickleit)
AddStategraphActionHandler('wilson', ActionHandler(Pickleit, "dolongaction"))

-- Make pig foot loot stuffs
local function AddPigLootInternal(prefab)
	prefab.components.lootdropper:AddChanceLoot('pigs_foot',1)
	prefab.components.lootdropper:AddChanceLoot('pigs_foot',.5)
end

-- Add a loot drop to pigmen
local function AddPigLoot(prefab)
	AddPigLootInternal(prefab)
	prefab:ListenForEvent("transformwere", AddPigLootInternal)
	prefab:ListenForEvent("transformnormal", AddPigLootInternal)
end

AddPrefabPostInit("pigman", AddPigLoot)
AddPrefabPostInit("pigguard", AddPigLoot)
