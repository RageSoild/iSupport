--[[
	
	   _ ____                        __    ____        _       
	  (_) __/_ _____  ___  ___  ____/ /_  / __/__ ____(_)__ ___
	 / /\ \/ // / _ \/ _ \/ _ \/ __/ __/ _\ \/ -_) __/ / -_|_-<
	/_/___/\_,_/ .__/ .__/\___/_/  \__/ /___/\__/_/ /_/\__/___/
         	  /_/  /_/                                         
	
	Features:
		- Powerful PROdiction
			- Extremely accurate Q's
		- Utilizes iHealing for accurate heal and poke potential 


--]]
require "iFoundation_v2"

class 'Plugin' -- {
	
	if myHero.charName ~= "Nami" then return end 
	local SkillQ = Caster(_Q, 850, SPELL_CIRCLE, math.huge, 0.400, true)
	local SkillW = Caster(_W, 725, SPELL_TARGETED)
	local SkillR = Caster(_R, 1000, SPELL_LINEAR, 1200, 0.500, true) 
	local combo = ComboLibrary()
	local Menu = nil
	
	function Plugin:__init() 
		AutoCarry.Crosshair:SetSkillCrosshairRange(1000)
		combo:AddCasters({SkillQ, SkillW, SkillR})
		--combo:AddCustomCast(_R, function(Target) return Menu.useR end)
	end 

	function Plugin:OnTick() 
		Target = AutoCarry.Crosshair:GetTarget()
		HealTarget = iHealing.Instance():GetTarget(SkillW.range)
		if Menu.useR then 
			SkillR:CastMouse(mousePos)
		elseif Target and AutoCarry.Keys.AutoCarry then
			combo:CastCombo(Target) 
			if HealTarget and (HealTarget.health / HealTarget.maxHealth) < (Menu.heal / 100) then 
				CastSpell(_W, HealTarget)
			end 
		end
	end 

	function Plugin:OnLoad() 
		Priority.Instance(true)
		PrintChat("Loaded >> iSupport Series: Nami (1.0)")
	end 

	Menu = AutoCarry.Plugins:RegisterPlugin(Plugin(), "Nami") 
	--Menu:addParam("AutoBubble", "Auto-Bubble", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("useR", "Use Ultimate", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("R"))
	Menu:addParam("heal", "Heal HP",SCRIPT_PARAM_SLICE, 75, 0, 100, 0)
-- }