//=============================================================================
// UTMGameAS - Assault, UT Millenium style: one match, then back to the menu.
//=============================================================================
class UTMGameAS extends Assault;

var UTMCore Core;

event InitGame(string Options, out string Error)
{
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
	// Only the second half decides the match
	if ( bResult && bDefenseSet && Core != None && Core.FindHuman() != None )
	{
		if ( bAssaultWon )
			Core.RecordResult(Core.Human.PlayerReplicationInfo.Team == Attacker.TeamIndex, false);
		else if ( bTiePartOne )
			Core.RecordResult(false, true);
		else
			Core.RecordResult(Core.Human.PlayerReplicationInfo.Team == Defender.TeamIndex, false);
	}
	return bResult;
}

function RestartGame()
{
	if ( bDontRestart )
		return;
	if ( !bGameEnded || (EndTime > Level.TimeSeconds) )
		return;
	if ( !bDefenseSet )
	{
		// first half done: swap sides and play the second half
		Super.RestartGame();
		return;
	}
	ResetGame();
	Core.ReturnToMenu();
}

defaultproperties
{
	GameName="UT Millenium Assault"
}
