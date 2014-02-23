--[[			CONFIG 				]]--
CATEGORY_NAME = "Murder"
// The name that the commands will be placed under
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

--------------- Don't edit anything below this line -------------------
---------------- Unless you know what you're doing --------------------

if SERVER then
	hook.Remove( "OnStartRound", "RoundStartEvents" )
	hook.Remove( "PlayerInitialSpawn", "PreventReconnectingMurderer" )
	hook.Remove( "PlayerDisconnected", "BanThemSlayEvaders" )
	hook.Remove( "OnEndRound", "NotifyMapChange" )
end

function ulx.slaynr( caller, targets, rounds, unset )

	for k, v in pairs( targets ) do
		
		if not unset then
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

function ulx.givemagnum( caller, targets )

	for k, v in pairs( targets ) do
		
		if v:GetObserverTarget() then
			ULib.tsayError( caller, "Spectators cannot be given a magnum!", true ) continue
		elseif v:GetMurderer() then
			ULib.tsayError( caller, "The Murderer cannot be given a magnum!", true ) continue
		end

		v:Give( "weapon_mu_magnum" )
		ulx.fancyLogAdmin( caller, false, "#A gave #T a magnum", targets )

	end

end
local magnum = ulx.command( CATEGORY_NAME, "ulx givemagnum", ulx.givemagnum, "!givemagnum" )
magnum:addParam{ type=ULib.cmds.PlayersArg, ULib.cmds.optional }
magnum:defaultAccess( ULib.ACCESS_ADMIN )
magnum:help( "Give the target the magnum." )

function ulx.respawn( caller, targets )

	for k, v in pairs( targets ) do

		if v:Team() ~= 2 then ULib.tsayError( caller, "You cannot respawn a spectator!" ) return end

		v:Spectate( OBS_MODE_NONE )
		v:Spawn()

	end

	ulx.fancyLogAdmin( caller, false, "#A respawned #T", targets )

end
local respawn = ulx.command( CATEGORY_NAME, "ulx respawn", ulx.respawn, "!respawn" )
respawn:addParam{ type=ULib.cmds.PlayersArg }
respawn:defaultAccess( ULib.ACCESS_ADMIN )
respawn:help( "Respawn the target." )

if SERVER then
	mapnr_changemap = false
	mapnr_map = nil
end
function ulx.mapnr( caller, map, unset )

	if !table.HasValue( ulx.maps, map ) and not unset then
		ULib.tsayError( caller, "Invalid map \""..map.."\" specified!" )
		return
	end

	if !mapnr_changemap and unset then
		ULib.tsayError( caller, "There is no map change active!" )
		return
	end

	if not unset then
		str = "#A set the map to be changed to #s next round!"
		mapnr_changemap = true
		mapnr_map = map
	else
		str = "#A removed the map change to #s next round!"
		mapnr_changemap = false
	end

	ulx.fancyLogAdmin( caller, false, str, mapnr_map )

end
local mapnr = ulx.command( CATEGORY_NAME, "ulx mapnr", ulx.mapnr, "!mapnr" )
mapnr:addParam{ type=ULib.cmds.StringArg, completes=ulx.maps, hint="map", ULib.cmds.optional }
mapnr:addParam{ type=ULib.cmds.BoolArg, invisible=true }
mapnr:defaultAccess( ULib.ACCESS_ADMIN )
mapnr:help( "Changes the map at the beggining of the next round." )
mapnr:setOpposite( "ulx unmapnr", { _, _, true }, "!unmapnr" )

function ulx.forcemurderer( caller, targets )

	if #targets > 1 then ULib.tsayError( caller, "Multiple targets specified!" ) return end
	GAMEMODE.ForceNextMurderer = target
	ulx.fancyLogAdmin( caller, true, "#A set #T to be the Murderer next round!", target )

end
local forcemu = ulx.command( CATEGORY_NAME, "ulx forcemurderer", ulx.forcemurderer, "!forcemurderer" )
forcemu:addParam{ type=ULib.cmds.PlayersArg }
forcemu:defaultAccess( ULib.ACCESS_ADMIN )
forcemu:help( "Force the target to be the murderer next round." )

/////			Hooks 			/////


if SERVER then

	hook.Add( "OnStartRound", "RoundStartEvents", function()

		if mapnr_changemap then
			mapnr_changemap = false
			game.ConsoleCommand( "changelevel "..mapnr_map.."\n" )
		end

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
						ULib.tsay( v, "You have been autoslain after leaving with active autoslays" )
						v:RemovePData( "NRSLAY_LEAVE")
					end

				end

			end

		end )

	end )

	hook.Add( "OnEndRound", "NotifyMapChange", function()
		
		if mapnr_changemap then
			ulx.fancyLogAdmin( nil, false, "The map will change to #s next round!", mapnr_map )
		end

	end )

	hook.Add( "PlayerInitialSpawn", "PreventReconnectingMurderer", function( ply )

		slays = tonumber( ply:GetPData( "NRSLAY_SLAYS" ) ) or 0
		if slays > 0 then
			ply.MurdererChance = 0
		end

	end )

	hook.Add( "PlayerDisconnected", "BanThemSlayEvaders", function( ply )

		if slaynr_ban then

			slays = tonumber( ply:GetPData( "NRSLAY_SLAYS" ) ) or 0

			if slays > 0 then
				local reason, mins = "Attempting to evade "..slays.." autoslays.", ( slaynr_culumativeban and slays*slaynr_banmins or slaynr_banmins )
				ULib.kickban( ply, mins, reason )
				ulx.fancyLogAdmin( nil, false, "Automatically banned #T for #i minutes (#s) ", ply, mins, reason )
				if !slaynr_keepslays then
					ply:RemovePData( "NRSLAY_SLAYS" )
				else
					ply:SetPData( "NRSLAY_LEAVE", true )
				end

			end

		end


	end )

end