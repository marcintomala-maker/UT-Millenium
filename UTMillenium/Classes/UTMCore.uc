//=============================================================================
// UTMCore - the brain of a UT Millenium match.
// Spawned by every UTMGame* class. Handles:
//  - bot count (map's recommended or max player count)
//  - bots with random factions, names, skins and per-bot random difficulty
//  - 10% slower movement (dodge distance stays original)
//  - stats (kills, deaths, captures, wins, losses)
//  - returning to the main menu when the match is over
//=============================================================================
class UTMCore extends Mutator;

const SlowFactor = 0.90;

var DeathMatchPlus G;
var int  Tier;                         // 0 = easy, 1 = medium, 2 = hard
var bool bSlow;
var bool bOneManArmy;
var bool bResultRecorded;
var bool bLeaving;

var class<RatedTeamInfo> Factions[9];
var int  TeamFaction[4];               // index into Factions for red / blue / green / gold
var int  NextMember[4];
var string UsedNames;

var PlayerPawn Human;
var EDodgeDir LastDodge;

//-----------------------------------------------------------------------------
// Setup

static function UTMCore Install(DeathMatchPlus Game, string Options)
{
	local UTMCore C;

	C = Game.Spawn(class'UTMCore');
	C.G = Game;
	C.Tier = Clamp(Game.GetIntOption(Options, "UTMTier", 0), 0, 2);
	C.bSlow = !class'UTMSettings'.default.bOrigSpeed;
	Game.BaseMutator.AddMutator(C);
	C.PickFactions();
	return C;
}

function PickFactions()
{
	local int i, j, Tmp, Order[9];

	// shuffle the 9 factions, first four go to red, blue, green, gold
	for ( i = 0; i < 9; i++ )
		Order[i] = i;
	for ( i = 8; i > 0; i-- )
	{
		j = Rand(i + 1);
		Tmp = Order[i];
		Order[i] = Order[j];
		Order[j] = Tmp;
	}
	for ( i = 0; i < 4; i++ )
		TeamFaction[i] = Order[i];
	UsedNames = "|";
}

function int NumTeams()
{
	if ( !G.bTeamGame )
		return 0;
	return Clamp(TeamGamePlus(G).MaxTeams, 2, 4);
}

// Called from the game's PostBeginPlay (after DeathMatchPlus set its own bot count)
function SetupMatch()
{
	local Mutator M;

	for ( M = G.BaseMutator; M != None; M = M.NextMutator )
		if ( M.IsA('UTMOneManArmy') )
			bOneManArmy = true;

	G.BotConfig.bAdjustSkill = false;
	G.bThreePlus = false;
	switch ( Tier )
	{
		case 0:
			G.bNoviceMode = true;
			G.Difficulty = 1;
			break;
		case 1:
			G.bNoviceMode = false;
			G.bThreePlus = true;
			G.Difficulty = 0;
			break;
		default:
			G.bNoviceMode = false;
			G.Difficulty = 2;
			break;
	}
	G.RemainingBots = ComputeBots();
	if ( G.bTeamGame )
		TeamGamePlus(G).bBalanceTeams = false;
}

function int ComputeBots()
{
	local string S;
	local int i, Lo, Hi, Total;

	S = Level.IdealPlayerCount;
	i = InStr(S, "-");
	if ( i >= 0 )
	{
		Lo = int(Left(S, i));
		Hi = int(Mid(S, i + 1));
	}
	else
	{
		Lo = int(S);
		Hi = Lo;
	}
	if ( Lo <= 0 )
		Lo = 4;
	if ( Hi < Lo )
		Hi = Lo;

	if ( class'UTMSettings'.default.bMaxBots )
		Total = Hi;
	else
		Total = (Lo + Hi + 1) / 2;

	Total = Clamp(Total, 2, 16);
	// even teams look fair: player + bots split evenly, at least 2 per team
	if ( G.bTeamGame && !bOneManArmy )
	{
		Total = Max(Total, 2 * NumTeams());
		if ( Total % NumTeams() != 0 )
			Total += NumTeams() - (Total % NumTeams());
		while ( Total > 16 )
			Total -= NumTeams();
	}
	return Total - 1;
}

//-----------------------------------------------------------------------------
// Helpers

function PlayerPawn FindHuman()
{
	local Pawn P;

	if ( Human != None && !Human.bDeleteMe )
		return Human;
	Human = None;
	for ( P = Level.PawnList; P != None; P = P.NextPawn )
		if ( P.IsA('PlayerPawn') && !P.IsA('Spectator') && (PlayerPawn(P).Player != None) )
		{
			Human = PlayerPawn(P);
			break;
		}
	return Human;
}

function int HumanTeam()
{
	if ( FindHuman() == None || Human.PlayerReplicationInfo == None )
		return 0;
	if ( Human.PlayerReplicationInfo.Team >= 4 )
		return 0;
	return Human.PlayerReplicationInfo.Team;
}

function float RandomSkill()
{
	switch ( Tier )
	{
		case 0:  return Rand(3);        // Novice, Average, Experienced
		case 1:  return 3 + Rand(3);    // Skilled, Adept, Masterful
		default: return 6 + Rand(2);    // Inhuman, Godlike
	}
}

//-----------------------------------------------------------------------------
// Bots

function int PickTeam()
{
	local TeamGamePlus T;
	local int i, Best, H;

	T = TeamGamePlus(G);
	H = HumanTeam();
	Best = -1;
	for ( i = 0; i < NumTeams(); i++ )
	{
		if ( bOneManArmy && i == H )
			continue;
		// on a tie prefer a team without the player
		if ( Best < 0 || T.Teams[i].Size < T.Teams[Best].Size
			|| (T.Teams[i].Size == T.Teams[Best].Size && Best == H) )
			Best = i;
	}
	return Best;
}

function bool IsOtherTeamsFaction(class<RatedTeamInfo> F, int Team)
{
	local int t;

	for ( t = 0; t < NumTeams(); t++ )
		if ( t != Team && F == Factions[TeamFaction[t]] )
			return true;
	return false;
}

function int FactionSize(class<RatedTeamInfo> F)
{
	local int i;

	for ( i = 0; i < 8; i++ )
		if ( F.default.BotClasses[i] == "" || F.default.BotNames[i] == "" )
			break;
	return i;
}

function bool NameFree(string N)
{
	return InStr(UsedNames, "|"$N$"|") < 0;
}

// Finds a faction member that isn't in the match yet.
function bool PickMember(int Team, out class<RatedTeamInfo> F, out int n)
{
	local int i, k, f0, Count;

	if ( Team >= 0 && Team < 4 )
	{
		F = Factions[TeamFaction[Team]];
		Count = FactionSize(F);
		for ( i = 0; i < Count; i++ )
		{
			k = (NextMember[Team] + i) % Count;
			if ( NameFree(F.default.BotNames[k]) )
			{
				NextMember[Team] = k + 1;
				n = k;
				return true;
			}
		}
	}

	// Deathmatch, or the team's faction ran out: anyone not playing yet,
	// but never someone from another team's faction.
	f0 = Rand(9);
	for ( i = 0; i < 9; i++ )
	{
		F = Factions[(f0 + i) % 9];
		if ( Team >= 0 && Team < 4 && IsOtherTeamsFaction(F, Team) )
			continue;
		Count = FactionSize(F);
		k = Rand(Count);
		for ( n = 0; n < Count; n++ )
			if ( NameFree(F.default.BotNames[(k + n) % Count]) )
			{
				n = (k + n) % Count;
				return true;
			}
	}
	F = Factions[0];
	n = Rand(FactionSize(F));
	return true;
}

function Bot SpawnBot(out NavigationPoint StartSpot)
{
	local Bot NewBot;
	local int Team, n;
	local class<RatedTeamInfo> F;
	local class<Bot> BC;

	Team = 255;
	if ( G.bTeamGame )
		Team = PickTeam();

	PickMember(Team, F, n);
	BC = class<Bot>(DynamicLoadObject(F.default.BotClasses[n], class'Class'));
	if ( BC == None )
		BC = class'TMale1Bot';

	StartSpot = G.FindPlayerStart(None, 255);
	if ( StartSpot == None )
	{
		log("UTM: could not find a start spot for a bot");
		return None;
	}

	NewBot = Spawn(BC,,, StartSpot.Location, StartSpot.Rotation);
	if ( NewBot == None )
		NewBot = Spawn(class'TMale1Bot',,, StartSpot.Location, StartSpot.Rotation);
	if ( NewBot == None )
		return None;

	NewBot.PlayerReplicationInfo.PlayerID = G.CurrentID++;
	if ( Team != 255 )
		NewBot.PlayerReplicationInfo.Team = Team;

	Individualize(NewBot, F, n, Team);
	NewBot.ViewRotation = StartSpot.Rotation;
	G.BroadcastMessage(NewBot.PlayerReplicationInfo.PlayerName $ G.EnteredMessage, false);

	G.ModifyBehaviour(NewBot);
	G.AddDefaultInventory(NewBot);
	G.NumBots++;
	if ( G.bRequireReady && (G.CountDown > 0) )
		NewBot.GotoState('Dying', 'WaitingForStart');
	NewBot.AirControl = G.AirControl;
	return NewBot;
}

function Individualize(Bot NewBot, class<RatedTeamInfo> F, int n, int Team)
{
	local string BotName;

	BotName = F.default.BotNames[n];
	G.ChangeName(NewBot, BotName, false);
	if ( BotName != NewBot.PlayerReplicationInfo.PlayerName )
		G.ChangeName(NewBot, "Bot", false);
	UsedNames = UsedNames $ BotName $ "|";

	if ( Team == 255 )
		NewBot.static.SetMultiSkin(NewBot, F.default.BotSkins[n], F.default.BotFaces[n], 255);
	else
		NewBot.static.SetMultiSkin(NewBot, F.default.BotSkins[n], F.default.BotFaces[n], Team);

	NewBot.InitializeSkill(RandomSkill());

	if ( (F.default.FavoriteWeapon[n] != "") && (F.default.FavoriteWeapon[n] != "None") )
		NewBot.FavoriteWeapon = class<Weapon>(DynamicLoadObject(F.default.FavoriteWeapon[n], class'Class'));
	NewBot.CombatStyle = NewBot.Default.CombatStyle + 0.7 * F.default.CombatStyle[n];
	NewBot.BaseAggressiveness = 0.5 * (NewBot.Default.Aggressiveness + NewBot.CombatStyle);
	NewBot.CampingRate = F.default.Camping[n];
	NewBot.bJumpy = ( F.default.BotJumpy[n] != 0 );
	NewBot.PlayerReplicationInfo.VoiceType = class<VoicePack>(DynamicLoadObject(NewBot.VoiceType, class'Class'));
}

//-----------------------------------------------------------------------------
// Movement speed

function ModifyPlayer(Pawn Other)
{
	ApplySpeed(Other);
	Super.ModifyPlayer(Other);
}

function ApplySpeed(Pawn P)
{
	if ( P == None || !P.bIsPlayer )
		return;
	if ( bSlow )
		P.GroundSpeed = P.Default.GroundSpeed * SlowFactor;
	else
		P.GroundSpeed = P.Default.GroundSpeed;
}

// Called by the menu when "Original Move Speed" is toggled during a match.
function RefreshSpeed()
{
	local Pawn P;

	bSlow = !class'UTMSettings'.default.bOrigSpeed;
	for ( P = Level.PawnList; P != None; P = P.NextPawn )
		ApplySpeed(P);
}

event Tick(float DeltaTime)
{
	local PlayerPawn H;

	H = FindHuman();
	if ( H == None )
		return;

	// A player dodge launches at 1.5 x GroundSpeed. Since GroundSpeed is 10%
	// lower, undo that on the first frame of the dodge so the distance stays
	// exactly like the original game. (Bot dodges use a fixed speed already.)
	if ( bSlow && H.DodgeDir == DODGE_Active && LastDodge != DODGE_Active && H.Physics == PHYS_Falling )
	{
		H.Velocity.X = H.Velocity.X / SlowFactor;
		H.Velocity.Y = H.Velocity.Y / SlowFactor;
	}
	LastDodge = H.DodgeDir;

	// Instant game: no "press fire to start"
	if ( G != None && G.bRequireReady && G.CountDown > 0 && !H.bReadyToPlay )
		H.bReadyToPlay = true;
}

//-----------------------------------------------------------------------------
// Stats

function ScoreKill(Pawn Killer, Pawn Other)
{
	local PlayerPawn H;

	H = FindHuman();
	if ( H != None && Other != None )
	{
		if ( Other == H )
			class'UTMSettings'.default.Deaths++;
		else if ( Killer == H && Other.bIsPlayer )
		{
			if ( !G.bTeamGame || Other.PlayerReplicationInfo == None
				|| Other.PlayerReplicationInfo.Team != H.PlayerReplicationInfo.Team )
				class'UTMSettings'.default.Kills++;
		}
		class'UTMSettings'.static.Save();
	}
	Super.ScoreKill(Killer, Other);
}

function AddCapture(Pawn Scorer)
{
	if ( Scorer != None && Scorer == FindHuman() )
	{
		class'UTMSettings'.default.Captures++;
		class'UTMSettings'.static.Save();
	}
}

// Works out the winner once the game has really ended.
function MatchEnded()
{
	local Pawn P, Best;
	local int i, BestTeam;
	local TeamGamePlus T;
	local PlayerPawn H;

	if ( bResultRecorded )
		return;
	H = FindHuman();
	if ( H == None || H.PlayerReplicationInfo == None )
		return;

	if ( G.bTeamGame )
	{
		T = TeamGamePlus(G);
		BestTeam = 0;
		for ( i = 1; i < T.MaxTeams; i++ )
			if ( T.Teams[i].Score > T.Teams[BestTeam].Score )
				BestTeam = i;
		RecordResult(H.PlayerReplicationInfo.Team == BestTeam, false);
	}
	else
	{
		for ( P = Level.PawnList; P != None; P = P.NextPawn )
			if ( P.bIsPlayer && P.PlayerReplicationInfo != None && !P.IsA('Spectator')
				&& (Best == None || P.PlayerReplicationInfo.Score > Best.PlayerReplicationInfo.Score) )
				Best = P;
		RecordResult(Best == H, false);
	}
}

function RecordResult(bool bWon, bool bTie)
{
	if ( bResultRecorded )
		return;
	bResultRecorded = true;
	class'UTMSettings'.default.Matches++;
	if ( !bTie )
	{
		if ( bWon )
		{
			class'UTMSettings'.default.Wins++;
			class'UTMSettings'.default.Streak++;
			if ( class'UTMSettings'.default.Streak > class'UTMSettings'.default.BestStreak )
				class'UTMSettings'.default.BestStreak = class'UTMSettings'.default.Streak;
		}
		else
		{
			class'UTMSettings'.default.Losses++;
			class'UTMSettings'.default.Streak = 0;
		}
	}
	class'UTMSettings'.static.Save();
}

//-----------------------------------------------------------------------------
// Back to the menu

function ReturnToMenu()
{
	if ( bLeaving )
		return;
	if ( FindHuman() == None )
		return;
	bLeaving = true;
	Human.ClientTravel(class'UTMConsole'.default.MenuURL, TRAVEL_Absolute, false);
}

defaultproperties
{
	Factions(0)=class'Botpack.RatedTeamInfo1'
	Factions(1)=class'Botpack.RatedTeamInfo2'
	Factions(2)=class'Botpack.RatedTeamInfo3'
	Factions(3)=class'Botpack.RatedTeamInfo4'
	Factions(4)=class'Botpack.RatedTeamInfo5'
	Factions(5)=class'Botpack.RatedTeamInfo6'
	Factions(6)=class'Botpack.RatedTeamInfo7'
	Factions(7)=class'Botpack.RatedTeamInfo8'
	Factions(8)=class'Botpack.RatedTeamInfoS'
}
