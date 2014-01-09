-- The default quality of the screenshot, used if the user does not specify the quality
-- The higher the better, but also the longer it will take to send
-- You are not allowed to use values greater than 50
local grab_Quality = 40 -- (0.1-50)

net.Receive( "grab_SendScreenshot", function()

	local img = net.ReadString()

	local frame = vgui.Create( "DFrame" )
	frame:SetTitle( "Screenshot from ".. ( net.ReadEntity():Nick() or "<disconnected>" ) )
	frame:SetSize( ScrW(), ScrH() )
	frame:SetDraggable( false )
	frame:Center()

	local panel = frame:Add( "HTML" )
	panel:SetHTML([[
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
		<img src="data:image/jpg;base64,]] .. img .. [[">]])
	panel:Dock( FILL )

	frame:MakePopup()

end )

net.Receive( "grab_RequestScreenshot", function()

	local sendto, quality = net.ReadEntity(), net.ReadInt( 16 )

	local scr = {}
	scr.format = "jpeg"
	scr.h = ScrH()
	scr.w = ScrW()
	scr.quality = quality or math.Clamp( grab_Quality, 0.1, 50 )
	scr.x = 0
	scr.y = 0

	local img = render.Capture( scr )

	net.Start( "grab_Screenshot" )
		net.WriteEntity( sendto )
		net.WriteString( util.Base64Encode( img ) )
	net.SendToServer()

end )