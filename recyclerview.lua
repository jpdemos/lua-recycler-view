-- This is the Lua definition of a lua recycler view. Can only be used within the Garry's Mod game.

-- In the game, the default list view GUI doesn't limit how many rows can be added, thus making the game slow when you reach 200 or more rows.

-- This recycler view works by re-using rows & columns once they get out of the panel's viewport (i.e. when you scroll).
-- It allows to have as many rows and columns as your RAM can support, because there is only a few rows rendered.

-- Last test proved I could have more than 1 000 000 rows without any slow down.

local PANEL = {}

local BaseLabelLoadFunction = function( panel, text ) -- Default panel template loading function
	
	panel:SetTextColor( panel:GetSkin().Colours.Label.Dark )
	panel:SetContentAlignment( 4 )
	panel:SetText( tostring( text or "" ) )
	panel:SetTextInset( 3, 1 )
	panel:SetFont( "DebugFixed" )
	
end

-- Columns accessors
AccessorFunc( PANEL, "m_iColumnWidth", "BaseColumnWidth" )
AccessorFunc( PANEL, "m_bColumnsShown", "ShowColumns" )

-- Rows accessors
AccessorFunc( PANEL, "m_iRowHeight", "BaseRowHeight" )

-- ListView accessors
AccessorFunc( PANEL, "m_bCanLoad", "CanLoad" )

Derma_Hook( PANEL, "Paint", "Paint", "ListBox" )

function PANEL:Init()
	
	-- Persistant data through layouts
	self.Rows	 = {}
	self.Columns = {}
	
	self.ContainerSize = { w = 0, h = 0 } -- OnSizeChanged pls

	-- Data that can be reset through layouts.
	self.Cache = {
		VerticalData = {
			StartIndex		= 1,
			Scroll			= 0,
			ScrollOffset	= 0,
			Padding			= 0,
			Count			= 0,
			TotalSize		= 0,
			Panels			= {}
		},
		HorizontalData = {
			StartIndex		= 1,
			Scroll			= 0,
			ScrollOffset	= 0,
			Padding			= 0,
			Count			= 0,
			TotalSize		= 0,
			Panels			= {}
		}
	}
	
	-- Scroll canvas
	self.ScrollCanvas = self:Add( "DScrollableCanvas" ) -- DScrollableCanvas represents a simple panel that can be scrolled horizontally and vertically.
	self.ScrollCanvas:Dock( FILL )
	
	-- We have to do this to properly add the ColumnsHeaderContainer on the scrollcanvas.
	self.ScrollCanvas.AddItem		= nil
	self.ScrollCanvas.OnChildAdded	= nil
	
	-- Columns Container (where you put the columns header)
	self.ColumnsHeaderContainer = self.ScrollCanvas:Add( "EditablePanel" )
	self.ColumnsHeaderContainer:Dock( TOP )
	self.ColumnsHeaderContainer:DockMargin( 0, 0, 0, 0 )
	self.ColumnsHeaderContainer:SetTall( 18 )
	self.ColumnsHeaderContainer:SetVisible( false ) -- self:AddColumn( sName ) to set visible
	self.ColumnsHeaderContainer.m_bPanelsNeedReload = false
	
	self.ColumnsHeaderContainer.OnChildAdded = function( container, panel )
		panel:Dock( LEFT )
	end
	
	self.ColumnsHeaderContainer.PerformLayout = nil
	
	self.ColumnsHeaderContainer.AddPanel = function( container )
		
		local panel = container:Add( "RecyclerView_ColumnHeader" ) -- TODO: Accessor?
		panel:SetListView( self )
		
		return panel
		
	end
	
	self.ColumnsHeaderContainer.GetSpace = function( container ) return container:GetWide() end
	
	self.ScrollCanvas.AddItem		= DScrollPanel.AddItem
	self.ScrollCanvas.OnChildAdded	= DScrollPanel.OnChildAdded
	
	
	-- Lines container (where you put rows)
	self.LinesContainer = self.ScrollCanvas:GetCanvas()
	self.LinesContainer:Dock( FILL )
	self.LinesContainer:DockMargin( 1, 0, 0, 0 )
	self.LinesContainer.m_bPanelsNeedReload = false
	
	self.LinesContainer.OnChildAdded = function( container, panel )
		panel:Dock( TOP )
	end
	
	self.LinesContainer.PerformLayout = nil -- Important. Prevents SizeToChildren, which calls InvalidateLayout
	
	self.LinesContainer.AddPanel = function( container )
		
		local panel = container:Add( "RecyclerView_Row" ) -- TODO: Accessor?
		panel:SetListView( self )
		
		return panel
		
	end
	
	self.LinesContainer.GetSpace = function( container ) return container:GetTall() end
	
	
	self.ScrollCanvas.GetCanvasHeight = function()
		return self.Cache.VerticalData.TotalSize
	end
	
	self.ScrollCanvas.GetCanvasWidth = function()
		return self.Cache.HorizontalData.TotalSize
	end
	
	self.ScrollCanvas.GetContainerHeight = function() return self.LinesContainer:GetTall() end
	self.ScrollCanvas.GetContainerWidth = function() return self.ColumnsHeaderContainer:GetWide() end
	
	self.ScrollCanvas.OnVScroll = function( _, offset ) self:OnVScroll( offset ) end
	self.ScrollCanvas.OnHScroll = function( _, offset ) self:OnHScroll( offset ) end
	
	self.ScrollCanvas.PerformLayout = function( container, w, h ) -- No OnSizeChanged ... :(
		
		DScrollableCanvas.PerformLayout( container, w, h )
		
		if self.ContainerSize.w != w or self.ContainerSize.h != h then
		
			local oldWidth, oldHeight = self.ContainerSize.w, self.ContainerSize.h
			
			self.ContainerSize.w = w
			self.ContainerSize.h = h
			
			self.ScrollCanvas:InvalidateChildren() -- Prevents "Adding child in layout!" error.
			self:Load() -- Should I place this here?
			
			self:OnContainerSizeChanged( w - oldWidth, h - oldHeight )
			
		end
		
	end
	
	self.ContainerSize.w, self.ContainerSize.h = self.ScrollCanvas:GetSize()
	
	self.m_iRowHeight	 = 17 -- Arbitrary value. Panels seems to init with this height.
	self.m_iColumnWidth	 = 2^7
	self.m_bColumnsShown = true
	self.m_bCanLoad		 = false
	
end

function PANEL:Load()
	
	self.m_bCanLoad = true
	self.ColumnsHeaderContainer:SetVisible( self.m_bColumnsShown )
	self.ScrollCanvas:InvalidateChildren() -- Needed to update the containers size
	
end

function PANEL:PerformLayout( w, h )
	
	if not self.m_bCanLoad then return end
	
	-- Not done in seperate functions so we don't slow down as this is done every layout.
	-- Columns layout
	if #self.Columns > 0 then
		
		if self.ColumnsHeaderContainer:IsVisible() != self.m_bColumnsShown then
			self.ColumnsHeaderContainer:SetVisible( self.m_bColumnsShown )
		end
		
		if self.Cache.HorizontalData.TotalSize < self.ColumnsHeaderContainer:GetWide() then
			
			self:UpdateItemDataSize( self.Cache.HorizontalData, self.Columns, #self.Columns, self.ColumnsHeaderContainer:GetWide() - ( self.Cache.HorizontalData.TotalSize - self.Columns[ #self.Columns ].Size ) )
			self.ColumnsHeaderContainer.m_bPanelsNeedReload = true
			
		end
		
		if self:UpdateStartItemIndex( self.ColumnsHeaderContainer, self.Cache.HorizontalData, self.Columns ) or self.ColumnsHeaderContainer.m_bPanelsNeedReload then -- Only update if needed
			
			self.LinesContainer.m_bPanelsNeedReload = true -- If you need to change the columns, you need to change the rows' columns too. TODO: find better way than doing this?
			self:UpdatePanelList( self.ColumnsHeaderContainer, self.Cache.HorizontalData, self.Columns )
			
		end
		
	end
	
	
	-- Rows layout
	if #self.Rows > 0 then
		
		if self:UpdateStartItemIndex( self.LinesContainer, self.Cache.VerticalData, self.Rows ) or self.LinesContainer.m_bPanelsNeedReload then -- Only update if needed
			
			self:UpdatePanelList( self.LinesContainer, self.Cache.VerticalData, self.Rows )
			self:KillFocus() -- Remove focus from cells. Useful for custom panels in columns, like DTextEntry.
			
		end
		
	end
	
	
	-- Updating containers padding
	-- Columns container left padding
	self.ColumnsHeaderContainer:DockPadding( -self.Cache.HorizontalData.Padding, 0, 0, 0 )
	
	-- Rows container left, top and right paddings
	self.LinesContainer:DockPadding( 
		-self.Cache.HorizontalData.Padding,
		-self.Cache.VerticalData.Padding,
		self.LinesContainer:GetWide() - self.Cache.HorizontalData.TotalSize + self.Cache.HorizontalData.Scroll,
		0 )
	
	self.ColumnsHeaderContainer.m_bPanelsNeedReload	= false
	self.LinesContainer.m_bPanelsNeedReload			= false
	
	self.ScrollCanvas:InvalidateChildren()
	
end

function PANEL:OnContainerSizeChanged( dw, dh )
	
	self.ColumnsHeaderContainer.m_bPanelsNeedReload	= true -- TODO: could find out which one with dw != 0 or dh != 0
	self.LinesContainer.m_bPanelsNeedReload			= true
	self:InvalidateLayout()
	
end

function PANEL:Clear()
	
	self.Rows	 = {} -- Faster than table.Empty
	self.Columns = {}
	
	for k, Panel in pairs( self.Cache.VerticalData.Panels ) do
		
		Panel:Remove()
		self.Cache.VerticalData.Panels[ k ] = nil
		
	end
	
	for k, Panel in pairs( self.Cache.HorizontalData.Panels ) do
		
		Panel:Remove()
		self.Cache.HorizontalData.Panels[ k ] = nil
		
	end
	
	self.Cache.VerticalData.StartIndex	 = 1
	self.Cache.VerticalData.Scroll		 = 0
	self.Cache.VerticalData.ScrollOffset = 0
	self.Cache.VerticalData.Padding		 = 0
	self.Cache.VerticalData.Count		 = 0
	self.Cache.VerticalData.TotalSize	 = 0
	
	self.Cache.HorizontalData.StartIndex	= 1
	self.Cache.HorizontalData.Scroll		= 0
	self.Cache.HorizontalData.ScrollOffset	= 0
	self.Cache.HorizontalData.Padding		= 0
	self.Cache.HorizontalData.Count			= 0
	self.Cache.HorizontalData.TotalSize		= 0
	
	
	self.ColumnsHeaderContainer:SetVisible( false )
	
end

-- This is where we determine what item to show, based on the scroll delta.
function PANEL:UpdateStartItemIndex( Container, Data, Items )
	
	local CurrentStartIndex	= Data.StartIndex
	local ScrollDelta		= Data.Scroll - Data.ScrollOffset
	
	ScrollDelta = ScrollDelta + Data.Padding
	
	if ScrollDelta < 0 then -- We're going up.
		
		while ScrollDelta < 0 and CurrentStartIndex > 1 and Items[ CurrentStartIndex - 1 ] do -- While we still have items upward, and havn't reached the delta
			
			ScrollDelta			= ScrollDelta + Items[ CurrentStartIndex - 1 ].Size
			CurrentStartIndex	= CurrentStartIndex - 1
			
		end
		
	else
		
		while ScrollDelta > 0 and CurrentStartIndex <= #Items and Items[ CurrentStartIndex ] and Items[ CurrentStartIndex ].Size < ScrollDelta do
			
			ScrollDelta			= ScrollDelta - Items[ CurrentStartIndex ].Size
			CurrentStartIndex	= CurrentStartIndex + 1
			
		end
		
	end
	
	local ShouldUpdate = Data.StartIndex != CurrentStartIndex
	
	Data.StartIndex		= CurrentStartIndex
	Data.Padding		= ScrollDelta
	Data.ScrollOffset	= Data.Scroll
	
	return ShouldUpdate
	
end

-- Here we update the used cells view so they show the correct data.
function PANEL:UpdatePanelList( Container, Data, Items )
	
	local ContainerSpace	= Container:GetSpace()
	local ItemIndex			= Data.StartIndex
	local PanelIndex		= 1
	local PanelsCount		= 0
	local TotalPanelSize	= 0
	
	while Items[ ItemIndex ] and TotalPanelSize <= ContainerSpace + Data.Padding + Items[ Data.StartIndex ].Size do
		
		if not Data.Panels[ PanelIndex ] then
			Data.Panels[ PanelIndex ] = Container:AddPanel()
		end
		
		Data.Panels[ PanelIndex ]:SetItemID( ItemIndex )
		Data.Panels[ PanelIndex ]:Update()
		
		TotalPanelSize	= TotalPanelSize + Items[ ItemIndex ].Size
		ItemIndex		= ItemIndex + 1
		PanelIndex		= PanelIndex + 1
		PanelsCount		= PanelsCount + 1
		
	end
	
	-- Remove the ones that arn't used ( they are not visible ).
	for i = PanelsCount + 1, #Data.Panels, 1 do
		
		Data.Panels[ i ]:Remove()
		Data.Panels[ i ] = nil
		
	end
	
	Data.Count = PanelsCount
	
end

function PANEL:UpdateItemDataSize( Data, Items, i, Size )
	
	if not Items[ i ] then return end
	
	local OldSize		= Items[ i ].Size
	local OldDataSize	= Data.TotalSize
	
	Items[ i ].Size		= Size
	Data.TotalSize		= Data.TotalSize + ( Items[ i ].Size - OldSize )
	
	return Data.TotalSize != OldDataSize
	
end


-- ROWS
function PANEL:AddRow( rowData, height, n )
	
	local i = table.insert( self.Rows, n or #self.Rows + 1, {
		Data = rowData,
		Size = height or self.m_iRowHeight
	} )
	
	self.Cache.VerticalData.TotalSize = self.Cache.VerticalData.TotalSize + self.Rows[ i ].Size
	self:InvalidateLayout()
	
	return i
	
end

function PANEL:AddColumn( colName, n, width )
	
	local i = table.insert( self.Columns, n or #self.Columns + 1, {
		Text	 = tostring( colName or "" ),
		Size	 = width or self.m_iColumnWidth,
		Type	 = "DLabel",
		LoadFunc = BaseLabelLoadFunction
	} )
	
	self.Cache.HorizontalData.TotalSize = self.Cache.HorizontalData.TotalSize + self.Columns[ i ].Size
	self:InvalidateLayout()
	
	return i
	
end

function PANEL:SetDataTable( data )
	
	self:Clear()
	
	self:SetColumnWidth( self:AddColumn( "Index" ), 35 )
	self:SetColumnWidth( self:AddColumn( "Key" ), 350 )
	self:AddColumn( "Value" )
	local i = 1
	
	for k, v in pairs( data ) do
		
		self:AddRow( { i, tostring( k ), tostring( v ) } )
		i = i + 1
		
	end
	
end

function PANEL:SetRowHeight( i, size )
	
	-- Update the data and then update the rows
	if not self:UpdateItemDataSize( self.Cache.VerticalData, self.Rows, i, size ) then return end
	
	self.LinesContainer.m_bPanelsNeedReload = true
	self:InvalidateLayout()
	
end

function PANEL:SetColumnWidth( i, size )
	
	-- Update the data and then update the corresponding panel if visible.
	local OldSize = self.Columns[ i ].Size
	
	
	
	
	if self:UpdateItemDataSize( self.Cache.HorizontalData, self.Columns, i, size ) then
		
		self.ColumnsHeaderContainer.m_bPanelsNeedReload	= true
		--self.LinesContainer.m_bPanelsNeedReload			= true -- Is this needed? let UpdateStartIndex decide? Will be set to true if columns start index has changed anyway
		
		self:InvalidateLayout( true ) -- TODO: maybe remove true
		
	end
	if self.m_bCanLoad then
	
		local PanelIndex = i - self.Cache.HorizontalData.StartIndex + 1
		
		if PanelIndex < 1 or PanelIndex > self.Cache.HorizontalData.Count then -- If the panel isn't visible, we update the scroll offset.
			self.Cache.HorizontalData.ScrollOffset = self.Cache.HorizontalData.ScrollOffset - ( OldSize - self.Columns[ i ].Size )
		end
		
	end
	
end

function PANEL:OnRowSizeChanged( i, size )			self:SetRowHeight( i, size ) end
function PANEL:OnColumnHeaderSizeChanged( i, size )	self:SetColumnWidth( i, size ) end

function PANEL:GetRowData( i )		return self.Rows[ i ].Data end
function PANEL:GetColumnData( i )	return self.Columns[ i ].Data end

function PANEL:SetRowData( i, colOrData, ... ) -- Ew
	
	if not self.Rows[ i ] then return end
	
	local data = select( 1, ... )
	
	if #data > 0 and colOrData then
		self.Rows[ i ].Data[ colOrData ] = data
	else
		self.Rows[ i ].Data = colOrData
	end
	
end

function PANEL:SetColumnPanelType( i, ClassName )
	
	if not self.Columns[ i ] then return end
	
	self.Columns[ i ].Type = ClassName or "DLabel"
	
end

function PANEL:GetColumnPanelType( i )
	return self.Columns[ i ].Type
end

function PANEL:SetColumnPanelLoadFunction( i, Func )
	
	if not self.Columns[ i ] then return end
	
	self.Columns[ i ].LoadFunc = Func or BaseLabelLoadFunction
	
end

function PANEL:GetColumnPanelLoadFunction( i )
	return self.Columns[ i ].LoadFunc
end

function PANEL:OnVScroll( offset )
	
	offset = -offset
	
	if offset == self.Cache.VerticalData.Scroll then return end
	self.Cache.VerticalData.Scroll = offset
	
	self:InvalidateLayout( true )
	
end

function PANEL:OnHScroll( offset )
	
	offset = -offset
	
	if offset == self.Cache.HorizontalData.Scroll then return end
	self.Cache.HorizontalData.Scroll = offset
	
	self:InvalidateLayout( true )
	
end

vgui.Register( "RecyclerView", PANEL, "EditablePanel" ) -- TODO: change to DBufferedListView
