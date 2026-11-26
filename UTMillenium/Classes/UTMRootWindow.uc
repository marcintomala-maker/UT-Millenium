//=============================================================================
// UTMRootWindow - hides the classic menu bar and shows the UT Millenium
// main menu instead. GUI scale follows the window height so the portrait
// menu looks the same on 1080p, 1440p and 4K screens.
//=============================================================================
class UTMRootWindow extends UMenuRootWindow;

var UTMMainWindow MainWin;

function Created()
{
	Super.Created();
	if ( MenuBar != None )
		MenuBar.HideWindow();
	if ( StatusBar != None )
		StatusBar.HideWindow();
	MainWin = UTMMainWindow(CreateWindow(class'UTMMainWindow', 0, 0, WinWidth, WinHeight));
	Resized();
}

function CalculateEffectiveGUIScale()
{
	local float S;

	if ( RealHeight > 0 )
	{
		S = float(int(RealHeight / 640.0 * 4.0)) / 4.0;
		GUIScale = FClamp(S, 1.0, 3.0);
		Log("UT Millenium GUI scale:"@GUIScale);
	}
	else
		Super.CalculateEffectiveGUIScale();
}

function Resized()
{
	Super.Resized();
	if ( MainWin != None )
	{
		MainWin.WinLeft = 0;
		MainWin.WinTop = 0;
		MainWin.SetSize(WinWidth, WinHeight);
	}
}

function BeforePaint(Canvas C, float X, float Y)
{
	Super.BeforePaint(C, X, Y);
	if ( MainWin == None )
		return;
	// The speech menu (V) and the console (~) use the window system in-game:
	// keep the main menu out of the way then.
	if ( Console.bQuickKeyEnable )
	{
		if ( MainWin.bWindowVisible )
			MainWin.HideWindow();
	}
	else if ( !MainWin.bWindowVisible )
	{
		MainWin.ShowWindow();
		MainWin.SendToBack();
	}
}

function Paint(Canvas C, float MouseX, float MouseY)
{
	if ( Console.bNoDrawWorld )
		DrawStretchedTexture(C, 0, 0, WinWidth, WinHeight, Texture'UMenu.MenuBlack');
}

function DoQuitGame()
{
	class'UTMSettings'.static.Save();
	Super.DoQuitGame();
}

defaultproperties
{
	LookAndFeelClass="UMenu.UMenuGoldLookAndFeel"
}
