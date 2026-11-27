//=============================================================================
// UTMPlayerClient - character setup with the 3D preview on top and the
// options below (fits the portrait menu).
// The original setup panel finds its preview through Splitter.RightClientWindow,
// so we keep a (hidden) Splitter that just points at our preview.
//=============================================================================
class UTMPlayerClient extends UMenuPlayerClientWindow;

var UWindowVSplitter VSplit;
var UTMPlayerMeshClient Preview;
var localized string XanName;

function Created()
{
	Super(UMenuDialogClientWindow).Created();

	VSplit = UWindowVSplitter(CreateWindow(class'UWindowVSplitter', 0, 0, WinWidth, WinHeight));
	VSplit.bSizable = False;
	Preview = UTMPlayerMeshClient(VSplit.CreateWindow(class'UTMPlayerMeshClient', 0, 0, 100, 100));
	VSplit.TopClientWindow = Preview;

	// lookup helper for the setup panel (never shown)
	Splitter = UWindowHSplitter(CreateWindow(class'UWindowHSplitter', 0, 0, 1, 1));
	Splitter.HideWindow();
	Splitter.RightClientWindow = Preview;

	VSplit.BottomClientWindow = VSplit.CreateWindow(PlayerSetupClass, 0, 0, 100, 100, OwnerWindow);
	VSplit.SplitPos = int(WinHeight * 0.5);
}

function Resized()
{
	Super(UMenuDialogClientWindow).Resized();
	if ( VSplit != None )
	{
		VSplit.SetSize(WinWidth, WinHeight);
		VSplit.SplitPos = int(WinHeight * 0.5);
	}
}

// The final boss is listed as plain "Boss" in Unreal Tournament's menus;
// show his name from the game's own story instead.
function Paint(Canvas C, float X, float Y)
{
	local UMenuPlayerSetupClient S;

	Super.Paint(C, X, Y);
	if ( VSplit != None && UWindowScrollingDialogClient(VSplit.BottomClientWindow) != None )
		S = UMenuPlayerSetupClient(UWindowScrollingDialogClient(VSplit.BottomClientWindow).ClientArea);
	if ( S != None )
	{
		RenameBoss(S.ClassCombo);
		RenameBoss(S.SkinCombo);
	}
}

function RenameBoss(UWindowComboControl Combo)
{
	local UWindowComboListItem I;

	if ( Combo == None || Combo.List == None || Combo.List.Items == None )
		return;
	for ( I = UWindowComboListItem(Combo.List.Items.Next); I != None; I = UWindowComboListItem(I.Next) )
		if ( I.Value == "Boss" )
			I.Value = XanName;
	if ( Combo.EditBox != None && Combo.EditBox.Value == "Boss" )
		Combo.EditBox.Value = XanName;
}

defaultproperties
{
	XanName="Xan Kriegor"
	PlayerSetupClass=class'UTMenu.UTPlayerSetupScrollClient'
}
