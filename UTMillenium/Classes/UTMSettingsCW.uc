//=============================================================================
// UTMSettingsCW - Settings: technical, in-game and mutators.
// Only the options a casual mouse + keyboard player cares about.
//=============================================================================
class UTMSettingsCW extends UWindowDialogClientWindow;

var UWindowHSliderControl BrightSlider, FovSlider, SensSlider;
var UWindowHSliderControl MusicSlider, SoundSlider, SpeechSlider;
var UWindowComboControl FpsCombo;
var UWindowCheckbox InvertCheck, TauntCheck;
var UWindowSmallButton KeysButton, CharButton, MutButton;
var UWindowCheckbox ModeCheck[6];
var UWindowSmallButton MapsButton[6];

var bool bReady;
var float Y_Tech, Y_Game, Y_Modes, Y_Mut;

var localized string TechText, GameText, ModesText, MutText;
var localized string BrightText, FovText, FpsText, SensText, InvertText;
var localized string MusicText, SoundText, SpeechText, KeysText;
var localized string CharText, TauntText, MapsText, MutButtonText, MutCountText;
var localized string UnlimitedText;

function float LeftX()  { return 10; }
function float FullW()  { return WinWidth - 20; }

function UWindowHSliderControl MakeSlider(string Label, float Y, float Lo, float Hi, int Step, float V)
{
	local UWindowHSliderControl S;

	S = UWindowHSliderControl(CreateControl(class'UWindowHSliderControl', LeftX(), Y, FullW(), 16));
	S.SetRange(Lo, Hi, Step);
	S.SetValue(V);
	S.SetText(Label);
	S.SetFont(F_Normal);
	S.SliderWidth = FullW() * 0.5;
	return S;
}

function UWindowCheckbox MakeCheck(string Label, float X, float Y, float W, bool bOn)
{
	local UWindowCheckbox C;

	C = UWindowCheckbox(CreateControl(class'UWindowCheckbox', X, Y, W, 16));
	C.SetText(Label);
	C.SetFont(F_Normal);
	C.bChecked = bOn;
	C.Align = TA_Left;
	C.DownSound = Sound'UMenu.LittleSelect';
	return C;
}

function UWindowSmallButton MakeButton(string Label, float X, float Y, float W)
{
	local UWindowSmallButton B;

	B = UWindowSmallButton(CreateControl(class'UWindowSmallButton', X, Y, W, 16));
	B.SetText(Label);
	B.OverSound = Sound'UMenu.LittleSelect';
	B.DownSound = Sound'UMenu.BigSelect';
	return B;
}

function Created()
{
	local PlayerPawn P;
	local float Y;
	local int i, Fps;
	local string Tmp;

	Super.Created();
	P = GetPlayerOwner();

	// ---- Technical
	Y = 6;
	Y_Tech = Y;
	Y += 22;

	BrightSlider = MakeSlider(BrightText, Y, 2, 10, 1,
		int(float(P.ConsoleCommand("get ini:Engine.Engine.ViewportManager Brightness")) * 10));
	Y += 24;
	FovSlider = MakeSlider(FovText, Y, 80, 130, 1, P.DefaultFOV);
	Y += 24;

	FpsCombo = UWindowComboControl(CreateControl(class'UWindowComboControl', LeftX(), Y, FullW(), 16));
	FpsCombo.SetText(FpsText);
	FpsCombo.SetFont(F_Normal);
	FpsCombo.SetEditable(False);
	FpsCombo.EditBoxWidth = FullW() * 0.5;
	FpsCombo.AddItem(UnlimitedText, "0");
	FpsCombo.AddItem("60", "60");
	FpsCombo.AddItem("90", "90");
	FpsCombo.AddItem("120", "120");
	FpsCombo.AddItem("144", "144");
	FpsCombo.AddItem("165", "165");
	FpsCombo.AddItem("240", "240");
	Fps = int(float(P.ConsoleCommand("get ini:Engine.Engine.ViewportManager FrameRateLimit")));
	i = FpsCombo.FindItemIndex2(string(Fps));
	if ( i < 0 )
		i = 0;
	FpsCombo.SetSelectedIndex(i);
	Y += 24;

	SensSlider = MakeSlider(SensText, Y, 1, 40, 1, P.MouseSensitivity * 4);
	Y += 24;
	InvertCheck = MakeCheck(InvertText, LeftX(), Y, FullW(), P.bInvertMouse);
	Y += 24;

	MusicSlider = MakeSlider(MusicText, Y, 0, 255, 8, GetVol("MusicVolume", class'UTMSettings'.default.SavedMusicVolume));
	Y += 24;
	SoundSlider = MakeSlider(SoundText, Y, 0, 255, 8, GetVol("SoundVolume", class'UTMSettings'.default.SavedSoundVolume));
	Y += 24;
	Tmp = P.ConsoleCommand("get ini:Engine.Engine.AudioDevice SpeechVolume");
	if ( Left(Tmp, 12) != "Unrecognized" )
	{
		SpeechSlider = MakeSlider(SpeechText, Y, 0, 255, 8, GetVol("SpeechVolume", class'UTMSettings'.default.SavedSpeechVolume));
		Y += 24;
	}
	KeysButton = MakeButton(KeysText, LeftX(), Y, FullW());
	Y += 30;

	// ---- In-game
	Y_Game = Y;
	Y += 22;
	CharButton = MakeButton(CharText, LeftX(), Y, FullW());
	Y += 24;
	TauntCheck = MakeCheck(TauntText, LeftX(), Y, FullW(), class'TournamentPlayer'.default.bAutoTaunt);
	Y += 26;

	Y_Modes = Y;
	Y += 18;
	for ( i = 0; i < 6; i++ )
	{
		ModeCheck[i] = MakeCheck(class'UTMMatchMaker'.static.ModeName(i), LeftX(), Y, FullW() - 70, class'UTMSettings'.default.ModeOn[i] != 0);
		MapsButton[i] = MakeButton(MapsText, WinWidth - 70, Y, 60);
		Y += 22;
	}
	Y += 8;

	// ---- Mutators
	Y_Mut = Y;
	Y += 22;
	MutButton = MakeButton(MutButtonText, LeftX(), Y, FullW());
	Y += 30;

	DesiredWidth = 0;
	DesiredHeight = Y;
	bReady = true;
}

function float GetVol(string What, int SavedValue)
{
	if ( class'UTMSettings'.default.bMuted )
		return SavedValue;
	return float(GetPlayerOwner().ConsoleCommand("get ini:Engine.Engine.AudioDevice "$What));
}

function BeforePaint(Canvas C, float X, float Y)
{
	local int i;
	local UWindowWindow W;

	Super.BeforePaint(C, X, Y);
	// follow the window width (the scrollbar takes some room)
	for ( W = FirstChildWindow; W != None; W = W.NextSiblingWindow )
		W.WinWidth = WinWidth - 20;
	for ( i = 0; i < 6; i++ )
	{
		ModeCheck[i].WinWidth = WinWidth - 90;
		MapsButton[i].WinLeft = WinWidth - 70;
		MapsButton[i].WinWidth = 60;
	}
	BrightSlider.SliderWidth = (WinWidth - 20) * 0.5;
	FovSlider.SliderWidth = (WinWidth - 20) * 0.5;
	SensSlider.SliderWidth = (WinWidth - 20) * 0.5;
	MusicSlider.SliderWidth = (WinWidth - 20) * 0.5;
	SoundSlider.SliderWidth = (WinWidth - 20) * 0.5;
	if ( SpeechSlider != None )
		SpeechSlider.SliderWidth = (WinWidth - 20) * 0.5;
	FpsCombo.EditBoxWidth = (WinWidth - 20) * 0.5;
	SensSlider.SetText(SensText$": "$Left(string(SensSlider.GetValue() / 4.0), 4));
	FovSlider.SetText(FovText$": "$int(FovSlider.GetValue()));
}

function DrawHeader(Canvas C, float Y, string Text)
{
	C.Font = Root.Fonts[F_Bold];
	C.DrawColor.R = 200;
	C.DrawColor.G = 140;
	C.DrawColor.B = 0;
	ClipText(C, 10, Y + 3, Text);
	DrawStretchedTexture(C, 10, Y + 17, WinWidth - 20, 1, Texture'UWindow.WhiteTexture');
	C.DrawColor.R = 255;
	C.DrawColor.G = 255;
	C.DrawColor.B = 255;
}

function Paint(Canvas C, float X, float Y)
{
	Super.Paint(C, X, Y);
	DrawHeader(C, Y_Tech, TechText);
	DrawHeader(C, Y_Game, GameText);
	C.Font = Root.Fonts[F_Normal];
	C.DrawColor.R = 0; C.DrawColor.G = 0; C.DrawColor.B = 0;
	ClipText(C, 10, Y_Modes + 2, ModesText);
	DrawHeader(C, Y_Mut, MutText);
}

function SetVolume(string What, float V)
{
	local UTMConsole Con;

	Con = UTMConsole(Root.Console);
	if ( Con == None )
		return;
	if ( class'UTMSettings'.default.bMuted )
		Con.ToggleMute();   // touching a volume slider unmutes
	Con.SetVolume(What, int(V));
}

function Notify(UWindowDialogControl C, byte E)
{
	local PlayerPawn P;
	local int i;
	local UTMMapListWindow MW;

	Super.Notify(C, E);
	if ( !bReady )
		return;
	P = GetPlayerOwner();

	if ( E == DE_Change )
	{
		switch ( C )
		{
		case BrightSlider:
			P.ConsoleCommand("set ini:Engine.Engine.ViewportManager Brightness "$(BrightSlider.GetValue() / 10));
			P.ConsoleCommand("flush");
			break;
		case FovSlider:
			P.SetDesiredFOV(FovSlider.GetValue());
			P.DefaultFOV = FovSlider.GetValue();
			P.SaveConfig();
			break;
		case FpsCombo:
			P.ConsoleCommand("set ini:Engine.Engine.ViewportManager FrameRateLimit "$FpsCombo.GetValue2());
			break;
		case SensSlider:
			P.UpdateSensitivity(SensSlider.GetValue() / 4.0);
			P.SaveConfig();
			break;
		case InvertCheck:
			P.InvertMouse(InvertCheck.bChecked);
			P.SaveConfig();
			break;
		case MusicSlider:
			SetVolume("MusicVolume", MusicSlider.GetValue());
			break;
		case SoundSlider:
			SetVolume("SoundVolume", SoundSlider.GetValue());
			break;
		case SpeechSlider:
			SetVolume("SpeechVolume", SpeechSlider.GetValue());
			break;
		case TauntCheck:
			class'TournamentPlayer'.default.bAutoTaunt = TauntCheck.bChecked;
			if ( TournamentPlayer(P) != None )
			{
				TournamentPlayer(P).SetAutoTaunt(TauntCheck.bChecked);
				P.SaveConfig();
			}
			class'TournamentPlayer'.static.StaticSaveConfig();
			break;
		}
		for ( i = 0; i < 6; i++ )
			if ( C == ModeCheck[i] )
			{
				class'UTMSettings'.default.ModeOn[i] = byte(ModeCheck[i].bChecked);
				class'UTMSettings'.static.Save();
			}
	}
	else if ( E == DE_Click )
	{
		if ( C == KeysButton )
			Root.CreateWindow(class'UTMKeysWindow', 10, 10, 340, 600, OwnerWindow, True);
		else if ( C == CharButton )
			Root.CreateWindow(class'UTMPlayerWindow', 10, 10, 340, 400, OwnerWindow, True);
		else if ( C == MutButton )
			Root.CreateWindow(class'UTMMutatorWindow', 10, 10, 320, 520, OwnerWindow, True);
		for ( i = 0; i < 6; i++ )
			if ( C == MapsButton[i] )
			{
				class'UTMMapListCW'.default.Mode = i;
				MW = UTMMapListWindow(Root.CreateWindow(class'UTMMapListWindow', 10, 10, 300, 520, OwnerWindow, True));
				if ( MW != None )
					MW.WindowTitle = class'UTMMatchMaker'.static.ModeName(i)$" - "$MapsText;
			}
	}
}

defaultproperties
{
	TechText="TECHNICAL"
	GameText="IN-GAME"
	ModesText="Game modes in the random pick:"
	MutText="MUTATORS"
	BrightText="Brightness"
	FovText="Field of View"
	FpsText="Frame Rate Limit"
	SensText="Mouse Sensitivity"
	InvertText="Invert Mouse"
	MusicText="Music Volume"
	SoundText="Effects Volume"
	SpeechText="Voice Volume"
	KeysText="Key Bindings..."
	CharText="Character..."
	TauntText="Auto Taunt"
	MapsText="Maps"
	MutButtonText="Choose Mutators..."
	UnlimitedText="Unlimited"
}
