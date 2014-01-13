net.Receive( "grab_SendScreenshot", function()

	local img, ply = net.ReadData( 65500 ), net.ReadString()

	local frame = vgui.Create( "DFrame" )
	frame:SetTitle( "Screenshot from "..ply )
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
		<img src="data:image/jpg;base64,]] .. util.Base64Encode( img ) .. [[">]])
	panel:Dock( FILL )
	panel:SetMouseInputEnabled( false )

	save = frame:Add( "DButton" )
	save:SetImage( "icon16/drive_add.png" )
	save:SetText( "   Save Image" )
	save:SetSize( 100, 25 )
	save:SetPos( ( frame:GetWide()/2 ) -( save:GetWide()/2 ), frame:GetTall() -35  )
	save.Paint = function( p, w, h )
		draw.RoundedBox( 8, 0, 0, w, h, Color( 0, 0, 0, 150 ) )
	end
	save.DoClick = function()
		file.Write( "Screengrab.txt", img )
		save:Remove()
		LocalPlayer():ChatPrint( "A file named 'Screenshot.txt' has been created in the GarrysMod/garrysmod/data folder. If you rename it to 'Screenshot.jpg' you can open it as an image." )
	end

	frame:MakePopup()

end )

net.Receive( "grab_RequestScreenshot", function()

	local sendto, quality = net.ReadEntity(), net.ReadInt( 16 )

	local scr = {}
	scr.format = "jpeg"
	scr.h = ScrH()
	scr.w = ScrW()
	scr.quality = 30
	scr.x = 0
	scr.y = 0

	local img = render.Capture( scr )

	net.Start( "grab_Screenshot" )
		net.WriteEntity( sendto )
		net.WriteData( img, 65500 )
	net.SendToServer()

end )
