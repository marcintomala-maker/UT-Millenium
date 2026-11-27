//=============================================================================
// Bullet Time: every kill the player makes slows time down for 2.5 real
// seconds, Max Payne style. The duration is measured in real time; the game
// clock (match timer included) runs slow with everything else.
//=============================================================================
class UTMBulletTime extends Mutator;

var float RealLeft;        // real seconds of slow motion left
var float RealIn;          // real seconds since slow motion started
var float Duration;        // total, real seconds
var float SlowSpeed;       // game speed at the slowest
var float RampIn, RampOut; // real seconds to slow down / speed back up
var Sound SlowSound;       // an original UT sound, played slowed down

function bool IsHuman(Pawn P)
{
	return PlayerPawn(P) != None && PlayerPawn(P).Player != None && !P.IsA('Spectator');
}

function ScoreKill(Pawn Killer, Pawn Other)
{
	if ( Killer != None && Other != None && Killer != Other && IsHuman(Killer) && Other.bIsPlayer )
		StartSlowMo(PlayerPawn(Killer));
	Super.ScoreKill(Killer, Other);
}

function StartSlowMo(PlayerPawn P)
{
	// a kill during slow motion keeps it going instead of starting over
	if ( RealLeft <= 0 )
	{
		RealIn = 0;
		if ( SlowSound != None )
			P.PlaySound(SlowSound, SLOT_Interface, 2.0, false, , 0.6);
	}
	else if ( RealIn > RampIn )
		RealIn = RampIn;
	RealLeft = Duration - RealIn;
}

event Tick(float DeltaTime)
{
	local float Real, Speed;

	if ( RealLeft <= 0 )
		return;
	// DeltaTime is game time; turn it back into real time
	Real = DeltaTime / FMax(Level.TimeDilation, 0.01);
	RealIn += Real;
	RealLeft -= Real;

	if ( RealLeft <= 0 )
		Speed = 1.0;
	else if ( RealIn < RampIn )
		Speed = 1.0 + (SlowSpeed - 1.0) * (RealIn / RampIn);
	else if ( RealLeft < RampOut )
		Speed = SlowSpeed + (1.0 - SlowSpeed) * (1.0 - RealLeft / RampOut);
	else
		Speed = SlowSpeed;
	Level.TimeDilation = FClamp(Speed, SlowSpeed, 1.0);
}

event Destroyed()
{
	Level.TimeDilation = 1.0;
	Super.Destroyed();
}

defaultproperties
{
	Duration=2.5
	SlowSpeed=0.3
	RampIn=0.2
	RampOut=0.5
	SlowSound=Sound'UnrealShare.General.FatRingSound'
}
