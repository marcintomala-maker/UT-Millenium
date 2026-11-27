//=============================================================================
// UTMHUDWindow - the original UT HUD settings (crosshair, HUD colors) in
// their own window.
//=============================================================================
class UTMHUDWindow extends UTMFramedWindow;

defaultproperties
{
	WindowTitle="HUD and Crosshair"
	ClientClass=class'UTMHUDScrollClient'
	WantWidth=340
	WantHeight=600
}
