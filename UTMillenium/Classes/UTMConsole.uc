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
var bool   bBriefing;         // pre-match board is up
var float  BriefingAge;
var float  CursorFixTime;     // re-show the Windows cursor after a mode switch
var localized string SkipText;
var bool   bStarted;

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
	if ( !bStarted )
	{
		bStarted = true;
		Viewport.Actor.ConsoleCommand("HideLog");       // no UT log window
		class'Ladder'.default.HasBeatenGame = true;     // Xan is playable from the start
		if ( class'UTMSettings'.default.DefaultsVersion < 1 )
			ApplyDefaults();
	}
	if ( bBriefing )
		BriefingAge += Delta;
	// Switching between fullscreen and the window can leave the Windows cursor
	// hidden. Toggle it off and on again after every switch, then keep it on
	// while a menu is open.
	if ( CursorFixTime > 0 )
		CursorFixTime -= Delta;
	if ( bUWindowActive && !bQuickKeyEnable )
		Viewport.bShowWindowsMouse = !(CursorFixTime > 0.25);
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
	Log("UTM EnterLevel mode="$M$" level="$Viewport.Actor.Level);
	bLocked = false;
	switch ( M )
	{
		case MODE_MENU:
			bMatchPaused = false;
			bBriefing = false;
			SetPortrait();
			bQuickKeyEnable = false;
			LaunchUWindow();
			ApplyMute();
			break;
		case MODE_MATCH:
			bMatchPaused = false;
			SetBorderless();
			// pre-match board; the game stays paused until a click
			bBriefing = true;
			BriefingAge = 0;
			bQuickKeyEnable = false;
			Super.LaunchUWindow();
			bLocked = false;
			bNoDrawWorld = true;
			break;
		case MODE_CINEMATIC:
			bMatchPaused = false;
			bBriefing = false;
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
// UT Millenium defaults, applied once: modern keys, volumes, brightness.

function Bind(string Key, string Command)
{
	Viewport.Actor.ConsoleCommand("SET Input "$Key$" "$Command);
}

function ApplyDefaults()
{
	local int i;
	local PlayerPawn P;

	P = Viewport.Actor;
	Log("UTM applying default settings");
	// WSAD + C, numbers for weapons (as in the original)
	Bind("W", "MoveForward");
	Bind("S", "MoveBackward");
	Bind("A", "StrafeLeft");
	Bind("D", "StrafeRight");
	Bind("C", "Duck");
	Bind("Space", "Jump");
	Bind("LeftMouse", "Fire");
	Bind("RightMouse", "AltFire");
	for ( i = 1; i <= 9; i++ )
		Bind(string(i), "SwitchWeapon "$i);
	Bind("0", "SwitchWeapon 10");
	// no joystick / controller
	for ( i = 1; i <= 16; i++ )
		Bind("Joy"$i, "");
	Bind("JoyX", "");
	Bind("JoyY", "");
	Bind("JoyZ", "");
	Bind("JoyR", "");
	Bind("JoyU", "");
	Bind("JoyV", "");
	Bind("JoySlider1", "");
	Bind("JoySlider2", "");
	Bind("JoyPovUp", "");
	Bind("JoyPovDown", "");
	Bind("JoyPovLeft", "");
	Bind("JoyPovRight", "");
	P.ConsoleCommand("set ini:Engine.Engine.ViewportManager UseJoystick False");

	// volume sliders: music and effects at 80%, voices at 70%
	if ( !class'UTMSettings'.default.bMuted )
	{
		SetVolume("MusicVolume", 204);
		SetVolume("SoundVolume", 204);
		SetVolume("SpeechVolume", 179);
	}
	class'UTMSettings'.default.SavedMusicVolume = 204;
	class'UTMSettings'.default.SavedSoundVolume = 204;
	class'UTMSettings'.default.SavedSpeechVolume = 179;

	// brightness 0.8
	P.ConsoleCommand("set ini:Engine.Engine.ViewportManager Brightness 0.8");
	P.ConsoleCommand("flush");

	class'UTMSettings'.default.DefaultsVersion = 1;
	class'UTMSettings'.static.Save();
}

//-----------------------------------------------------------------------------
// Window modes

function SetPortrait()
{
	local int W, H;

	if ( ScreenMode == 1 )
		return;
	ScreenMode = 1;
	CursorFixTime = 0.5;
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
	CursorFixTime = 0.5;
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

	if ( !bQuickKeyEnable && M == MODE_MATCH )
		SetPortrait();
	Super.LaunchUWindow();
	bLocked = false;

	if ( bQuickKeyEnable )
		return;

	bNoDrawWorld = true;
	if ( M == MODE_MATCH )
		bMatchPaused = true;
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

function FinishBriefing()
{
	if ( !bBriefing || BriefingAge < 0.6 )
		return;
	Log("UTM FinishBriefing age="$BriefingAge);
	bBriefing = false;
	bQuickKeyEnable = false;
	Super.CloseUWindow();
	bNoDrawWorld = false;
}

state UWindow
{
	event bool KeyEvent( EInputKey Key, EInputAction Action, FLOAT Delta )
	{
		if ( bBriefing )
		{
			if ( Action == IST_Press )
				FinishBriefing();
			if ( Action == IST_Axis )
				return Super.KeyEvent(Key, Action, Delta);   // keep the cursor moving
			return true;
		}
		return Super.KeyEvent(Key, Action, Delta);
	}
}

// Leave the running match and go back to the main menu (nothing is
// counted as a win or a loss).
function QuitMatch()
{
	if ( !bMatchPaused )
		return;
	bMatchPaused = false;
	GoToMenu();
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
// Intro / outro: small pulsing hint

event PostRender( canvas C )
{
	local float XL, YL, P;
	local Font F;

	Super.PostRender(C);
	if ( GetMode() != MODE_CINEMATIC )
		return;
	F = Font(DynamicLoadObject("LadderFonts.UTLadder16", class'Font'));
	if ( F != None )
		C.Font = F;
	P = 0.6 + 0.4 * Sin(Viewport.Actor.Level.TimeSeconds * 2.2);
	C.Style = 1;
	C.DrawColor.R = byte(70 * P);
	C.DrawColor.G = byte(160 * P);
	C.DrawColor.B = byte(255 * P);
	C.bCenter = false;
	C.StrLen(SkipText, XL, YL);
	C.SetPos(C.ClipX / 2 - XL / 2, C.ClipY - YL * 2.5);
	C.DrawText(SkipText, false);
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
	SkipText="PRESS ANYWHERE TO CONTINUE"
	LoadingMessage="LOADING"
	PrecachingMessage="LOADING"
}
