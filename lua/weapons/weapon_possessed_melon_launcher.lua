
AddCSLuaFile()

SWEP.PrintName = "PossMelLaunch"
SWEP.ShopName = "Possessed Melon Launcher"
SWEP.Author = "spaaz"
SWEP.Purpose = "Shoot homing shards with primary attack and possessed melons with secondary attack."

SWEP.Slot = 1
SWEP.SlotPos = 2

SWEP.Spawnable = true

SWEP.ViewModel = Model( "models/weapons/c_smg1.mdl" )
SWEP.WorldModel = Model( "models/weapons/w_smg1.mdl" )
SWEP.ViewModelFOV = 54
SWEP.UseHands = true
SWEP.ViewModelFlip              = false

SWEP.Base 			= "weapon_tttbase"
SWEP.Kind           = WEAPON_EQUIP1

if engine.ActiveGamemode() == "terrortown" then
	SWEP.Primary.ClipSize = GetConVar("possessed_melon_ammo"):GetInt()
	SWEP.Primary.DefaultClip = GetConVar("possessed_melon_ammo"):GetInt()
else
	SWEP.Primary.ClipSize = -1
	SWEP.Primary.DefaultClip = -1
end
SWEP.Primary.Automatic = true
SWEP.DrawWeaponInfoBox	= false
SWEP.Primary.Ammo = "none"
SWEP.Primary.Recoil            = 1

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= true
SWEP.Secondary.Ammo		= "none"
SWEP.CanBuy			= { ROLE_TRAITOR }
SWEP.FireMode = 0

SWEP.DrawAmmo = true

game.AddParticles( "particles/hunter_flechette.pcf" )
game.AddParticles( "particles/hunter_projectile.pcf" )

local ShootSound = Sound( "NPC_Hunter.FlechetteShoot" )
local ShootSound2 = Sound( "weapons/grenade_launcher1.wav" )
local ReloadSound = Sound( "weapons/smg1/smg1_reload.wav" )
SWEP.RollerEnt = NULL

function SWEP:Initialize()

	self:SetHoldType( "smg" )

end
	
if ( !CLIENT ) then
local NextTime = CurTime()
	function SWEP:Think()
		if CurTime() > NextTime then
			NextTime = CurTime() + 0.01
			if IsValid(self.Owner) then
				for _, ent in pairs(ents.FindByName( "PML_Flechette" )) do
					if ent.Owner == self.Owner then
						local curMelPos = nil
						local curDist = math.huge
						local entPos = ent:GetPos()
						for _, mel in pairs(ents.FindByName( "PML_Melon" )) do
							local melPos = mel:GetPos()										
							local vec01 = melPos - entPos
							vec01:Normalize()
							local vec02 = ent:GetAngles():Forward()
							local angMod = math.acos(vec01:Dot(vec02))
							local dist = entPos:DistToSqr( melPos ) * angMod * angMod * angMod

							if ( dist < curDist ) and angMod < 1.5 then
								curMelPos = melPos
								curDist = dist
							end
						end
						if curMelPos then
							if !(ent:GetMoveType() == MOVETYPE_NONE) then
								local Vel = ent:GetAbsVelocity()
								if Vel:Length()>500 then
									local VelMod = curMelPos - entPos
									local LenMod = VelMod:Length()*-2 + 2000
									if LenMod > 0 and CurTime() > ent.MagTime then

										Vel:Normalize()
										VelMod:Normalize()
										local Dot = Vel:Dot(VelMod)
										VelMod = VelMod - Vel*Dot
	
										VelMod = VelMod*LenMod + ent:GetAbsVelocity()
										VelMod:Normalize()
										ent:SetAngles(VelMod:Angle()+ Angle(-8,0,0))
										ent:SetVelocity( (VelMod * 2500)-ent:GetAbsVelocity())
									end
								end
							end
						end 					
					end
				end
			end
		end
	end
end

function SWEP:Reload()
	if ( self:Clip1() < self.Primary.ClipSize && self.Owner:GetAmmoCount( self.Primary.Ammo ) > 0 ) then
		self.Weapon:SetSequence("fire01")
		self:EmitSound( ReloadSound )
		if self.Owner:GetAmmoCount( self.Primary.Ammo ) < self.Primary.ClipSize then
			self:SetClip1( GetAmmoCount( self.Primary.Ammo ) )
			self.Owner:RemoveAmmo( GetAmmoCount( self.Primary.Ammo ), self.Primary.Ammo )
		else
			self:SetClip1( self.Primary.ClipSize )
			self.Owner:RemoveAmmo( self.Primary.ClipSize, self.Primary.Ammo )
		end
			
	end
end

function SWEP:CanBePickedUpByNPCs()
	return true
end

function SWEP:PrimaryAttack()
	
	if self:Clip1() == 0 then return end
	
	if self:Clip1() > 0 then
		self:SetClip1(self:Clip1() - 1)
	end
	self:SetNextPrimaryFire( CurTime() + 0.08 )

	self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
	self:EmitSound( ShootSound )
	--self:ShootEffects( self )

	if ( CLIENT ) then return end

	SuppressHostEvents( NULL ) -- Do not suppress the flechette effects

	local ent = ents.Create( "hunter_flechette" )
	if ( !IsValid( ent ) ) then return end

	local Forward = Vector(1,0,0)
	Forward:Rotate(self.Owner:EyeAngles()) 
	local ADown = Vector(0,0,-1)
	local Right = ADown:Cross(Forward)
	Right:Normalize()
	local Down = Forward:Cross(Right)

	local pos = self.Owner:GetShootPos() + Forward * 40 + Down * 6.5 + Right * 8.5
	ent:SetPos(pos)

	local SAng = Angle( math.Rand(-0.8,1.2),math.Rand(-0.8,1.2),0)
	Forward:Rotate(SAng)
	SAng:Add(Angle(-8,0,0))
	SAng:Add(self.Owner:EyeAngles())
	ent:SetAngles( SAng )
	ent:SetOwner( self.Owner )
	ent:Spawn() 	
	ent:Activate()
	ent:SetVelocity( Forward * 2500 )
	ent:SetName( "PML_Flechette" )
	ent.MagTime = CurTime() + .06
	local prop = ents.Create( "prop_physics" )
	prop:SetModel("models/props_junk/watermelon01_chunk02a2.mdl")
	prop:SetPos(pos)
	prop:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	prop:Spawn() 	
	prop:Activate()
	prop:SetParent(ent)
	prop:SetAngles( SAng + Angle(0,0,1)*math.Rand(0,360) )
	ent:SetColor( Color( 0, 0, 0, 0 ) ) 
	ent:SetRenderMode( RENDERMODE_TRANSCOLOR )

end

function SWEP:Deploy()
	self:SendWeaponAnim(ACT_VM_DRAW)
	
	if ( SERVER ) then return end
	if GetConVar( "possessed_melon_hud" ):GetBool() then
		LocalPlayer():ChatPrint("set \"possessed_melon_hud 0\" in console to turn off hud")
	end
end

function SWEP:SecondaryAttack()

	if self:Clip1() < 16 then return end
	
	self:SetClip1(self:Clip1() - 16)
	
	self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)
	self:EmitSound( ShootSound2 )
	
	if ( CLIENT ) then return end
	
	local Forward = Vector(1,0,0)
	Forward:Rotate(self.Owner:EyeAngles())
	
	local spawn = self.Owner:GetShootPos() + Forward * 45
	local angl = Angle(0,0,0)
	angl:Random()

	local RollerEnt = ents.Create( "npc_rollermine" )
	RollerEnt:SetPos( spawn )
	RollerEnt:SetAngles( angl )
	RollerEnt:Spawn()
	RollerEnt:SetKeyValue( "SpawnFlags", 65536 )
	RollerEnt:AddEntityRelationship(self.Owner,4,99)
	RollerEnt:SetModel("models/props_junk/watermelon02.mdl")
	RollerEnt:PhysicsInit( SOLID_VPHYSICS )
	RollerEnt:SetName("PML_Melon")
	local phy = RollerEnt:GetPhysicsObject()
	--phy:AddGameFlag( 1028 )
	phy:SetMass( 100 )
	RollerEnt.Owner = self.Owner
	RollerEnt:CallOnRemove("melonSpawn",function(ent)
		local pos = ent:GetPos()
		local ang = ent:GetAngles()
		local vel = ent:GetVelocity()
		local mel = ents.Create( "prop_dynamic" )
		mel:SetPos( pos )
		mel:SetAngles( ang )
		mel:SetModel("models/props_junk/watermelon02.mdl")
		mel:SetName("PML_MelonExplode")
		mel:Spawn()
		mel:SetVelocity(vel)
		
		timer.Simple(0.1,function()
			local d = DamageInfo()
			d:SetDamage( 100 )
			d:SetAttacker( mel )
			d:SetDamageType( DMG_BLAST ) 

			mel:TakeDamageInfo( d )
		end)

	end)
	self:SetNextSecondaryFire( CurTime() + .6 )
	phy:SetVelocity(Forward * 1200)

end

function SWEP:DrawHUD()
	
	if ( SERVER ) then return end
	if GetConVar( "possessed_melon_hud" ):GetBool() then
		local sWidth = ScrH() / 2
		local sHight = ScrH() / 4
		local xMargin = (ScrW() / 2) - (ScrH() / 4)
		local yMargin = (ScrH() / 4) *3
		surface.SetMaterial(Material("vgui/possessed_melon_launcher_vgui"))
		surface.SetDrawColor( 255, 255, 255, 255 )
		surface.DrawTexturedRect(xMargin,yMargin,sWidth,sHight)
	end
			
end
			
function SWEP:ShouldDropOnDie()

	return true

end

function SWEP:GetNPCRestTimes()

	-- Handles the time between bursts
	-- Min rest time in seconds, max rest time in seconds

	return 0.3, 0.6

end

function SWEP:GetNPCBurstSettings()

	-- Handles the burst settings
	-- Minimum amount of shots, maximum amount of shots, and the delay between each shot
	-- The amount of shots can end up lower than specificed

	return 1, 6, 0.1

end

function SWEP:GetNPCBulletSpread( proficiency )

	-- Handles the bullet spread based on the given proficiency
	-- return value is in degrees

	return 1

end

if CLIENT then

	CreateClientConVar( "possessed_melon_hud",1,"set to 0 to turn off hud for the possessed melon launcher")
   SWEP.Icon = "vgui/ttt/icon_possmellaunch"

   -- Text shown in the equip menu
   SWEP.EquipMenuData = {
      type = "Weapon",
      desc = "Shoot homing shards with primary attack\nand possessed melons with secondary attack"
   };
end
