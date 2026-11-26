//=============================================================================
// UTMPlayerWindow - the original UT character setup (name, team, model,
// skin, face, voice) with the 3D preview, resized for the portrait menu.
//=============================================================================
class UTMPlayerWindow extends UTPlayerWindow;

function SetSizePos()
{
	SetSize(Root.WinWidth - 10, Root.WinHeight - 20);
	WinLeft = int((Root.WinWidth - WinWidth) / 2);
	WinTop = int((Root.WinHeight - WinHeight) / 2);
}

function Resized()
{
	Super.Resized();
	if ( UMenuPlayerClientWindow(ClientArea) != None && UMenuPlayerClientWindow(ClientArea).Splitter != None )
		UMenuPlayerClientWindow(ClientArea).Splitter.SplitPos = int(ClientArea.WinWidth * 0.64);
}

defaultproperties
{
	bSizable=False
}
