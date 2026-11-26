//=============================================================================
// UTMGameCTF - Capture the Flag, UT Millenium style: one match, then back to the menu.
//=============================================================================
class UTMGameCTF extends CTFGame;

var UTMCore Core;

event InitGame(string Options, out string Error)
{
	GoalTeamScore = 3;
	TimeLimit = 20;
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

function ScoreFlag(Pawn Scorer, CTFFlag theFlag)
{
	if ( Scorer != None && Scorer.PlayerReplicationInfo != None
		&& Scorer.PlayerReplicationInfo.Team != theFlag.Team && Core != None )
		Core.AddCapture(Scorer);
	Super.ScoreFlag(Scorer, theFlag);
}

defaultproperties
{
	GameName="UT Millenium Capture the Flag"
}
