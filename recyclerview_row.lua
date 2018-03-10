local PANEL = {}

AccessorFunc( PANEL, "m_iItem", "ItemID" )
AccessorFunc( PANEL, "m_pListView", "ListView" )
AccessorFunc( PANEL, "m_bAlt", "AltLine" )

Derma_Hook( PANEL, "Paint", "Paint", "ListViewLine" )


function PANEL:Init()
	
	self.Height = 17 -- Arbitrary value. Panels seems to init with this height.
	self.Data = {}
	
	self.Panels = {} -- Columns panel for this row
	
	self:SetTall( self.Height )
	self.m_bAlt = false
	self.m_iItem = 0
	
end

function PANEL:PerformLayout( w, h )
	
	if self.Height != h then -- This let the inner panels decide the row's height
		
		self.Height = h
		self:OnHeightChanged( self.Height )
		
	end
	
end

function PANEL:OnChildAdded( child )
	
	child:Dock( LEFT )
	
end

function PANEL:Update()
	
	self:LoadData()
	self:BuildPanels()
	self:SetAltLine( self.m_iItem % 2 == 0 )
	
end

function PANEL:BuildPanels()
	
	local ListView = self.m_pListView
	if not ListView then return end
	
	local ColumnIndex		= ListView.Cache.HorizontalData.StartIndex -- Not using accessors as they are slower.
	local ColumnPanelType	= nil
	
	for i = 1, ListView.Cache.HorizontalData.Count do
		
		ColumnPanelType	= ListView.Columns[ ColumnIndex ].Type
		
		if self.Panels[ i ] and self.Panels[ i ].ClassName != ColumnPanelType then
			
			self.Panels[ i ]:Remove()
			self.Panels[ i ] = nil
			
		end
		
		if not self.Panels[ i ] then
			self.Panels[ i ] = self:Add( ColumnPanelType )
		end
		
		self.Panels[ i ]:SetSize( ListView.Columns[ ColumnIndex ].Size, self.Height )
		self.Panels[ i ]:SetZPos( i ) -- Render the panel at the correct place in the list.
		
		ListView.Columns[ ColumnIndex ].LoadFunc( self.Panels[ i ], self.Data[ ColumnIndex ], self.m_iItem, ColumnIndex )
		
		ColumnIndex = ColumnIndex + 1
		
	end
	
end

function PANEL:LoadData()
	
	if not self.m_pListView then return end
	
	local data = self.m_pListView.Rows[ self.m_iItem ]
	
	self.Data	= data.Data
	self.Height	= data.Size -- TODO: find out why it isn't updated in PerformLayout
	self:SetTall( data.Size )
	
	
end

function PANEL:OnHeightChanged( h )
	
	if not self.m_pListView then return end
	
	self:GetListView():OnRowSizeChanged( self.m_iItem, h )
	
end

function PANEL:OnColumnSizeChanged( i, width )
	
	if not self.Panels[ i ] then return end -- Shouldn't happen.
	
	self.Panels[ i ]:SetWide( width )
	
end

vgui.Register( "RecyclerView_Row", PANEL, "EditablePanel" )