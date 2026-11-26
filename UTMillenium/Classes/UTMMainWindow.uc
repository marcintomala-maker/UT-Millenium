//=============================================================================
// UTMMainWindow - the portrait main menu.
// Layout is designed on a 360 x 640 grid and scaled to the window.
//=============================================================================
class UTMMainWindow extends UWindowDialogClientWindow;

var UTMPlateButton BtnTier[3];
var UTMPlateButton BtnSettings, BtnCredits, BtnIntro, BtnOutro;
var UTMPlateButton BtnMute, BtnExit, BtnReset, BtnAddMaps;
var UTMCheck ChkSpeed, ChkMaxBots;
var UWindowMessageBox ResetBox, NoMapsBox, AddMapsBox;

var string TipText;
var string TipLine[8];
var float S, OX, OY;

var Texture LogoTex[3], BackTex, TrophyTex;
var Font HugeFont;

var localized string TierText[3];
var localized string SpeedText, SpeedTip, MaxBotsText, MaxBotsTip;
var localized string SettingsText, CreditsText, IntroText, OutroText;
var localized string MuteText, UnmuteText, ExitText, ResetText;
var localized string ResetTitle, ResetQuestion, NoMapsTitle, NoMapsText;
var localized string InProgressText, InProgressHint;
var localized string AddMapsText, AddMapsTitle, AddMapsQuestion;

//-----------------------------------------------------------------------------

static function Font PickFont(UWindowRootWindow R, float Units)
{
	local float Px;
	local int Sz;

	Px = Units * R.GUIScale;
	if      ( Px >= 30 ) Sz = 30;
	else if ( Px >= 22 ) Sz = 22;
	else if ( Px >= 20 ) Sz = 20;
	else if ( Px >= 18 ) Sz = 18;
	else if ( Px >= 16 ) Sz = 16;
	else if ( Px >= 14 ) Sz = 14;
	else if ( Px >= 12 ) Sz = 12;
	else if ( Px >= 10 ) Sz = 10;
	else                 Sz = 8;
	return Font(DynamicLoadObject("LadderFonts.UTLadder"$Sz, class'Font'));
}

function UTMPlateButton MakeButton(string Label)
{
	local UTMPlateButton B;

	B = UTMPlateButton(CreateControl(class'UTMPlateButton', 0, 0, 100, 30));
	B.Label = Label;
	return B;
}

function UTMCheck MakeCheck(string Label, bool bOn)
{
	local UTMCheck C;

	C = UTMCheck(CreateControl(class'UTMCheck', 0, 0, 200, 16));
	C.SetText(Label);
	C.SetFont(F_Bold);
	C.bChecked = bOn;
	C.Align = TA_Left;
	C.TextColor.R = 230;
	C.TextColor.G = 230;
	C.TextColor.B = 230;
	return C;
}

function Created()
{
	local int i;

	Super.Created();

	for ( i = 0; i < 3; i++ )
		BtnTier[i] = MakeButton(TierText[i]);

	ChkSpeed   = MakeCheck(SpeedText,   class'UTMSettings'.default.bOrigSpeed);
	ChkMaxBots = MakeCheck(MaxBotsText, class'UTMSettings'.default.bMaxBots);

	BtnSettings = MakeButton(SettingsText);
	BtnCredits  = MakeButton(CreditsText);
	BtnIntro    = MakeButton(IntroText);
	BtnOutro    = MakeButton(OutroText);
	BtnMute     = MakeButton(MuteText);
	BtnExit     = MakeButton(ExitText);
	BtnReset    = MakeButton(ResetText);
	BtnAddMaps  = MakeButton(AddMapsText);

	LogoTex[0] = Texture(DynamicLoadObject("Logo.UTLogo1", class'Texture'));
	LogoTex[1] = Texture(DynamicLoadObject("Logo.UTLogo2", class'Texture'));
	LogoTex[2] = Texture(DynamicLoadObject("Logo.UTLogo3", class'Texture'));
	BackTex    = Texture(DynamicLoadObject("MenuGr.rmetal", class'Texture'));
	TrophyTex  = Texture(DynamicLoadObject("UTMenu.Skins.TrophyChal", class'Texture'));
}

function Place(UWindowWindow W, float X, float Y, float Wd, float Ht)
{
	W.WinLeft = OX + X * S;
	W.WinTop = OY + Y * S;
	W.SetSize(Wd * S, Ht * S);
}

function BeforePaint(Canvas C, float X, float Y)
{
	local int i;
	local bool bInMatch;

	Super.BeforePaint(C, X, Y);

	S = FMin(WinWidth / 360.0, WinHeight / 640.0);
	OX = (WinWidth - 360 * S) / 2;
	OY = (WinHeight - 640 * S) / 2;

	for ( i = 0; i < 3; i++ )
		Place(BtnTier[i], 70, 318 + i * 46, 220, 42);

	Place(ChkSpeed,   100, 458, 170, 16);
	Place(ChkMaxBots, 100, 478, 170, 16);

	Place(BtnSettings, 24, 502, 152, 38);
	Place(BtnCredits, 184, 502, 152, 38);
	Place(BtnIntro,    24, 546, 152, 38);
	Place(BtnOutro,   184, 546, 152, 38);
	Place(BtnMute,     24, 600, 100, 28);
	Place(BtnExit,    236, 600, 100, 28);
	Place(BtnAddMaps, 130, 600, 100, 28);
	Place(BtnReset,   290, 274, 52, 18);

	bInMatch = UTMConsole(Root.Console) != None && UTMConsole(Root.Console).bMatchPaused;
	for ( i = 0; i < 3; i++ )
		BtnTier[i].bDisabled = bInMatch;
	BtnIntro.bDisabled = bInMatch;
	BtnOutro.bDisabled = bInMatch;
	BtnAddMaps.bDisabled = bInMatch;

	if ( class'UTMSettings'.default.bMuted )
		BtnMute.Label = UnmuteText;
	else
		BtnMute.Label = MuteText;
}

//-----------------------------------------------------------------------------
// Drawing

function SetColor(Canvas C, byte R, byte G, byte B)
{
	C.DrawColor.R = R;
	C.DrawColor.G = G;
	C.DrawColor.B = B;
}

function DrawBox(Canvas C, float X, float Y, float W, float H, byte Shade)
{
	SetColor(C, Shade, Shade, Shade);
	DrawStretchedTexture(C, OX + X*S, OY + Y*S, W*S, H*S, Texture'UMenu.MenuBlack');
	// border
	SetColor(C, 150, 110, 30);
	DrawStretchedTexture(C, OX + X*S, OY + Y*S, W*S, 1, Texture'UWindow.WhiteTexture');
	DrawStretchedTexture(C, OX + X*S, OY + (Y+H)*S - 1, W*S, 1, Texture'UWindow.WhiteTexture');
	DrawStretchedTexture(C, OX + X*S, OY + Y*S, 1, H*S, Texture'UWindow.WhiteTexture');
	DrawStretchedTexture(C, OX + (X+W)*S - 1, OY + Y*S, 1, H*S, Texture'UWindow.WhiteTexture');
	SetColor(C, 255, 255, 255);
}

function DrawCentered(Canvas C, string Text, float CX, float Y, float Units)
{
	local float XL, YL;

	C.Font = PickFont(Root, Units * S);
	TextSize(C, Text, XL, YL);
	ClipText(C, OX + CX*S - XL/2, OY + Y*S, Text, True);
}

function DrawStat(Canvas C, string Value, string Label, float CX, float Y)
{
	SetColor(C, 255, 210, 40);
	DrawCentered(C, Value, CX, Y, 18);
	SetColor(C, 170, 170, 170);
	DrawCentered(C, Label, CX, Y + 24, 9);
}

// The biggest font UT ships with, for the streak number.
function DrawHuge(Canvas C, string Text, float CX, float Y)
{
	local float XL, YL;

	if ( HugeFont == None )
		HugeFont = Font(DynamicLoadObject("UWindowFonts.UTFont40", class'Font'));
	if ( HugeFont == None || 40 > 50 * S * Root.GUIScale )
	{
		DrawCentered(C, Text, CX, Y, 30);
		return;
	}
	C.Font = HugeFont;
	TextSize(C, Text, XL, YL);
	ClipText(C, OX + CX*S - XL/2, OY + Y*S, Text, True);
}

function string KDText()
{
	local float KD;
	local string T;
	local int i;

	KD = float(class'UTMSettings'.default.Kills) / float(Max(1, class'UTMSettings'.default.Deaths));
	T = string(KD);
	i = InStr(T, ".");
	if ( i >= 0 )
		T = Left(T, i + 3);
	return T;
}

function Paint(Canvas C, float X, float Y)
{
	local int i;

	// background
	SetColor(C, 255, 255, 255);
	DrawStretchedTexture(C, 0, 0, WinWidth, WinHeight, Texture'UMenu.MenuBlack');
	if ( BackTex != None )
	{
		SetColor(C, 90, 90, 90);
		DrawStretchedTexture(C, OX, OY, 360*S, 640*S, BackTex);
	}

	// logo (three 256x256 pieces side by side)
	SetColor(C, 255, 255, 255);
	for ( i = 0; i < 3; i++ )
		if ( LogoTex[i] != None )
			DrawStretchedTexture(C, OX + (36 + i*96)*S, OY + 2*S, 96*S, 96*S, LogoTex[i]);

	SetColor(C, 255, 190, 0);
	DrawCentered(C, "MILLENIUM", 180, 92, 24);

	// the big one: winning streak
	DrawBox(C, 16, 124, 328, 98, 40);
	if ( TrophyTex != None )
	{
		SetColor(C, 255, 255, 255);
		C.Style = 2;
		DrawStretchedTexture(C, OX + 30*S, OY + 140*S, 56*S, 56*S, TrophyTex);
		DrawStretchedTexture(C, OX + 274*S, OY + 140*S, 56*S, 56*S, TrophyTex);
		C.Style = 1;
	}
	SetColor(C, 255, 255, 255);
	DrawCentered(C, "WINNING STREAK", 180, 130, 12);
	SetColor(C, 255, 200, 0);
	DrawHuge(C, string(class'UTMSettings'.default.Streak), 180, 146);
	SetColor(C, 170, 170, 170);
	DrawCentered(C, "HIGHEST STREAK:  "$class'UTMSettings'.default.BestStreak, 180, 202, 11);

	// the rest of the stats
	DrawBox(C, 16, 228, 328, 66, 60);
	DrawStat(C, KDText(), "K / D", 48, 236);
	DrawStat(C, string(class'UTMSettings'.default.Wins), "WINS", 114, 236);
	DrawStat(C, string(class'UTMSettings'.default.Losses), "LOSSES", 180, 236);
	DrawStat(C, string(class'UTMSettings'.default.Kills), "KILLS", 246, 236);
	DrawStat(C, string(class'UTMSettings'.default.Captures), "CAPTURES", 312, 236);

	// match section
	SetColor(C, 255, 255, 255);
	DrawCentered(C, "MATCH", 180, 298, 14);

	SetColor(C, 255, 255, 255);
}

// Splits Text into TipLine[] so every line fits into MaxW. Returns the line count.
function int WrapTip(Canvas C, string Text, float MaxW)
{
	local string Word, Line, Test;
	local int n, k;
	local float XL, YL;

	while ( Text != "" && n < 8 )
	{
		k = InStr(Text, " ");
		if ( k < 0 )
		{
			Word = Text;
			Text = "";
		}
		else
		{
			Word = Left(Text, k);
			Text = Mid(Text, k + 1);
		}
		if ( Line == "" )
			Test = Word;
		else
			Test = Line @ Word;
		TextSize(C, Test, XL, YL);
		if ( XL > MaxW && Line != "" )
		{
			TipLine[n++] = Line;
			Line = Word;
		}
		else
			Line = Test;
	}
	if ( Line != "" && n < 8 )
		TipLine[n++] = Line;
	return n;
}

function AfterPaint(Canvas C, float X, float Y)
{
	local float XL, YL, TY, H;
	local int Lines, i;

	Super.AfterPaint(C, X, Y);

	// "match in progress" plate on top of the greyed match buttons
	if ( UTMConsole(Root.Console) != None && UTMConsole(Root.Console).bMatchPaused )
	{
		DrawBox(C, 40, 344, 280, 80, 255);
		SetColor(C, 255, 210, 40);
		DrawCentered(C, InProgressText, 180, 356, 18);
		SetColor(C, 220, 220, 220);
		DrawCentered(C, InProgressHint, 180, 392, 11);
		SetColor(C, 255, 255, 255);
	}

	// tooltip: word-wrapped to the box, box sized to the text
	if ( TipText != "" )
	{
		C.Font = Root.Fonts[F_Normal];
		TextSize(C, "Wy", XL, YL);
		Lines = WrapTip(C, TipText, WinWidth - 24);
		H = Lines * YL + 10;
		TY = Y + 20;
		if ( TY + H > WinHeight )
			TY = Y - H - 8;
		SetColor(C, 255, 255, 255);
		DrawStretchedTexture(C, 4, TY, WinWidth - 8, H, Texture'UMenu.MenuBlack');
		SetColor(C, 255, 200, 0);
		DrawStretchedTexture(C, 4, TY, WinWidth - 8, 1, Texture'UWindow.WhiteTexture');
		DrawStretchedTexture(C, 4, TY + H - 1, WinWidth - 8, 1, Texture'UWindow.WhiteTexture');
		DrawStretchedTexture(C, 4, TY, 1, H, Texture'UWindow.WhiteTexture');
		DrawStretchedTexture(C, WinWidth - 5, TY, 1, H, Texture'UWindow.WhiteTexture');
		SetColor(C, 240, 240, 240);
		for ( i = 0; i < Lines; i++ )
			ClipText(C, 12, TY + 5 + i * YL, TipLine[i]);
		SetColor(C, 255, 255, 255);
	}
}

//-----------------------------------------------------------------------------
// Input

function Notify(UWindowDialogControl C, byte E)
{
	local int i;
	local UTMConsole Con;

	Super.Notify(C, E);
	Con = UTMConsole(Root.Console);

	switch ( E )
	{
	case DE_MouseEnter:
		if ( C == ChkSpeed )
			TipText = SpeedTip;
		else if ( C == ChkMaxBots )
			TipText = MaxBotsTip;
		break;

	case DE_MouseLeave:
		if ( C == ChkSpeed || C == ChkMaxBots )
			TipText = "";
		break;

	case DE_Change:
		if ( C == ChkSpeed )
		{
			class'UTMSettings'.default.bOrigSpeed = ChkSpeed.bChecked;
			class'UTMSettings'.static.Save();
			if ( Con != None )
				Con.RefreshSpeed();
		}
		else if ( C == ChkMaxBots )
		{
			class'UTMSettings'.default.bMaxBots = ChkMaxBots.bChecked;
			class'UTMSettings'.static.Save();
		}
		break;

	case DE_Click:
		if ( UTMPlateButton(C) != None && UTMPlateButton(C).bDisabled )
			return;
		for ( i = 0; i < 3; i++ )
			if ( C == BtnTier[i] && Con != None )
			{
				if ( !Con.StartMatch(i) )
					NoMapsBox = MessageBox(NoMapsTitle, NoMapsText, MB_OK, MR_OK, MR_OK);
				return;
			}
		if ( C == BtnSettings )
			Root.CreateWindow(class'UTMSettingsWindow', 10, 10, 340, 560, Self, True);
		else if ( C == BtnCredits )
			Root.CreateWindow(class'UTMCreditsWindow', 10, 10, 340, 560, Self, True);
		else if ( C == BtnIntro && Con != None )
			Con.PlayCinematic(false);
		else if ( C == BtnOutro && Con != None )
			Con.PlayCinematic(true);
		else if ( C == BtnMute && Con != None )
			Con.ToggleMute();
		else if ( C == BtnExit )
			Root.DoQuitGame();
		else if ( C == BtnAddMaps )
			AddMapsBox = MessageBox(AddMapsTitle, AddMapsQuestion, MB_YesNo, MR_No, MR_Yes);
		else if ( C == BtnReset )
			ResetBox = MessageBox(ResetTitle, ResetQuestion, MB_YesNo, MR_No, MR_No);
		break;
	}
}

function MessageBoxDone(UWindowMessageBox W, MessageBoxResult Result)
{
	if ( W == ResetBox && Result == MR_Yes )
		class'UTMSettings'.static.ResetStats();
	if ( W == AddMapsBox && Result == MR_Yes )
	{
		class'UTMSettings'.default.bAddMapsRequest = true;
		class'UTMSettings'.static.Save();
		Root.DoQuitGame();
	}
}

// ESC while the menu was opened from a match: back to the game.
function EscClose()
{
	if ( UTMConsole(Root.Console) != None )
		UTMConsole(Root.Console).ResumeMatch();
}

function Close(optional bool bByParent)
{
	// the main menu is never closed
}

defaultproperties
{
	TierText(0)="EASY"
	TierText(1)="MEDIUM"
	TierText(2)="HARD"
	SpeedText="Original Move Speed"
	SpeedTip="Off: you and the bots move 15% slower than in original UT (dodges stay original). On: original UT speed."
	MaxBotsText="Max Bots"
	MaxBotsTip="Off: bots fill the map's recommended player count. On: the map is filled with bots up to its maximum."
	SettingsText="SETTINGS"
	CreditsText="CREDITS"
	IntroText="PLAY INTRO"
	OutroText="PLAY OUTRO"
	MuteText="MUTE"
	UnmuteText="UNMUTE"
	ExitText="EXIT"
	ResetText="RESET"
	ResetTitle="Reset Stats"
	ResetQuestion="Erase all your stats (streaks, K/D, wins, losses, kills, captures)? This can't be undone."
	NoMapsTitle="No Maps"
	NoMapsText="No game mode with allowed maps. Turn on a game mode and some maps in Settings."
	AddMapsText="ADD MAPS"
	AddMapsTitle="Add Maps"
	AddMapsQuestion="UT Millenium will close for a moment so you can pick a folder with maps (zip files are fine). It copies all maps from there and starts again. Continue?"
	InProgressText="MATCH IN PROGRESS"
	InProgressHint="Press ESC to return to game"
}
