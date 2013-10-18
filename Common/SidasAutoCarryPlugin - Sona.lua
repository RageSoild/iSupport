--[[
	   _ ____                        __    ____        _       
	  (_) __/_ _____  ___  ___  ____/ /_  / __/__ ____(_)__ ___
	 / /\ \/ // / _ \/ _ \/ _ \/ __/ __/ _\ \/ -_) __/ / -_|_-<
	/_/___/\_,_/ .__/ .__/\___/_/  \__/ /___/\__/_/ /_/\__/___/
         	  /_/  /_/                                         

	Sona - Marven of the Chords

	Features:
		- Intelligent Power Cord management
			- Uses VALOR to poke down the enemy and harass them out of lane
			- Uses PERSEVERANCE when a nearby enemy attacks a nearby ally or 
			  when a nearby ally is killable or the health of a nearby ally is lower
			  then a enemy within their attack range 
			- Uses CELERITY when a nearby ally attacks a nearby enemy or 
			  when a nearby enemy is killable or the health of a nearby enemy is 
			  higher then an ally within their attack range
		- Powerful Auto Mode 
			- Allows you to focus on movement manually while letting the plugin automatically
			  manage your spells 
		- Smart chords
			- Pokes enemies using custom collision to maximize damage 
			- Heals nearby allies according to the user settings for health threshold 
			- Gives local allies movement speed when they take damage from a turret 
		- Auto-Cresendo 
			- Monitors cresendo collision and automatically ultimates the minimum number 
			  of enemies. 

--]]

require "iFoundation_v2"

class 'Plugin' -- {
	
	if myHero.charName ~= "Sona" then return end 
	local SkillQ = Caster(_Q, 1000, SPELL_SELF)
	local SkillW = Caster(_W, 1000, SPELL_SELF)
	local SkillE = Caster(_E, 1000, SPELL_SELF)
	local SkillR = Caster(_R, 1000, SPELL_LINEAR)

	local rCollision = nil

	local pTarget = nil 
	local pCord = nil 

	local Ally, damage = nil, nil 
	local targetDamage = 0

	local Menu = nil

	NONE = 0 -- DERP?
	VALOR = 1 -- AD/AP BUFF (x2 DMG)
	PERSEVERANCE = 2 -- RESISTANCE BUFF (20% DMG REDUCE)
	CELERITY = 3 -- MOVEMENT SPEED BUFF (40% MSPEED REDUCE)

	local AuraTable = {
		["valor"] = VALOR, 
		["perseverance"] = PERSEVERANCE, 
		["discord"] = CELERITY
	}

	local currentAura = NONE 
	local powerCord = false 
	
	function Plugin:__init() 
		AutoCarry.Crosshair:SetSkillCrosshairRange(1000)
		AutoShield.Instance(SkillW.range, SkillW)
		rCollision = Collision(SkillR.range, SkillR.speed, SkillR.delay, SkillR.width)
		AdvancedCallback:bind('OnGainBuff', function(unit, buff) self:OnGainBuff(unit, buff) end)
		AdvancedCallback:bind('OnLoseBuff', function(unit, buff) self:OnLoseBuff(unit, buff) end)
	end 

	function Plugin:OnTick() 
		Target = AutoCarry.Crosshair:GetTarget()
		MultiTarget = GetMultiCresendo()
		if MultiTarget and SkillR:Ready() then 
			SkillR:Cast(MultiTarget)
		elseif AutoCarry.Keys.AutoCarry or not Menu.AutoStop then
			Heal()
			if Target then 
				if powerCord then 
					if pTarget then 
						if GetDistance(pTarget) <= Combat.GetTrueRange() + 500 and not pTarget.isDead then 
							Target = pTarget 
						else 
							pCord = nil 
							pTarget = nil 
						end 
					end 
					if pCord then 
						if currentAura == pCord and GetDistance(Target) < Combat.GetTrueRange() + 200 then 
							myHero:Attack(Target)
						else 
							PowerCord(pCord)
						end 
					else
						-- other methods
						local ally = GetNearestAllyToEnemy(1000)
						if ally then 
							local killable = DamageCalculation.CalculateRealDamage(Target, ally) > Target.health
							local friendlyKillable = DamageCalculation.CalculateRealDamage(ally, Target) > ally.health
							if ally.health > Target.health or killable then 
								PowerCord(CELERITY)
							elseif ally.health < Target.health or friendlyKillable then
								PowerCord(PERSEVERANCE)
							elseif getDmg("Q", Target, myHero, 3) * 2 < Target.health then 
								PowerCord(VALOR)
							end 
						end 
					end 
				else 
					Poke(Target)
				end  
			end 			
		end
	end 

	function Plugin:OnLoad() 
	end 

	function Plugin:OnGainBuff(unit, buff) 
		if unit and buff then
			if buff.name == "sonapowerchord" then
				powerCord = true 
				PrintFloatText(myHero, 1, "PowerCord!")
				AutoCarry.MyHero.CanAttack = false 
			end 
			for aura, value in pairs(AuraTable) do 
				if buff.name:find(aura) then 
					currentAura = value
					break 
				end 
			end 
		end 
	end 

	function Plugin:OnLoseBuff(unit, buff) 
		if unit and buff then 
			if buff.name == "sonapowerchord" then
				powerCord = false
				AutoCarry.MyHero.CanAttack = true 
				pTarget = nil 
				pCord = nil 
			end 
		end 
	end 

	function Plugin:OnProcessSpell(object, spell)
		if object and spell then 
			--> Allies 
			if object.team ~= myHero.team then 
				for i=1, heroManager.iCount do 
					local p = heroManager:GetHero(i)
					if p and not p.dead and p.team == myHero.team then
						if AutoShield.SpellHit(object, spell, p) or (object.type == "obj_AI_Turret" and GetDistance(p, spell.endPos) < 80) then
							if GetDistance(object) <= Combat.GetTrueRange() + 500 and powerCord then 
								PowerCord(PERSEVERANCE)
								pTarget = object 
								return 
							end
						end  
					end 
				end 
			end 
			--> Enemies
			if object.team == myHero.team then 
				for i=1, heroManager.iCount do 
					local p = heroManager:GetHero(i)
					if p and not p.dead and p.team ~= myHero.team then
						if AutoShield.SpellHit(object, spell, p) or (object.type == "obj_AI_Turret" and GetDistance(p, spell.endPos) < 80) then 
							if GetDistance(object) <= Combat.GetTrueRange() + 500 and powerCord then 
								PowerCord(CELERITY)
								pTarget = p  
								return 
							end
						end 
					end 
				end 
			end 
		end 
	end 

	function PowerCord(mode)
		if powerCord then 
			if mode == VALOR and currentAura ~= VALOR then 
				CastSpell(_Q)
			elseif mode == PERSEVERANCE and currentAura ~= PERSEVERANCE then 
				CastSpell(_W)
			elseif mode == CELERITY and currentAura ~= CELERITY then 
				CastSpell(_E)
			end 
			if not pCord then 
				pCord = mode 
			end 
		end 
	end 

	function GetSurroundingAllies(Range)
		local result = {}
		for i=1, heroManager.iCount do 
			local p = heroManager:GetHero(i)
			if p and not p.dead and p.team == myHero.team and GetDistance(p) <= Range then 
				table.insert(result, p) 
			end 
		end 
		return result 
	end 

	function GetNearestAllyToEnemy(range) 
		local distance = math.huge
		local best = nil 
		for _, ally in pairs(GetSurroundingAllies(range)) do 
			if ally and not ally.dead then 
				for i=1, heroManager.iCount do 
					local p = heroManager:GetHero(i)
					if p and not p.dead and p.team ~= myHero.team then 
						if GetDistance(ally, p) <= distance then 
							best = ally 
							distance = GetDistance(ally, p)
						end 
					end 
				end 
			end 
		end 
		return best 
	end 

	function Poke(Target)
		if not SkillQ:Ready() or not Target then return end 
		if GetDistance(Target) < SkillQ.range then 
			if not QCollision(Target) then 
				CastSpell(_Q) 
			end 
		end 
	end 

	function QCollision(Target)
		local distance = GetDistance(Target)
		local collide = 0 
		for index, minion in pairs(AutoCarry.EnemyMinions().objects) do 
			if minion and not minion.dead then 
				if GetDistance(minion) <= distance then 
					collide = collide + 1
				end 
			end 
		end 
		return collide > 1 
	end 

	function Heal() 
		if not SkillW:Ready() or powerCord then return end 
		for i=1, heroManager.iCount do 
			local p = heroManager:GetHero(i)
			if p and not p.dead and p.team == myHero.team then
				if GetDistance(p) <= SkillQ.range then 
					if (p.health / p.maxHealth) < (Menu.wPercent / 100) then 
						CastSpell(_W)
						return 
					end 
				end  
			end 
		end 
	end 

	function GetMultiCresendo() 
		local hitCount = 0 
		for _, enemy in pairs(GetEnemyHeroes()) do 
			if enemy and not enemy.dead and GetDistance(enemy) <= SkillR.range then 
				hit, heros = rCollision:GetHeroCollision(myHero, enemy, 2) 
				if hit then 
					for i, hero in pairs(heros) do 
						if hero and not hero.dead and GetDistance(enemy) <= SkillR.range then 
							hitCount = hitCount + 1 
						end 
					end 
				end 
				if hitCount >= Menu.rCol then 
					return enemy 
				end 
				hitCount = 0
			end 
		end 
	end 

	Menu = AutoCarry.Plugins:RegisterPlugin(Plugin(), "Sona") 
	Menu:addParam("wPercent", "Heal Percentage",SCRIPT_PARAM_SLICE, 75, 0, 100, 0)
	Menu:addParam("rCol", "Auto R amount of players",SCRIPT_PARAM_SLICE, 2, 0, 5, 0)
	Menu:addParam("AutoStop", "Disable Auto Heal", SCRIPT_PARAM_ONKEYTOGGLE, false, 86) 
-- }