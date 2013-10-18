--[[

	   _ ____                        __    ____        _       
	  (_) __/_ _____  ___  ___  ____/ /_  / __/__ ____(_)__ ___
	 / /\ \/ // / _ \/ _ \/ _ \/ __/ __/ _\ \/ -_) __/ / -_|_-<
	/_/___/\_,_/ .__/ .__/\___/_/  \__/ /___/\__/_/ /_/\__/___/
          /_/  /_/                                         

    Nidalee - 

    Features: 
    	- Cougar/Human management 
    		- Automatically monitors which form we are in for maximum damage output 
    		- Run-away mode that automatically switches you into cougar form 
    	- Powerful Q prediction 
    		- Utilizies Klokje's newest PROdiction for unpresidented Q accuracy 
    	- Utilizes iFoundation's iHealing Library 
    		- Please read iHealing 
--]]

require "iFoundation_v2"

class 'Plugin' -- {
	
	if myHero.charName ~= "Nidalee" then return end 
	local HumanQ = Caster(_Q, 1500, SPELL_LINEAR_COL, 1300, 0.100, 60, true)
	local HumanW = Caster(_W, 900, SPELL_CIRCLE, math.huge, 0.900, 80, true)
	local HumanE = Caster(_E, 600, SPELL_TARGETED_FRIENDLY)

	local CougarQ = Caster(_Q, 225, SPELL_SELF) 
	local CougarW = Caster(_W, 375, SPELL_SELF)
	local CougarE = Caster(_E, 300, SPELL_SELF)

	local SkillQ = HumanQ 
	local SkillW = HumanW 
	local SkillE = HumanE
	local SkillR = Caster(_R, math.huge, SPELL_SELF)

	local Menu = nil

	local isCougar = false

	local combo = ComboLibrary()

	function Plugin:__init() 
		AutoCarry.Crosshair:SetSkillCrosshairRange(1500)
		combo:AddCasters({SkillQ, SkillW, SkillE, SkillR})
		AutoShield.Instance(HumanE.range, HumanE)
		combo:AddCustomCast(_Q, function(Target) return ValidTarget(Target, SkillQ.range) end)
		combo:AddCustomCast(_W, function(Target) return ValidTarget(Target, SkillW.range) end)
		combo:AddCustomCast(_E, function(Target) return ValidTarget(Target, SkillE.range) end)
		combo:AddCustomCast(_R, function(Target) 
				if isCougar then 
					return (GetDistance(Target) > 500) and (myHero.health / myHero.maxHealth) > (Menu.escapeHp / 100) 
				else 
					return GetDistance(Target) < 225 or (myHero.health / myHero.maxHealth) < (Menu.escapeHp / 100) 
				end 
			end)
	end 

	function Plugin:OnTick() 
		Target = AutoCarry.Crosshair:GetTarget()
		HealTarget = iHealing.Instance():GetTarget(SkillE.range)
		isCougar = myHero:GetSpellData(_Q).name == "Takedown"
		UpdateSkills()
		if AutoCarry.Keys.AutoCarry then
			if Target then 
				combo:CastCombo(Target) 
			end 
			if not isCougar and HealTarget and (HealTarget.health / HealTarget.maxHealth) < (Menu.heal / 100) then 
				CastSpell(_E, HealTarget)
			end 
		end
	end 

	function Plugin:OnLoad() 
		PrintChat("Loaded >> iSupport Series: Nidalee (1.0)")
	end 

	function UpdateSkills()
		if isCougar then 
			combo:UpdateCaster(_Q, CougarQ)
			combo:UpdateCaster(_W, CougarW)
			combo:UpdateCaster(_E, CougarE)
		else
			combo:UpdateCaster(_Q, HumanQ)
			combo:UpdateCaster(_W, HumanW)
			combo:UpdateCaster(_E, HumanE) 
		end 
	end 

	Menu = AutoCarry.Plugins:RegisterPlugin(Plugin(), "Nidalee") 
	Menu:addParam("desc1","-- Spell Options --", SCRIPT_PARAM_INFO, "")
	Menu:addParam("escapeHp", "Cougar Override HP (runaway)",SCRIPT_PARAM_SLICE, 25, 0, 100, 0)
	Menu:addParam("heal", "Heal HP",SCRIPT_PARAM_SLICE, 75, 0, 100, 0)
-- }