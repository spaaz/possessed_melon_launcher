CreateConVar( "possessed_melon_exp_dam_mod", 1 ,{ FCVAR_ARCHIVE, FCVAR_NOTIFY }, "damage modifier for possessed melons exploding" )
CreateConVar( "possessed_melon_phy_dam_mod", 0.05 ,{ FCVAR_ARCHIVE, FCVAR_NOTIFY }, "damage modifier for possessed melon physics" )
CreateConVar( "possessed_melon_sha_dam_mod", 0.2 ,{ FCVAR_ARCHIVE, FCVAR_NOTIFY }, "damage modifier for homing shards" )
CreateConVar( "possessed_melon_ammo", 224 ,{ FCVAR_ARCHIVE, FCVAR_NOTIFY }, "amount of ammo for the possessed melon launcher" )

if ( CLIENT ) then return end

hook.Add("EntityTakeDamage","melondmg",function(target,dmgInfo)
	local inf = dmgInfo:GetInflictor()
	local att = dmgInfo:GetAttacker()
	if target:GetClass() == "npc_rollermine" and target:GetName() == "PML_Melon" then
		dmgInfo:SetDamageType(DMG_BLAST)
		if IsEntity( att ) and att:IsPlayer() then
			target.Owner = att
		end
	end
	if att and IsEntity(att) and att:IsValid() and att:GetClass() == "npc_rollermine" and att:GetName() == "PML_Melon" then
		if bit.band(dmgInfo:GetDamageType(), DMG_CRUSH) == 0 then
			dmgInfo:ScaleDamage(GetConVar("possessed_melon_exp_dam_mod"):GetFloat())
		else
			dmgInfo:ScaleDamage(GetConVar("possessed_melon_phy_dam_mod"):GetFloat())
		end
		if IsValid(att.Owner) then
			dmgInfo:SetInflictor(att)
			dmgInfo:SetAttacker(att.Owner)
		end		
	end
	if inf and IsEntity(inf) and inf:IsValid() and inf:GetClass() == "hunter_flechette" and inf:GetName() == "PML_Flechette" then
		if bit.band(dmgInfo:GetDamageType(), DMG_NEVERGIB) == 0  then
			dmgInfo:ScaleDamage(GetConVar("possessed_melon_sha_dam_mod"):GetFloat()*2)
		else
			dmgInfo:ScaleDamage(GetConVar("possessed_melon_sha_dam_mod"):GetFloat())
		end
	end
end)

hook.Add( "Think", "melonThink" , function()
	if SERVER then
		for i, ent in ipairs(ents.FindByClass( "npc_rollermine" )) do
			if ent:GetName() == "PML_Melon" then
				local phy = ent:GetPhysicsObject()
				local enemy = ent:GetEnemy()
				if enemy and phy then
					local pos = ent:GetPos()
					local yeet = enemy:GetPos() - pos
					local length = yeet:Length()
					if length > 60 then
						local vel = ent:GetVelocity()
						local enemyVel = enemy:GetVelocity()
						local yeetforce = math.Clamp(yeet:Length(),100,200)*10
						if length < 300 then
							yeet = yeet + (enemyVel - vel)*Vector(1,1,0)
						end
						yeet:Normalize()
		
						phy:ApplyForceOffset(yeet * yeetforce, pos + Vector(0,0,5))
					else
						local vel = ent:GetVelocity()
						local enemyVel = enemy:GetVelocity()
						local yeetforce = math.Clamp(yeet:Length(),100,200)*10						
						yeet = yeet + (vel - enemyVel)*Vector(1,1,0)
						yeet:Normalize()
		
						phy:ApplyForceOffset(yeet * yeetforce, pos + Vector(0,0,5))
					end
				end
			end
		end
	end
end)