//=============================================================================
// UTMFramedWindow - a floating window with an X to close it, sized to fit
// inside the portrait menu.
//=============================================================================
class UTMFramedWindow extends UMenuFramedWindow;

var float WantWidth, WantHeight;

function Created()
{
	bSizable = False;
	bStatusBar = False;
	Super.Created();
	FitToRoot();
	GetPlayerOwner().PlaySound(Sound'UMenu.WindowOpen', SLOT_Interface);
}

function Close(optional bool bByParent)
{
	if ( !bByParent )
		GetPlayerOwner().PlaySound(Sound'UMenu.WindowClose', SLOT_Interface);
	Super.Close(bByParent);
}

function FitToRoot()
{
	local float W, H;

	W = FMin(WantWidth, Root.WinWidth - 12);
	H = FMin(WantHeight, Root.WinHeight - 20);
	SetSize(W, H);
	WinLeft = int((Root.WinWidth - W) / 2);
	WinTop = int((Root.WinHeight - H) / 2);
}

function ResolutionChanged(float W, float H)
{
	FitToRoot();
	Super.ResolutionChanged(W, H);
}

defaultproperties
{
	WantWidth=340
	WantHeight=560
}
