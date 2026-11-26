//=============================================================================
// UTMConsole - decides what the game window shows:
//   menu level    -> small portrait window with the main menu
//   match         -> borderless fullscreen; ESC = back to the menu (paused)
//   intro / outro -> borderless fullscreen; any key = back to the menu
//=============================================================================
class UTMConsole extends UTConsole;

var string MenuURL;
var string IntroURL;
var string OutroURL;

var string LastLevel;
var int    ScreenMode;        // 1 = portrait window, 2 = borderless fullscreen
var bool   bMatchPaused;      // menu opened from a running match

const MODE_LOADING = -1;
const MODE_MENU = 0;
const MODE_MATCH = 1;
const MODE_CINEMATIC = 2;

//-----------------------------------------------------------------------------
// Where are we?

function int GetMode()
{
	local LevelInfo L;

	if ( Viewport == None || Viewport.Actor == None )
		return MODE_LOADING;
	L = Viewport.Actor.Level;
	if ( L == None || L == Viewport.Actor.GetEntryLevel() || L.Game == None )
		return MODE_LOADING;
	if ( L.Game.IsA('UTMMenuGame') )
		return MODE_MENU;
	if ( L.Game.IsA('UTIntro') )
	{
		if ( string(L.Outer.Name) ~= "UT-Logo-Map" )
			return MODE_MENU;
		return MODE_CINEMATIC;
	}
	return MODE_MATCH;
}

event Tick( float Delta )
{
	local string Lvl;
	local int M;

	Super.Tick(Delta);

	if ( Viewport == None || Viewport.Actor == None || Viewport.Actor.Level == None )
		return;
	Lvl = string(Viewport.Actor.Level);
	if ( Lvl == LastLevel )
		return;
	M = GetMode();
	if ( M == MODE_LOADING )
		return;
	LastLevel = Lvl;
	EnterLevel(M);
}

function EnterLevel(int M)
{
	bLocked = false;
	switch ( M )
	{
		case MODE_MENU:
			bMatchPaused = false;
			SetPortrait();
			bQuickKeyEnable = false;
			LaunchUWindow();
			ApplyMute();
			break;
		case MODE_MATCH:
		case MODE_CINEMATIC:
			bMatchPaused = false;
			SetBorderless();
			if ( bUWindowActive || IsInState('UWindow') )
			{
				bQuickKeyEnable = false;
				Super.CloseUWindow();
			}
			bNoDrawWorld = false;
			break;
	}
}

//-----------------------------------------------------------------------------
// Window modes

function SetPortrait()
{
	local int W, H;

	if ( ScreenMode == 1 )
		return;
	ScreenMode = 1;
	W = class'UTMSettings'.default.PortraitX;
	H = class'UTMSettings'.default.PortraitY;
	if ( W < 200 || H < 300 )
	{
		W = 450;
		H = 800;
	}
	Viewport.Actor.ConsoleCommand("SetScreenMode Windowed");
	Viewport.Actor.ConsoleCommand("SetRes "$W$"x"$H);
}

function SetBorderless()
{
	if ( ScreenMode == 2 )
		return;
	ScreenMode = 2;
	Viewport.Actor.ConsoleCommand("SetScreenMode Borderless");
	if ( class'UTMSettings'.default.DesktopX > 0 && class'UTMSettings'.default.DesktopY > 0 )
		Viewport.Actor.ConsoleCommand("SetRes "$class'UTMSettings'.default.DesktopX$"x"$class'UTMSettings'.default.DesktopY);
}

//-----------------------------------------------------------------------------
// Menu open / close

function LaunchUWindow()
{
	local int M;

	M = GetMode();
	if ( !bQuickKeyEnable && M == MODE_CINEMATIC )
	{
		GoToMenu();
		return;
	}

	Super.LaunchUWindow();
	bLocked = false;

	if ( bQuickKeyEnable )
		return;

	bNoDrawWorld = true;
	if ( M == MODE_MATCH )
	{
		bMatchPaused = true;
		SetPortrait();
	}
}

function CloseUWindow()
{
	local int M;
	local bool bWasQuick;

	M = GetMode();
	bWasQuick = bQuickKeyEnable;

	// the main menu level always shows the menu
	if ( M == MODE_MENU && !bWasQuick )
		return;

	Super.CloseUWindow();

	if ( M == MODE_MENU )
	{
		// e.g. the ~ console was closed: bring the menu back
		bQuickKeyEnable = false;
		LaunchUWindow();
		return;
	}

	if ( M == MODE_MATCH && !bWasQuick )
	{
		bMatchPaused = false;
		bNoDrawWorld = false;
		SetBorderless();
	}
}

// Skip UTConsole's ladder slot window, we have no ladder.
function CreateRootWindow(Canvas Canvas)
{
	Super(WindowConsole).CreateRootWindow(Canvas);
	CreateSpeech();
}

event bool KeyEvent( EInputKey Key, EInputAction Action, FLOAT Delta )
{
	local int M;

	M = GetMode();
	if ( M == MODE_CINEMATIC && Action == IST_Press )
	{
		GoToMenu();
		return true;
	}
	if ( M == MODE_MENU && Action == IST_Press && Key == IK_Escape )
	{
		bQuickKeyEnable = false;
		LaunchUWindow();
		return true;
	}
	return Super.KeyEvent(Key, Action, Delta);
}

//-----------------------------------------------------------------------------
// Actions used by the menu

function GoToMenu()
{
	Viewport.Actor.ClientTravel(MenuURL, TRAVEL_Absolute, false);
}

function bool StartMatch(int Tier)
{
	local string URL;

	URL = class'UTMMatchMaker'.static.BuildURL(Viewport.Actor, Tier);
	if ( URL == "" )
		return false;
	bMatchPaused = false;
	SetBorderless();
	Viewport.Actor.ClientTravel(URL, TRAVEL_Absolute, false);
	return true;
}

function PlayCinematic(bool bOutro)
{
	bMatchPaused = false;
	SetBorderless();
	if ( bOutro )
		Viewport.Actor.ClientTravel(OutroURL, TRAVEL_Absolute, false);
	else
		Viewport.Actor.ClientTravel(IntroURL, TRAVEL_Absolute, false);
}

function ResumeMatch()
{
	if ( bMatchPaused )
	{
		bQuickKeyEnable = false;
		CloseUWindow();
	}
}

function SetVolume(string What, int V)
{
	Viewport.Actor.ConsoleCommand("set ini:Engine.Engine.AudioDevice "$What$" "$Clamp(V, 0, 255));
}

function int GetVolume(string What)
{
	return int(Viewport.Actor.ConsoleCommand("get ini:Engine.Engine.AudioDevice "$What));
}

function ToggleMute()
{
	if ( class'UTMSettings'.default.bMuted )
	{
		class'UTMSettings'.default.bMuted = false;
		SetVolume("MusicVolume",  class'UTMSettings'.default.SavedMusicVolume);
		SetVolume("SoundVolume",  class'UTMSettings'.default.SavedSoundVolume);
		SetVolume("SpeechVolume", class'UTMSettings'.default.SavedSpeechVolume);
	}
	else
	{
		class'UTMSettings'.default.SavedMusicVolume  = GetVolume("MusicVolume");
		class'UTMSettings'.default.SavedSoundVolume  = GetVolume("SoundVolume");
		class'UTMSettings'.default.SavedSpeechVolume = GetVolume("SpeechVolume");
		class'UTMSettings'.default.bMuted = true;
		ApplyMute();
	}
	class'UTMSettings'.static.Save();
}

function ApplyMute()
{
	if ( !class'UTMSettings'.default.bMuted )
		return;
	SetVolume("MusicVolume", 0);
	SetVolume("SoundVolume", 0);
	SetVolume("SpeechVolume", 0);
}

function RefreshSpeed()
{
	local UTMCore C;

	foreach Viewport.Actor.AllActors(class'UTMCore', C)
		C.RefreshSpeed();
}

//-----------------------------------------------------------------------------
// Loading screen

function PrintActionMessage( Canvas C, string BigMessage )
{
	local float XL, YL;
	local Font F;

	if ( BigMessage == PausedMessage )
		return;   // the menu is on screen instead

	C.Style = 1;
	C.DrawColor.R = 255;
	C.DrawColor.G = 255;
	C.DrawColor.B = 255;
	C.SetPos(0, 0);
	C.DrawTile(Texture'UMenu.MenuBlack', FrameX, FrameY, 0, 0, 16, 16);

	F = Font(DynamicLoadObject("LadderFonts.UTLadder30", class'Font'));
	if ( F != None )
		C.Font = F;
	C.bCenter = false;
	C.StrLen(BigMessage, XL, YL);
	C.SetPos(FrameX/2 - XL/2, FrameY/2 - YL/2);
	C.DrawColor.R = 255;
	C.DrawColor.G = 200;
	C.DrawColor.B = 0;
	C.DrawText(BigMessage, false);

	F = Font(DynamicLoadObject("LadderFonts.UTLadder16", class'Font'));
	if ( F != None )
		C.Font = F;
	C.StrLen("UT MILLENIUM", XL, YL);
	C.SetPos(FrameX/2 - XL/2, FrameY/2 + YL * 2);
	C.DrawColor.R = 160;
	C.DrawColor.G = 160;
	C.DrawColor.B = 160;
	C.DrawText("UT MILLENIUM", false);
}

defaultproperties
{
	RootWindow="UTMillenium.UTMRootWindow"
	MenuURL="UT-Logo-Map.unr?Game=UTMillenium.UTMMenuGame"
	IntroURL="CityIntro.unr?Game=UTMillenium.UTMIntroGame"
	OutroURL="EOL_Challenge.unr?Game=UTMillenium.UTMOutroGame"
	ScreenMode=0
	LoadingMessage="LOADING"
	PrecachingMessage="LOADING"
}
