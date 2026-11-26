//=============================================================================
// UTMPlateButton - a big menu button drawn with the red/yellow "plate"
// artwork from the original UT single player ladder screens.
//=============================================================================
class UTMPlateButton extends UWindowButton;

var string Label;

function Created()
{
	Super.Created();
	OverSound = Sound'UMenu.LittleSelect';
	DownSound = Sound'UMenu.BigSelect';
}

function Paint(Canvas C, float X, float Y)
{
	local Texture T;
	local float XL, YL;
	local bool bOver;

	bOver = !bDisabled && MouseIsOver();
	if ( bDisabled )
		T = Texture'UTMenu.Skins.Plate3Plain';
	else if ( bOver || bMouseDown )
		T = Texture'UTMenu.Skins.PlateYellow';
	else
		T = Texture'UTMenu.Skins.Plate';

	C.Style = 2;   // masked
	C.DrawColor.R = 255;
	C.DrawColor.G = 255;
	C.DrawColor.B = 255;
	if ( bDisabled )
	{
		C.DrawColor.R = 90;
		C.DrawColor.G = 90;
		C.DrawColor.B = 90;
	}
	DrawStretchedTextureSegment(C, 0, 0, WinWidth, WinHeight, 0, 0, 178, 48, T);
	C.Style = 1;

	C.Font = class'UTMMainWindow'.static.PickFont(Root, WinHeight * 0.42);
	if ( bDisabled )
	{
		C.DrawColor.R = 100; C.DrawColor.G = 100; C.DrawColor.B = 100;
	}
	else if ( bOver )
	{
		C.DrawColor.R = 255; C.DrawColor.G = 255; C.DrawColor.B = 0;
	}
	else
	{
		C.DrawColor.R = 255; C.DrawColor.G = 255; C.DrawColor.B = 255;
	}
	TextSize(C, Label, XL, YL);
	ClipText(C, (WinWidth - XL) / 2, (WinHeight - YL) / 2, Label, True);
	C.DrawColor.R = 255; C.DrawColor.G = 255; C.DrawColor.B = 255;
}

simulated function Click(float X, float Y)
{
	if ( bDisabled )
		return;
	Super.Click(X, Y);
}

defaultproperties
{
}
