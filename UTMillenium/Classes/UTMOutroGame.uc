//=============================================================================
// UTMOutroGame - the ending of the Tournament: your character on the
// podium with every trophy, and the final (Challenge) trophy arriving.
//=============================================================================
class UTMOutroGame extends TrophyGame;

var int Elapsed;
var() int ShowSeconds;

function AcceptInventory( Pawn PlayerPawn )
{
	local Trophy T;

	// skip TrophyGame's ladder logic, but keep UTIntro's inventory cleanup
	Super(UTIntro).AcceptInventory(PlayerPawn);

	if ( bTrophyInit )
		return;
	bTrophyInit = true;
	foreach AllActors(class'Trophy', T)
	{
		if ( T.IsA('Challenge') )
		{
			NewTrophyClass = T.Class;
			TrophyTime = 30;
			T.bHidden = true;
		}
		else
		{
			CorrectRotation = T.Rotation;
			T.bHidden = false;
		}
	}
}

function Timer()
{
	local Pawn P;

	Super.Timer();
	Elapsed++;
	if ( Elapsed == ShowSeconds )
		for ( P = Level.PawnList; P != None; P = P.NextPawn )
			if ( PlayerPawn(P) != None && PlayerPawn(P).Player != None )
				PlayerPawn(P).ClientTravel(class'UTMConsole'.default.MenuURL, TRAVEL_Absolute, false);
}

defaultproperties
{
	ShowSeconds=75
	GameName="UT Millenium Outro"
}
