--Hand Selector by Paynamia
--Totally replaces the PlayerSetHandsModel hook

--This note is for me
--So, if it's gonna force hands based on playermodel, it has to read and write on client,
--and send that to the server so it can be applied. Shouldn't be too hard.

--Menu based upon: https://github.com/Facepunch/garrysmod/blob/3095112/garrysmod/gamemodes/sandbox/gamemode/editor_player.lua
--Positions of extra buttons and such meant to emulate Enhanced PlayerModel Selector 3.0 by LibertyPrime

if CLIENT then
PayHandSel = { }

CreateConVar("cl_handselector_enable", "0", { FCVAR_ARCHIVE, FCVAR_USERINFO, FCVAR_DONTRECORD })
CreateConVar("cl_handselector_model", "models/weapons/c_arms_citizen.mdl", { FCVAR_ARCHIVE, FCVAR_USERINFO, FCVAR_DONTRECORD })
CreateConVar("cl_handselector_skin", "0", { FCVAR_ARCHIVE, FCVAR_USERINFO, FCVAR_DONTRECORD })
CreateConVar("cl_handselector_body", "0", { FCVAR_ARCHIVE, FCVAR_USERINFO, FCVAR_DONTRECORD })
local cvarDebug = CreateConVar("cl_handselector_debug", "1", { FCVAR_ARCHIVE, FCVAR_USERINFO, FCVAR_DONTRECORD })

if !file.Exists( "pay_handselector", "DATA" ) then file.CreateDir( "pay_handselector" ) end
if file.Exists( "pay_handselector/cl_hand_assignments.txt", "DATA" ) then
	if cvarDebug then print("Auto-assign file exists!") end
	PayHandSel.handassignments = util.JSONToTable( file.Read( "pay_handselector/cl_hand_assignments.txt", "DATA" ) )
	if !istable( PayHandSel.handassignments ) then
		PayHandSel.handassignments = { }
	end
	if cvarDebug then PrintTable( PayHandSel.handassignments ) end
end

list.Set( "DesktopWindows", "HandSelectorMenu", {

	title		= "Hand Selector",
	icon		= "icon64/handselector.png",
	width		= 960,
	height		= 700,
	onewindow	= true,
	init		= function( icon, window )
	
		window:SetSize( math.min( ScrW() - 16, window:GetWide() ), math.min( ScrH() - 16, window:GetTall() ) )
		window:Center()
		
		local mdl = window:Add( "DModelPanel" )
		mdl:Dock( FILL )
		mdl:SetFOV( 36 )
		mdl:SetCamPos( Vector( 0, 0, 0 ) )
		mdl:SetDirectionalLight( BOX_RIGHT, Color( 255, 160, 80, 255 ) )
		mdl:SetDirectionalLight( BOX_LEFT, Color( 80, 160, 255, 255 ) )
		mdl:SetAmbientLight( Vector( -64, -64, -64 ) )
		mdl:SetAnimated( true )
		mdl.Angles = Angle( 0, 0, 0 )
		mdl.Pos = Vector( -100, 0, -6 )
		mdl:SetLookAt( Vector( -100, 0, -22 ) )
		
		local applybutton = window:Add( "DButton" )
		applybutton:SetText( "Apply" )
		applybutton:SetPos( window:GetWide() - 540, 30 )
		applybutton:SetSize( 100, 30 )
		applybutton.DoClick = function()
			net.Start("handselector_update")
			net.SendToServer()
			if PayHandSel.handassignments[LocalPlayer():GetModel()] then
				net.Start("handselector_autotable")
				net.WriteTable(PayHandSel.handassignments[LocalPlayer():GetModel()])
				net.SendToServer()
			end
		end
		
		local sheet = window:Add( "DPropertySheet" )
		sheet:Dock( RIGHT )
		sheet:SetSize( 430, 0 )
		
		local modelsheet = sheet:Add( "DPropertySheet" )
		sheet:AddSheet( "Model", modelsheet, "icon16/user.png" )
		
		local PanelBrowser = modelsheet:Add( "DFileBrowser" )
		
		PanelBrowser:SetPath( "GAME" )
		PanelBrowser:SetBaseFolder( "models" )
		PanelBrowser:SetFileTypes( "*.mdl" )
		PanelBrowser:SetModels( true )
		PanelBrowser:SetOpen( true )
		PanelBrowser:SetCurrentFolder( "weapons" )
		
		function PanelBrowser:OnSelect( path, pnl )
			RunConsoleCommand( "cl_handselector_model", path )
			RunConsoleCommand( "cl_handselector_body", "0" )
			RunConsoleCommand( "cl_handselector_skin", "0" )
			timer.Simple( 0.1, function() window.UpdateFromConvars() end )
		end
		
		local PanelSelect = modelsheet:Add( "DPanelSelect" )

		for name, model in SortedPairs( list.Get( "PayHandList" ) ) do

			local icon = vgui.Create( "SpawnIcon" )
			icon:SetModel( model )
			icon:SetSize( 64, 64 )
			icon:SetTooltip( name )

			PanelSelect:AddPanel( icon )
			icon.DoClick = function()
				RunConsoleCommand( "cl_handselector_model", model )
				RunConsoleCommand( "cl_handselector_body", "0" )
				RunConsoleCommand( "cl_handselector_skin", "0" )
				timer.Simple( 0.1, function() window.UpdateFromConvars() end )
			end

		end

		modelsheet:AddSheet( "List", PanelSelect, "icon16/user.png" )
		
		modelsheet:AddSheet( "Browser", PanelBrowser, "icon16/user.png" )
		
		local bdcontrols = window:Add( "DPanel" )
		bdcontrols:DockPadding( 8, 8, 8, 8 )

		local bdcontrolspanel = bdcontrols:Add( "DPanelList" )
		bdcontrolspanel:EnableVerticalScrollbar( true )
		bdcontrolspanel:Dock( FILL )

		local bgtab = sheet:AddSheet( "Bodygroups", bdcontrols, "icon16/cog.png" )
		
		local autoassignmenu = window:Add( "DPanel" )
		autoassignmenu:DockPadding( 8, 8, 8, 8 )
		
		local autoassignlist = autoassignmenu:Add( "DListView" )
		autoassignlist:Dock( FILL )
		autoassignlist:SetMultiSelect( false )
		autoassignlist:AddColumn( "Model" )
		autoassignlist:AddColumn( "Skin" ):SetMaxWidth(25)
		autoassignlist:AddColumn( "Bodygroups" )
		autoassignlist:AddColumn( "Hands" )
		autoassignlist:AddColumn( "Hand Skin" ):SetMaxWidth(25)
		autoassignlist:AddColumn( "Hand Bodygroups" )
		
		local autoassigncont = autoassignmenu:Add( "DPanel" )
		autoassigncont:Dock( BOTTOM )
		autoassigncont:SetSize( 0, 30 )
		
		--This was just an unfortunate shortening.
		--I chose to leave it.
		local autoassadd = autoassigncont:Add( "DButton" )
		autoassadd:SetText( "Add New Assignment" )
		autoassadd:SetPos( 0, 8 )
		autoassadd:SetSize( 194, 20 )
		autoassadd.DoClick = function()
			PayHandSel.handassignments[LocalPlayer():GetModel()] = { }
			PayHandSel.handassignments[LocalPlayer():GetModel()].Body = LocalPlayer():GetInfo( "cl_playerbodygroups" )
			PayHandSel.handassignments[LocalPlayer():GetModel()].Skin = LocalPlayer():GetInfoNum( "cl_playerskin", 0 )
			PayHandSel.handassignments[LocalPlayer():GetModel()].hModel = LocalPlayer():GetInfo( "cl_handselector_model" )
			PayHandSel.handassignments[LocalPlayer():GetModel()].hBody = LocalPlayer():GetInfo( "cl_handselector_body" )
			PayHandSel.handassignments[LocalPlayer():GetModel()].hSkin = LocalPlayer():GetInfoNum( "cl_handselector_skin", 0 )
			file.Write( "pay_handselector/cl_hand_assignments.txt", util.TableToJSON( PayHandSel.handassignments, false ) )
			timer.Simple( 0.1, function() window.UpdateFromConvars() end )
		end
		
		local autoassdel = autoassigncont:Add( "DButton" )
		autoassdel:SetText( "Remove Selected Assignment" )
		autoassdel:SetPos( 204, 8 )
		autoassdel:SetSize( 194, 20 )
		autoassdel.DoClick = function()
			-- Testing new functions
			local pmtable = { LocalPlayer():GetModel(), LocalPlayer():GetInfo( "cl_playerbodygroups" ), LocalPlayer():GetInfoNum( "cl_playerskin", 0 ) }
			print( table.concat( pmtable ) )
			print( util.CRC( table.concat( pmtable ) ) )
			return
		end
		
		sheet:AddSheet( "Auto-Assign", autoassignmenu, "icon16/cog.png" )
		
		local settingsmenu = window:Add( "DPanel" )
		settingsmenu:DockPadding( 8, 8, 8, 8 )
		
		local settingssheet = settingsmenu:Add( "DPropertySheet" )
		settingssheet:Dock( FILL )
		
		local settingsserver = window:Add( "DPanel" )
		settingsserver:DockPadding( 8, 8, 8, 8 )
		
		local svenabledcheckbox = settingsserver:Add( "DCheckBoxLabel" )
		svenabledcheckbox:SetPos( 10, 10 )
		svenabledcheckbox:SetText( "Enable Hand Selector" )
		svenabledcheckbox:SetTextColor( Color( 0, 0, 0 ) )
		svenabledcheckbox:SetConVar( "sv_handselector_enable" )
		
		local settingsclient = window:Add( "DPanel" )
		settingsclient:DockPadding( 8, 8, 8, 8 )
		
		local clenabledcheckbox = settingsclient:Add( "DCheckBoxLabel" )
		clenabledcheckbox:SetPos( 10, 10 )
		clenabledcheckbox:SetText( "Enable Hand Selector" )
		clenabledcheckbox:SetTextColor( Color( 0, 0, 0 ) )
		clenabledcheckbox:SetConVar( "cl_handselector_enable" )
		--clenabledcheckbox:SizeToContents()
		
		settingssheet:AddSheet( "Server", settingsserver, "icon16/cog.png" )
		settingssheet:AddSheet( "Client", settingsclient, "icon16/cog.png" )
		
		sheet:AddSheet( "Settings", settingsmenu, "icon16/cog.png" )
		
		-- Helper functions

		local function MakeNiceName( str )
			local newname = {}

			for _, s in pairs( string.Explode( "_", str ) ) do
				if ( string.len( s ) == 1 ) then table.insert( newname, string.upper( s ) ) continue end
				table.insert( newname, string.upper( string.Left( s, 1 ) ) .. string.Right( s, string.len( s ) - 1 ) ) -- Ugly way to capitalize first letters.
			end

			return string.Implode( " ", newname )
		end

		-- Updating
		local function UpdateBodyGroups( pnl, val )
			if ( pnl.type == "bgroup" ) then

				mdl.Entity:SetBodygroup( pnl.typenum, math.Round( val ) )

				local str = string.Explode( " ", GetConVarString( "cl_handselector_body" ) )
				if ( #str < pnl.typenum + 1 ) then for i = 1, pnl.typenum + 1 do str[ i ] = str[ i ] or 0 end end
				str[ pnl.typenum + 1 ] = math.Round( val )
				RunConsoleCommand( "cl_handselector_body", table.concat( str, " " ) )

			elseif ( pnl.type == "skin" ) then

				mdl.Entity:SetSkin( math.Round( val ) )
				RunConsoleCommand( "cl_handselector_skin", math.Round( val ) )

			end
		end

		local function RebuildBodygroupTab()
			bdcontrolspanel:Clear()

			bgtab.Tab:SetVisible( false )

			local nskins = mdl.Entity:SkinCount() - 1
			if ( nskins > 0 ) then
				local skins = vgui.Create( "DNumSlider" )
				skins:Dock( TOP )
				skins:SetText( "Skin" )
				skins:SetDark( true )
				skins:SetTall( 50 )
				skins:SetDecimals( 0 )
				skins:SetMax( nskins )
				skins:SetValue( GetConVarNumber( "cl_handselector_skin" ) )
				skins.type = "skin"
				skins.OnValueChanged = UpdateBodyGroups

				bdcontrolspanel:AddItem( skins )

				mdl.Entity:SetSkin( GetConVarNumber( "cl_handselector_skin" ) )

				bgtab.Tab:SetVisible( true )
			end

			local groups = string.Explode( " ", GetConVarString( "cl_handselector_body" ) )
			for k = 0, mdl.Entity:GetNumBodyGroups() - 1 do
				if ( mdl.Entity:GetBodygroupCount( k ) <= 1 ) then continue end

				local bgroup = vgui.Create( "DNumSlider" )
				bgroup:Dock( TOP )
				bgroup:SetText( MakeNiceName( mdl.Entity:GetBodygroupName( k ) ) )
				bgroup:SetDark( true )
				bgroup:SetTall( 50 )
				bgroup:SetDecimals( 0 )
				bgroup.type = "bgroup"
				bgroup.typenum = k
				bgroup:SetMax( mdl.Entity:GetBodygroupCount( k ) - 1 )
				bgroup:SetValue( groups[ k + 1 ] or 0 )
				bgroup.OnValueChanged = UpdateBodyGroups

				bdcontrolspanel:AddItem( bgroup )

				mdl.Entity:SetBodygroup( k, groups[ k + 1 ] or 0 )

				bgtab.Tab:SetVisible( true )
			end
		end
		
		local function RebuildAutoAssignTab()
			autoassignlist:Clear()
			for k, v in pairs( PayHandSel.handassignments ) do
				autoassignlist:AddLine( k, v.Skin, v.Body, v.hModel, v.hSkin, v.hBody )
			end
			autoassignlist:SortByColumn(1)
		end

		function window.UpdateFromConvars()

			local model = LocalPlayer():GetInfo( "cl_handselector_model" )
			util.PrecacheModel( model )
			mdl:SetModel( model )
			mdl.Entity.GetPlayerColor = function() return Vector( GetConVarString( "cl_playercolor" ) ) end
			mdl.Entity:SetPos( Vector( -100, 0, -6 ) )
			
			mdl.Entity:ResetSequence( mdl.Entity:LookupSequence( "fists_idle_01" ) )

			RebuildBodygroupTab()
			RebuildAutoAssignTab()

		end
		
		window.UpdateFromConvars()

		-- Hold to rotate

		function mdl:DragMousePress( mousebutton )
			self.PressX, self.PressY = gui.MousePos()
			self.Pressed = mousebutton
		end

		function mdl:DragMouseRelease() self.Pressed = false end

		function mdl:LayoutEntity( ent )
			if ( self.bAnimated ) then self:RunAnimation() end

			if ( self.Pressed == MOUSE_LEFT ) then
				local mx, my = gui.MousePos()
				self.Angles = self.Angles - Angle( 0, ( self.PressX or mx ) - mx, 0 )

				self.PressX, self.PressY = gui.MousePos()
			end
			-- I wouldn't include this, but some models don't center properly.
			-- There are so many weird compiles out there.
			if ( self.Pressed == MOUSE_MIDDLE ) then
				local mx, my = gui.MousePos()
				self.Pos = self.Pos - Vector( 0, 0, ( self.PressY*-(0.3) or my*-(0.3) ) - my*-(0.3) )
				
				self.PressX, self.PressY = gui.MousePos()
			end

			ent:SetAngles( self.Angles )
			ent:SetPos( self.Pos )
		end
		
	end
} )

end

if SERVER then

local cvarSVEnabled = CreateConVar("sv_handselector_enable", "1", { FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_DONTRECORD, FCVAR_SERVER_CAN_EXECUTE })

util.AddNetworkString("handselector_update")
util.AddNetworkString("handselector_autotable")

net.Receive( "handselector_update", function ( len, pl )
	pl:SetupHands()
end )

local function SetHands( pl, ent )
	
	local cvarCLEnabled = tobool( pl:GetInfo( "cl_handselector_enable" ) )
	local cvarDebug = tobool( pl:GetInfo( "cl_handselector_debug" ) )
	if cvarDebug then print("PHS: Hand Selector enabled SV:", cvarSVEnabled:GetBool()) end
	if cvarDebug then print("PHS: Hand Selector enabled CL:", cvarCLEnabled) end
	if ( cvarSVEnabled:GetBool() ~= true || cvarCLEnabled ~= true ) then return end
	
	local playermodel = player_manager.TranslateToPlayerModelName( pl:GetModel() )
	local backup = player_manager.TranslatePlayerHands( playermodel )
	--print( pl:GetInfoNum( "cl_handselector_enable", 1 ) )
	
	net.Receive( "handselector_autotable", function ( len, pl )
		PrintTable( net.ReadTable() )
	end )
	
	local info = { }
	info.model	= pl:GetInfo( "cl_handselector_model" ) or backup.model
	info.skin	= pl:GetInfoNum( "cl_handselector_skin", 0 ) or backup.skin
	info.body	= string.Replace( pl:GetInfo( "cl_handselector_body", 0 ), " ", "" ) or backup.body

	
	if cvarDebug then PrintTable( info ) end
	

	if ( info ) then
		ent:SetModel( info.model )
		ent:SetSkin( info.skin )
		ent:SetBodyGroups( info.body )
	end
	
	if cvarDebug then print("PHS: Hands set to", info.model) end
	return false
end

hook.Add( "PlayerSetHandsModel", "ForceCustomHands", SetHands )

end

list.Set( "PayHandList",	"citizen",	"models/weapons/c_arms_citizen.mdl" )
list.Set( "PayHandList",	"combine",	"models/weapons/c_arms_combine.mdl" )
list.Set( "PayHandList",	"chell",	"models/weapons/c_arms_chell.mdl" )
list.Set( "PayHandList",	"hev",		"models/weapons/c_arms_hev.mdl" )
list.Set( "PayHandList",	"refugee",	"models/weapons/c_arms_refugee.mdl" )
list.Set( "PayHandList",	"cstrike",	"models/weapons/c_arms_cstrike.mdl" )
list.Set( "PayHandList",	"dod",		"models/weapons/c_arms_dod.mdl" )

local function BuildHandList()
	for name, model in SortedPairs( player_manager.AllValidModels() ) do
		local hands = player_manager.TranslatePlayerHands( name )
		if !list.Contains( "PayHandList", hands.model ) then
			list.Set( "PayHandList", name, hands.model )
		end
	end
end
-- This needs to be called after all workshop items are loaded.
-- This hook seems good.
hook.Add( "PostGamemodeLoaded", "BuildHandList", BuildHandList )
