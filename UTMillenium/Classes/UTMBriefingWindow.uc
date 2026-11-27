//=============================================================================
// UTMBriefingWindow - the pre-match board, drawn on the Tournament ladder
// screen: game mode, map, screenshot, objectives. Click/key to start.
// Board coordinates are in the artwork's own 1024 x 768 space.
//=============================================================================
class UTMBriefingWindow extends UWindowWindow;

var Texture Tiles[12];
var float S, OX, OY;
var float Age;
var string Lines[24];
var int NumLines;

var string ModeTitle, MapTitle, MapAuthor, MapPlayers, MapFile;
var Texture StaticTex[4];
var Texture Shot;
var bool bPrepared;

var localized string PressText;

function Created()
{
	local int i;
	local string Row, Col;

	Super.Created();
	for ( i = 0; i < 12; i++ )
	{
		Row = string(i / 4 + 1);
		Col = string(int(i % 4) + 1);
		Tiles[i] = Texture(DynamicLoadObject("UTMenu.Skins.Ladr"$Row$Col, class'Texture'));
	}
	for ( i = 0; i < 4; i++ )
		StaticTex[i] = Texture(DynamicLoadObject("LadrStatic.Static.Static_A0"$i, class'Texture'));
}

function Tick(float Delta)
{
	Age += Delta;
}

//-----------------------------------------------------------------------------
// What to show

function AddLine(string T)
{
	if ( NumLines < 24 )
		Lines[NumLines++] = T;
}

function Prepare()
{
	local LevelInfo L;
	local GameInfo G;
	local DeathMatchPlus D;
	local TeamGamePlus T;
	local Assault A;
	local FortStandard F;
	local UTMCore Core;
	local PlayerPawn P;
	local int MyTeam, n;
	local string Enemies;

	bPrepared = true;
	P = GetPlayerOwner();
	L = P.Level;
	G = L.Game;
	D = DeathMatchPlus(G);
	T = TeamGamePlus(G);
	A = Assault(G);
	foreach P.AllActors(class'UTMCore', Core)
		break;

	MapTitle = L.Title;
	if ( MapTitle == "" || MapTitle ~= "Untitled" )
		MapTitle = string(L.Outer.Name);
	MapAuthor = L.Author;
	MapFile = string(L.Outer.Name);
	MapPlayers = L.IdealPlayerCount;
	Shot = L.Screenshot;

	MyTeam = 0;
	if ( P.PlayerReplicationInfo != None && P.PlayerReplicationInfo.Team < 2 )
		MyTeam = P.PlayerReplicationInfo.Team;

	if ( G.IsA('Assault') )
	{
		ModeTitle = "ASSAULT";
		if ( A.Attacker != None && A.Attacker.TeamIndex == MyTeam )
			AddLine("You ATTACK. Complete the objectives before time runs out:");
		else
			AddLine("You DEFEND. Stop the attackers until time runs out. They are after:");
		foreach P.AllActors(class'FortStandard', F)
			if ( F.FortName != "" && F.FortName != "Assault Target" && n++ < 6 )
				AddLine("- "$F.FortName);
		if ( A.bDefenseSet )
			AddLine("Second round: the sides have swapped.");
		else
			AddLine("After this round the teams swap sides.");
	}
	else if ( G.IsA('CTFGame') )
	{
		ModeTitle = "CAPTURE THE FLAG";
		AddLine("Steal the enemy flag and bring it home to your own flag.");
		AddLine("First team to "$int(T.GoalTeamScore)$" captures wins.");
	}
	else if ( G.IsA('Domination') )
	{
		ModeTitle = "DOMINATION";
		AddLine("Touch the control points to take them. Every point your team holds scores over time.");
		AddLine("First team to "$int(T.GoalTeamScore)$" points wins.");
	}
	else if ( G.IsA('LastManStanding') )
	{
		ModeTitle = "LAST MAN STANDING";
		AddLine("Everybody has "$LastManStanding(G).Lives$" lives. Be the last one standing.");
	}
	else if ( T != None )
	{
		ModeTitle = "TEAM DEATHMATCH";
		AddLine("Frag the other team. First team to "$int(T.GoalTeamScore)$" frags wins.");
	}
	else
	{
		ModeTitle = "DEATHMATCH";
		AddLine("Everyone against everyone. First to "$D.FragLimit$" frags wins.");
	}

	if ( D != None && D.TimeLimit > 0 && !G.IsA('Assault') )
		AddLine("Time limit: "$D.TimeLimit$" minutes.");

	AddLine("");
	if ( T != None && Core != None )
	{
		if ( Core.NumTeams() > 2 )
			AddLine(Core.NumTeams()$" teams in this match!");
		AddLine("You: "$T.Teams[MyTeam].TeamName$" Team ("$Core.Factions[Core.TeamFaction[MyTeam]].default.TeamName$").");
		if ( Core.bOneManArmy )
			AddLine("ONE MAN ARMY: you're alone, every bot is against you.");
		Enemies = "";
		for ( n = 0; n < Core.NumTeams(); n++ )
			if ( n != MyTeam )
			{
				if ( Enemies != "" )
					Enemies = Enemies $ ", ";
				Enemies = Enemies $ T.Teams[n].TeamName $ " Team (" $ Core.Factions[Core.TeamFaction[n]].default.TeamName $ ")";
			}
		AddLine("Enemies: "$Enemies$".");
	}
	else if ( Core != None )
		AddLine("Enemies: "$(D.NumBots + D.RemainingBots)$" bots, every one for themselves.");
	if ( Core != None )
	{
		switch ( Core.Tier )
		{
			case 0: AddLine("Bots: EASY (Novice to Experienced)."); break;
			case 1: AddLine("Bots: MEDIUM (Skilled to Masterful)."); break;
			default: AddLine("Bots: HARD (Inhuman and Godlike)."); break;
		}
	}
}

//-----------------------------------------------------------------------------
// Drawing

function BX(Canvas C, float X, float Y, float W, float H, Texture T)
{
	DrawStretchedTexture(C, OX + X*S, OY + Y*S, W*S, H*S, T);
}

function TextAt(Canvas C, float X, float Y, string T)
{
	ClipText(C, OX + X*S, OY + Y*S, T);
}

function TextCentered(Canvas C, float CX, float Y, string T)
{
	local float XL, YL;
	TextSize(C, T, XL, YL);
	ClipText(C, OX + CX*S - XL/2, OY + Y*S, T);
}

// word wrap Text into a column (board units); returns the new Y
function float WrapText(Canvas C, float X, float Y, float W, string Text, optional bool bMeasure)
{
	local string Word, Line, Test;
	local int k;
	local float XL, YL;

	TextSize(C, "Wy", XL, YL);
	if ( Text == "" )
		return Y + (YL / S) * 0.6;
	while ( Text != "" )
	{
		k = InStr(Text, " ");
		if ( k < 0 ) { Word = Text; Text = ""; }
		else { Word = Left(Text, k); Text = Mid(Text, k + 1); }
		if ( Line == "" ) Test = Word; else Test = Line @ Word;
		TextSize(C, Test, XL, YL);
		if ( XL > W*S && Line != "" )
		{
			if ( !bMeasure )
				TextAt(C, X, Y, Line);
			Y += YL / S;
			Line = Word;
		}
		else
			Line = Test;
	}
	if ( Line != "" )
	{
		if ( !bMeasure )
			TextAt(C, X, Y, Line);
		Y += YL / S;
	}
	return Y + 4;
}

// faint TV static (the same filter as on the map screenshot), fitted into a
// panel of the board art
function TVStatic(Canvas C, float X, float Y, float W, float H, int Frame)
{
	if ( StaticTex[0] == None )
		return;
	C.Style = 3;
	SetColor(C, 16, 16, 16);
	BX(C, X, Y, W, H, StaticTex[(int(Age * 20) + Frame) % 4]);
	C.Style = 1;
	SetColor(C, 255, 255, 255);
}

function SetColor(Canvas C, byte R, byte G, byte B)
{
	C.DrawColor.R = R; C.DrawColor.G = G; C.DrawColor.B = B;
}

function Paint(Canvas C, float X, float Y)
{
	local int i;
	local float TY, SW, SH, Blink, Flick;
	local int FontSize;

	if ( !bPrepared )
		Prepare();

	S = FMin(WinWidth / 1024.0, WinHeight / 768.0);
	OX = (WinWidth - 1024 * S) / 2;
	OY = (WinHeight - 768 * S) / 2;

	// a very light flicker, like an old monitor
	Flick = 0.95 + 0.05 * FRand();
	if ( FRand() < 0.02 )
		Flick = 0.88;

	SetColor(C, 255, 255, 255);
	DrawStretchedTexture(C, 0, 0, WinWidth, WinHeight, Texture'UMenu.MenuBlack');
	for ( i = 0; i < 12; i++ )
		if ( Tiles[i] != None )
			BX(C, (i % 4) * 256, (i / 4) * 256, 256.5, 256.5, Tiles[i]);

	// game mode in the top plate
	C.Font = class'UTMMainWindow'.static.PickFont(Root, 34 * S);
	SetColor(C, byte(255 * Flick), byte(210 * Flick), byte(40 * Flick));
	TextCentered(C, 252, 70, ModeTitle);
	TVStatic(C, 74, 62, 360, 52, 1);

	// map screenshot in the big screen
	if ( Shot != None )
	{
		SW = 320; SH = 320;
		if ( Shot.USize > Shot.VSize )
			SH = 320 * Shot.VSize / Shot.USize;
		SetColor(C, byte(255 * Flick), byte(255 * Flick), byte(255 * Flick));
		BX(C, 767 - SW/2, 247 - SH/2, SW, SH, Shot);
		// faint TV static on top
		if ( StaticTex[0] != None )
		{
			C.Style = 3;
			SetColor(C, 14, 14, 14);
			BX(C, 767 - SW/2, 247 - SH/2, SW, SH, StaticTex[int(Age * 20) % 4]);
			C.Style = 1;
		}
	}
	else
	{
		C.Font = class'UTMMainWindow'.static.PickFont(Root, 22 * S);
		SetColor(C, 120, 120, 120);
		TextCentered(C, 767, 236, MapTitle);
	}

	// objectives on the red grid
	C.Font = class'UTMMainWindow'.static.PickFont(Root, 24 * S);
	SetColor(C, byte(255 * Flick), byte(210 * Flick), byte(40 * Flick));
	TextAt(C, 172, 262, "OBJECTIVES");
	// pick the biggest font that still fits the red panel (bottom ~ y 640)
	for ( FontSize = 16; FontSize > 9; FontSize -= 2 )
	{
		C.Font = class'UTMMainWindow'.static.PickFont(Root, FontSize * S);
		TY = 300;
		for ( i = 0; i < NumLines; i++ )
			TY = WrapText(C, 172, TY, 200, Lines[i], true);
		if ( TY <= 640 )
			break;
	}
	SetColor(C, byte(235 * Flick), byte(235 * Flick), byte(235 * Flick));
	TY = 300;
	for ( i = 0; i < NumLines; i++ )
		TY = WrapText(C, 172, TY, 200, Lines[i]);
	TVStatic(C, 162, 256, 226, 400, 2);

	// map info in the bottom box
	C.Font = class'UTMMainWindow'.static.PickFont(Root, 26 * S);
	SetColor(C, byte(255 * Flick), byte(255 * Flick), byte(255 * Flick));
	TextCentered(C, 734, 592, MapTitle);
	C.Font = class'UTMMainWindow'.static.PickFont(Root, 14 * S);
	SetColor(C, 170, 170, 170);
	if ( MapAuthor != "" )
		TextCentered(C, 734, 622, "by "$MapAuthor);
	if ( MapPlayers != "" )
		TextCentered(C, 734, 638, MapFile$"   -   "$MapPlayers$" players");
	else
		TextCentered(C, 734, 638, MapFile);

	// press anywhere: big, slowly pulsing, in the blue of the UT intro billboard
	Blink = 0.65 + 0.35 * Sin(Age * 2.2);
	C.Font = class'UTMMainWindow'.static.PickFont(Root, 22 * S);
	SetColor(C, byte(70 * Blink), byte(160 * Blink), byte(255 * Blink));
	TextCentered(C, 734, 660, PressText);
	TVStatic(C, 529, 589, 388, 106, 3);
	TVStatic(C, 917, 609, 27, 66, 3);
	SetColor(C, 255, 255, 255);
}

function LMouseDown(float X, float Y)
{
	if ( UTMConsole(Root.Console) != None )
		UTMConsole(Root.Console).FinishBriefing();
}

defaultproperties
{
	PressText="PRESS ANYWHERE TO CONTINUE"
}
