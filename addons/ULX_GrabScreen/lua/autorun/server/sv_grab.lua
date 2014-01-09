-- Allow people using the command to specify their own quality
-- They will still be unable to use values greater than 50
local grab_AllowSpecify = true


util.AddNetworkString( "grab_Screenshot" )
util.AddNetworkString( "grab_RequestScreenshot" )
util.AddNetworkString( "grab_SendScreenshot" )

local function grabscreen( caller, target, quality )

	if target[1]:IsBot() then ULib.tsayError( caller, "You cannot take a screenshot from a bot!" ) return end
	if !grab_AllowSpecify and quality ~= 0 then ULib.tsayError( caller, "You are not allowed to specify the quality of screenshots!" ) return end

	ulx.fancyLogAdmin( caller, false, "#A requested a screenshot from #T", target )
	timer.Simple( 0.1, function() ULib.tsay( caller, "This will take a second or two.", true ) end )

	net.Start( "grab_RequestScreenshot", target )
		net.WriteEntity( caller )
		if quality then net.WriteInt( math.Clamp( quality, 0.1, 50 ), 16 ) end
	net.Send( target[1] )

end
local grab = ulx.command( "Utility", "ulx grabscreen", grabscreen, "!grabscreen" )
grab:addParam{ type=ULib.cmds.PlayersArg }
grab:addParam{ type=ULib.cmds.NumArg, hint="quality of screenshot, higher the better", ULib.cmds.optional, min=0, max=50 }
grab:defaultAccess( ULib.ACCESS_ADMIN )
grab:help( "Grab a screenshot of the target's screen." )

net.Receive( "grab_Screenshot", function( len, ply )

	local sendto, img = net.ReadEntity(), net.ReadString()

	net.Start( "grab_SendScreenshot" )
		net.WriteString( img )
		net.WriteEntity( ply )
	net.Send( sendto )

end )