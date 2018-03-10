local PANEL = {}

AccessorFunc( PANEL, "m_iItem", "ItemID" )
AccessorFunc( PANEL, "m_pListView", "ListView" )
AccessorFunc( PANEL, "m_bIsSizing", "IsSizing" )

function PANEL:Init()
	
	self:SetText( "" )
	
	self.m_iItem = 0
	self.Width = 0
	self.Sizing = {
		MouseStart	= 0,
		BaseWidth	= self:GetWide(),
		ItemID		= 0
	}
	
	-- SizeBar
	self.SizeBar = self:Add( "Panel" )
	self.SizeBar:Dock( RIGHT )
	self.SizeBar:SetWide( 4 )
	self.SizeBar:SetZPos( self:GetZPos() + 1 ) -- TODO: replace this magic number?
	self.SizeBar:SetCursor( "sizewe" )
	self.SizeBar.OnMousePressed = function() self:StartSizing() end
	
end

function PANEL:PerformLayout( w, h )
	
	if self.Width != w then
		self.Width = w
		self:OnWidthChanged( self.Width )
		
	end
	
end

function PANEL:Update()
	
	self:LoadData()
	
end

function PANEL:LoadData()
	
	if not self.m_pListView then return end
	
	local data = self.m_pListView.Columns[ self.m_iItem ]
	
	self:SetText( data.Text )
	self.Width = data.Size
	self:SetWide( data.Size )
	
end

function PANEL:OnWidthChanged( w )
	
	if not self.m_pListView then return end
	
	self.m_pListView:OnColumnHeaderSizeChanged( self.m_bIsSizing and self.Sizing.ItemID or self.m_iItem, w )
	
end

function PANEL:Think()
	
	if not self.m_bIsSizing then return end
	
	local Value = math.max( self.Sizing.BaseWidth + ( gui.MouseX() - self.Sizing.MouseStart ), 24 )
	
	if self.m_pListView.Columns[ self.Sizing.ItemID ].Size == Value then return end -- MEH!!
	
	self:OnWidthChanged( Value ) -- Will update the corresponding data and panel if visible
	self:InvalidateLayout()
	
end

function PANEL:StartSizing()
	
	self:MouseCapture( true )
	self:SetCursor( "sizewe" )
	
	self.m_bIsSizing = true
	
	self.Sizing.MouseStart	= gui.MouseX()
	self.Sizing.BaseWidth	= self:GetWide()
	self.Sizing.ItemID		= self:GetItemID()
	
	
end

function PANEL:EndSizing()
	
	self:MouseCapture( false )
	self:SetCursor( "hand" )
	
	self.m_bIsSizing = false
	
end

function PANEL:OnMouseReleased( code )
	
	self:EndSizing()
	DButton.OnMouseReleased( self, code )
	
end

function PANEL:OnCursorExited()
	
	if self.m_bIsSizing then return end
	DButton.OnMouseReleased( self, code )
	
end


function PANEL:DoClick()
	-- ?
end


vgui.Register( "RecyclerView_ColumnHeader", PANEL, "DButton" )