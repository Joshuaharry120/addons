if SERVER then

	util.AddNetworkString( "grab_ScreenshotToServer" )
	util.AddNetworkString( "grab_ScreenshotToClient" )
	util.AddNetworkString( "grab_RequestScreenshot" )
	util.AddNetworkString( "grab_RequestStream" )

	local function grabscreen( caller, target )

		if target[1]:IsBot() then ULib.tsayError( caller, "You cannot take a screenshot from a bot!" ) return end

		ulx.fancyLogAdmin( caller, false, "#A requested a screenshot from #T", target )
		timer.Simple( 0.1, function() caller:ChatPrint( "This will take a second or two." ) end )

		net.Start( "grab_RequestScreenshot", target )
			net.WriteEntity( caller )
		net.Send( target[1] )

	end
	local grab = ulx.command( "Utility", "ulx grabscreen", grabscreen, "!grabscreen" )
	grab:addParam{ type=ULib.cmds.PlayersArg }
	grab:defaultAccess( ULib.ACCESS_ADMIN )
	grab:help( "Grab a screenshot of the target's screen." )

	net.Receive( "grab_ScreenshotToServer", function( len, ply )

		local sendto = net.ReadEntity()
		local len = net.ReadUInt( 32 )
		local img = net.ReadData( len )

		net.Start( "grab_ScreenshotToClient" )
			net.WriteUInt( len, 32 )
			net.WriteData( img, #img )
			net.WriteEntity( ply )
		net.Send( sendto )

	end )

	net.Receive( "grab_RequestStream", function( len, ply )

		local target = net.ReadEntity()
		ulx.fancyLogAdmin( ply, false, "#A started streaming #T's screen", target )

		timer.Create( "CheckRequest" .. ply:UniqueID(), 4, 0, function()

			local stream = ply:GetInfoNum( "grabscreen_stream", 0 )

			if stream == 1 then

				net.Start( "grab_RequestScreenshot" )
					net.WriteEntity( ply )
				net.Send( target )

			else

				timer.Destroy( "CheckReqest" .. ply:UniqueID() )

			end

		end )

	end )


end

if CLIENT then

	GRABSCREEN_FRAME, GRABSCREEN_HTML, GRABSCREEN_STREAM = nil, nil, nil

	CreateClientConVar( "grabscreen_stream", 0, false, true )
	cvars.AddChangeCallback( "grabscreen_stream", function( name, old, new )

		if new == "1" then

			net.Start( "grab_RequestStream" )
				net.WriteEntity( GRABSCREEN_PLY )
			net.SendToServer()

		end

	end )

	net.Receive( "grab_ScreenshotToClient", function()

		local len = net.ReadUInt( 32 )
		local img, G = net.ReadData( len )
		GRABSCREEN_PLY = net.ReadEntity()

		if not IsValid( GRABSCREEN_FRAME ) then

			RunConsoleCommand( "grabscreen_stream", 0 )

			GRABSCREEN_FRAME = vgui.Create( "DFrame" )
			GRABSCREEN_FRAME:SetTitle( "Screenshot from "..GRABSCREEN_PLY:Nick() .. " - " .. GRABSCREEN_PLY:SteamID() )
			GRABSCREEN_FRAME:SetSize( ScrW(), ScrH() )
			GRABSCREEN_FRAME:SetDraggable( false )
			GRABSCREEN_FRAME:Center()

			GRABSCREEN_HTML = GRABSCREEN_FRAME:Add( "HTML" )
			GRABSCREEN_HTML:SetHTML([[
				<style type="text/css">
					body {
						margin: 0;
						padding: 0;
						overflow: hidden;
					}
					img {
						width: 100%;
						height: 100%;
					}
				</style>
				<img src="data:image/jpg;base64,]] .. util.Decompress( img ) .. [[">]]
			)
			GRABSCREEN_HTML:Dock( FILL )
			GRABSCREEN_HTML:SetMouseInputEnabled( false )

			GRABSCREEN_STREAM = GRABSCREEN_FRAME:Add( "DCheckBox" )
			GRABSCREEN_STREAM:SetPos( GRABSCREEN_FRAME:GetWide() -150, 5 )
			GRABSCREEN_STREAM:SetConVar( "grabscreen_stream" )

			GRABSCREEN_FRAME:MakePopup()

			GRABSCREEN_FRAME.OnClose = function()

				RunConsoleCommand( "grabscreen_stream", 0 )

			end

		else

			GRABSCREEN_HTML:SetHTML([[
				<style type="text/css">
					body {
						margin: 0;
						padding: 0;
						overflow: hidden;
					}
					img {
						width: 100%;
						height: 100%;
					}
				</style>
				<img src="data:image/jpg;base64,]] .. util.Decompress( img ) .. [[">]]
			)

		end

	end )

	net.Receive( "grab_RequestScreenshot", function()

		local sendto = net.ReadEntity()

		local scr = {}
		scr.format = "jpeg"
		scr.h = ScrH()
		scr.w = ScrW()
		scr.quality = 40
		scr.x = 0
		scr.y = 0

		local img = util.Base64Encode( render.Capture( scr ) )
		img = util.Compress( img )
		net.Start( "grab_ScreenshotToServer" )
			net.WriteEntity( sendto )
			net.WriteUInt( #img, 32 )
			net.WriteData( img, #img )
		net.SendToServer()

	end )

end
