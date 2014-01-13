util.AddNetworkString( "grab_Screenshot" )
util.AddNetworkString( "grab_RequestScreenshot" )
util.AddNetworkString( "grab_SendScreenshot" )

local function grabscreen( caller, target, quality )

	if target[1]:IsBot() then ULib.tsayError( caller, "You cannot take a screenshot from a bot!" ) return end

	ulx.fancyLogAdmin( caller, false, "#A requested a screenshot from #T", target )
	timer.Simple( 0.1, function() ULib.tsay( caller, "This will take a second or two.", true ) end )

	net.Start( "grab_RequestScreenshot", target )
		net.WriteEntity( caller )
	net.Send( target[1] )

end
local grab = ulx.command( "Utility", "ulx grabscreen", grabscreen, "!grabscreen" )
grab:addParam{ type=ULib.cmds.PlayersArg }
grab:defaultAccess( ULib.ACCESS_ADMIN )
grab:help( "Grab a screenshot of the target's screen." )

net.Receive( "grab_Screenshot", function( len, ply )

	local sendto, img = net.ReadEntity(), net.ReadData( 65500 )

	net.Start( "grab_SendScreenshot" )
		net.WriteData( img, 65500 )
		net.WriteString( ply:IsValid() and ( string.len(ply:Nick()) > 25 and string.sub( ply:Nick(), 1, 25 ).."..." or ply:Nick() ) or "<disconnected>"  )
	net.Send( sendto )

end )
