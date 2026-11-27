//=============================================================================
// UTMGameDOM - Domination, UT Millenium style: one match, then back to the menu.
//=============================================================================
class UTMGameDOM extends Domination;

var UTMCore Core;

event InitGame(string Options, out string Error)
{
	local int PickedTeam;

	GoalTeamScore = 100;
	TimeLimit = 20;
	if ( class'UTMSettings'.default.bJustTwoTeams )
		MaxTeams = 2;
	else
		MaxTeams = 2 + Rand(3);   // 2, 3 or 4 teams
	// the team picked in the Character screen always exists in the match
	// (Green needs 3 teams, Gold 4); "None" ends up on Red. Characters
	// without a faction (Xan, Nali...) get a random team instead.
	PickedTeam = GetIntOption(Options, "Team", 255);
	if ( !class'UTMSettings'.default.bJustTwoTeams && PickedTeam >= 2 && PickedTeam <= 3
		&& class'UTMCore'.static.FactionForSkin(ParseOption(Options, "Skin")) >= 0 )
		MaxTeams = Max(MaxTeams, PickedTeam + 1);
	Super.InitGame(Options, Error);
	Core = class'UTMCore'.static.Install(self, Options);
}

function PostBeginPlay()
{
	Super.PostBeginPlay();
	if ( Core != None )
		Core.SetupMatch();
}

function Bot SpawnBot(out NavigationPoint StartSpot)
{
	return Core.SpawnBot(StartSpot);
}

function bool SetEndCams(string Reason)
{
	local bool bResult;

	bResult = Super.SetEndCams(Reason);
	if ( bResult && Core != None )
		Core.MatchEnded();
	return bResult;
}

function RestartGame()
{
	if ( bDontRestart )
		return;
	if ( EndTime > Level.TimeSeconds )
		return;
	Core.ReturnToMenu();
}

function bool ChangeTeam(Pawn Other, int NewTeam)
{
	if ( Core != None )
		NewTeam = Core.TeamFor(Other, NewTeam);
	return Super.ChangeTeam(Other, NewTeam);
}

defaultproperties
{
	HUDType=Class'UTMillenium.UTMDominationHUD'
	GameName="UT Millenium Domination"
}
