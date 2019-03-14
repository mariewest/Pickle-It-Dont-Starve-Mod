-- Our list of prefab files that this mod includes
PrefabFiles = {
	"pickleit_veggies",
	"pickled_foods",
	"world_plants",

	"pickle_barrel",
	"mush_pickled",

	"pigs_foot",
	"pigs_foot_cooked",
	"pigs_foot_dried",
	"pickle_sword",
}

local assets=
{
    Asset("ATLAS", "images/inventoryimages/pickle_barrel.xml"),
    Asset("IMAGE", "images/inventoryimages/pickle_barrel.tex"),
}

local require = GLOBAL.require
require "pickleit_strings"
require "pickleit_helpers"

AddMinimapAtlas("images/inventoryimages/pickle_barrel.xml")

-- Add the pickleit action (Controller support!)
local Action = GLOBAL.Action
local ActionHandler = GLOBAL.ActionHandler
local Pickleit = Action({mount_enabled=false})
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

-- Meatrack overload for pigs_foot on meatrack
local function ModDryingRack(inst)

	local oldonstartdrying = inst.components.dryer.onstartcooking
	local onstartdrying = function(inst, dryable, ...)
		if dryable == "pigs_foot" then
		    inst.AnimState:PlayAnimation("drying_pre")
			inst.AnimState:PushAnimation("drying_loop", true)
			inst.AnimState:OverrideSymbol("swap_dried", "pigs_foot", "pigs_foot_hanging")
			return
		end

		return oldonstartdrying(inst, dryable, ...)
	end

	local oldsetdone = inst.components.dryer.oncontinuedone
	local setdone = function(inst, product, ...)
	    if product == "pigs_foot_dried" then
		    inst.AnimState:PlayAnimation("idle_full")
		    inst.AnimState:OverrideSymbol("swap_dried", "pigs_foot", "pigs_foot_dried_hanging")
		    return
	    end

	    return oldsetdone(inst, product, ...)
	end

    inst.components.dryer:SetStartDryingFn(onstartdrying)
    inst.components.dryer:SetContinueDryingFn(onstartdrying)
	inst.components.dryer:SetDoneDryingFn(setdone)
    inst.components.dryer:SetContinueDoneFn(setdone)
end
 
AddPrefabPostInit("meatrack", ModDryingRack)

-- Override for potatos on farm giving multiples
local Crop = require('components/crop')
local oldCropHarvest = Crop.Harvest
Crop.Harvest = function(self, harvester, ...)
    if self.product_prefab == "potato" then
	    if self.matured then
			local product = GLOBAL.SpawnPrefab(self.product_prefab)
	        if harvester then
	        	local rnd = math.random() * 100
	        	local count = 0
	        	if rnd <= 20 then count = 1 elseif rnd <= 60 then count = 2 else count = 3 end
	        	product.components.stackable:SetStackSize(count)
	            harvester.components.inventory:GiveItem(product)
	        else
	            product.Transform:SetPosition(self.grower.Transform:GetWorldPosition())
	            Launch(product, self.grower, TUNING.LAUNCH_SPEED_SMALL)
	        end 
	        GLOBAL.ProfileStatsAdd("grown_"..product.prefab) 
	        
	        self.matured = false
	        self.growthpercent = 0
	        self.product_prefab = nil
	        self.grower.components.grower:RemoveCrop(self.inst)
	        self.grower = nil
	        
	        return true
	    end
	    return
	end

	return oldCropHarvest(self, harvester, ...)
end