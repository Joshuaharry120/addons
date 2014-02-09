if GetConVarString( "gamemode" ) ~= "murder" then return end
CATEGORY_NAME = "Murder"

//////////////////////////////////////////////////////////
//												    	//
//				SLAY NEXT ROUND (!slaynr)				//		   
//	This command slays the target at the beggining of 	//
//	the next round, preventing them from spawning as	//
//	the Murderer to stop rounds being cut short. You	//
//	can also specify the amount of rounds the player 	//
//	should be slain for. Slays do not count if targets 	//
//	are in spectator mode, and carry on after the 		//
//	target disconnects (if enabled).					//
//														//
//////////////////////////////////////////////////////////

--[[			CONFIG 			]]--
local slaynr_ban = true
// Should players with autoslays be banned if they disconnect?
// (true/false)
local slaynr_culumativeban = true
// Should the number of minutes be multiplied by the amount of slays the player has?
// (true/false)
local slaynr_banmins = 200
// Number of minutes the player should be banned for (multiplied by no. of slays if culumative bans enabled)
// (number)
local slaynr_keepslays = false
// Should the player keep the slays they have if they get banned for slay evading?
// (true/false)

function ulx.slaynr( caller, targets, rounds, shouldslay )

	for k, v in pairs( targets ) do
		
		if not shouldslay then
			v:SetPData( "NRSLAY_SLAYS", rounds )
			v.MurdererChance = 0
			str = "#A set #T to be autoslain for "..rounds.." round(s)"
		else
			v:RemovePData( "NRSLAY_SLAYS" )
			v.MurdererChance = 1
			str = "#A removed all autoslays against #T"
		end
		
	end

	ulx.fancyLogAdmin( caller, false, str, targets )

end
local slaynr = ulx.command( CATEGORY_NAME, "ulx slaynr", ulx.slaynr, "!slaynr" )
slaynr:addParam{ type=ULib.cmds.PlayersArg }
slaynr:addParam{ type=ULib.cmds.NumArg, max=100, default=1, hint="rounds", ULib.cmds.optional, ULib.cmds.round }
slaynr:addParam{ type=ULib.cmds.BoolArg, invisible=true }
slaynr:defaultAccess( ULib.ACCESS_ADMIN )
slaynr:help( "Slays the target at the beggining of the next round." )
slaynr:setOpposite( "ulx unslaynr", { _, _, _, true }, "!unslaynr" )

hook.Add( "OnStartRound", "Autoslays", function()

	timer.Simple( 3, function()
		
		for k, v in pairs( player.GetAll() ) do
			
			if v:GetObserverTarget() then continue end

			slays, reconnect = tonumber( v:GetPData( "NRSLAY_SLAYS" ) ) or 0, v:GetPData( "NRSLAY_LEAVE" ) or false

			if slays > 0 then
				slays = slays-1

				if slays == 0 then
					v:RemovePData( "NRSLAY_SLAYS" )
					v.MurdererChance = 1
				else
					v:SetPData( "NRSLAY_SLAYS", slays )
					v.MurdererChance = 0
				end
				
				ulx.fancyLogAdmin( nil, false, "Autoslayed #T", v )
				v:Kill()
				if reconnect then
					ULib.tsay( v, "You have been autoslain after leaving with active autoslays", true )
					v:RemovePData( "NRSLAY_LEAVE")
				end

			end

		end

	end )

end )

hook.Add( "PlayerInitialSpawn", "PreventReconnectingMurderer", function( ply )

	slays = tonumber( ply:GetPData( "NRSLAY_SLAYS" ) ) or 0
	if slays > 0 then
		ply.MurdererChance = 0
	end

end )

hook.Add( "PlayerDisconnected", "BanThemSlayEvaders", function( ply )

	if slaynr_ban then

		slays = ply:GetPData( "NRSLAY_SLAYS" ) or 0

		if slays > 0 then
			RunConsoleCommand( "ulx", "banid", ply:SteamID(), tostring(slaynr_culumativeban and slaynr_banmins*slays or slaynr_banmins), "Evading "..slays.." autoslays" )
			if !slaynr_keepslays then
				ply:RemovePData( "NRSLAY_SLAYS" )
			else
				ply:SetPData( "NRSLAY_LEAVE", true )
			end
		end

	end


end )


function ulx.givemagnum( caller, targets )

	for k, v in pairs( targets ) do
		
		if v:GetObserverTarget() then
			ULib.tsayError( caller, "Spectators cannot be given a magnum!", true ) continue
		elseif v:GetMurderer() then
			ULib.tsayError( caller, "The Murderer cannot be given a magnum!", true ) continue
		end

		v:Give( "weapon_mu_magnum" )

	end

end
local magnum = ulx.command( CATEGORY_NAME, "ulx givemagnum", ulx.givemagnum, "!givemagnum" )
magnum:addParam{ type=ULib.cmds.PlayersArg, ULib.cmds.optional }
magnum:defaultAccess( ULib.ACCESS_ADMIN )
magnum:help( "Give the target the magnum." )

function ulx.respawn( caller, targets )

	for k, v in pairs( targets ) do
		if !v:IsValid() then return end
		
		v:Spawn()

	end


end
respawn = ulx.command( CATEGORY_NAME, "ulx respawn", ulx.respawn, "!respawn" )
respawn:addParam{ type=ULib.cmds.PlayersArg, ULib.cmds.optional }
respawn:defaultAccess( ULib.ACCESS_ADMIN )
respawn:help( "Respawn the target." )