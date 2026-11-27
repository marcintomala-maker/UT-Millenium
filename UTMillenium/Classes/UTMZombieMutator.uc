//=============================================================================
// UTMZombieMutator - base for the "zombie" mutators.
// Every enemy bot (the other team, or every bot in non-team games) only gets
// ZombieWeapon and can't pick up any other weapon or ammo.
// Zombies behave like zombies: they never run away to look for better
// weapons (that made them stand on pickups they can't take); they always
// hunt the nearest living player who isn't a zombie.
//=============================================================================
class UTMZombieMutator extends Mutator
	abstract;

var class<Weapon> ZombieWeapon;
var PlayerPawn Human;
var float CheckTimer;

function PlayerPawn FindHuman()
{
	local Pawn P;

	if ( Human != None && !Human.bDeleteMe )
		return Human;
	Human = None;
	for ( P = Level.PawnList; P != None; P = P.NextPawn )
		if ( P.IsA('PlayerPawn') && !P.IsA('Spectator') && PlayerPawn(P).Player != None )
		{
			Human = PlayerPawn(P);
			break;
		}
	return Human;
}

function bool IsZombie(Pawn P)
{
	if ( Bot(P) == None || P.PlayerReplicationInfo == None )
		return false;
	if ( !Level.Game.bTeamGame || FindHuman() == None || Human.PlayerReplicationInfo == None )
		return true;
	return P.PlayerReplicationInfo.Team != Human.PlayerReplicationInfo.Team;
}

function MakeZombie(Pawn P)
{
	local Inventory Inv, Next;
	local Weapon W;

	if ( P.Health <= 0 )
		return;

	W = Weapon(P.FindInventoryType(ZombieWeapon));
	for ( Inv = P.Inventory; Inv != None; Inv = Next )
	{
		Next = Inv.Inventory;
		if ( (Weapon(Inv) != None && Inv != W) || Ammo(Inv) != None )
		{
			if ( P.Weapon == Inv )
				P.Weapon = None;
			if ( P.PendingWeapon == Inv )
				P.PendingWeapon = None;
			Inv.Destroy();
		}
	}

	if ( W == None && DeathMatchPlus(Level.Game) != None )
	{
		DeathMatchPlus(Level.Game).GiveWeapon(P, string(ZombieWeapon));
		W = Weapon(P.FindInventoryType(ZombieWeapon));
	}
	if ( W != None && P.Weapon != W )
	{
		P.PendingWeapon = W;
		P.ChangedWeapon();
	}
}

function bool HasOtherWeapon(Pawn P)
{
	local Inventory Inv;

	for ( Inv = P.Inventory; Inv != None; Inv = Inv.Inventory )
		if ( Weapon(Inv) != None && Inv.Class != ZombieWeapon )
			return true;
	return P.FindInventoryType(ZombieWeapon) == None;
}

function ModifyPlayer(Pawn Other)
{
	Super.ModifyPlayer(Other);
	if ( IsZombie(Other) )
		MakeZombie(Other);
}

// Weapons are also handed out after ModifyPlayer (e.g. the translocator),
// so keep an eye on the zombies.
event Tick(float DeltaTime)
{
	local Pawn P;

	CheckTimer -= DeltaTime;
	if ( CheckTimer > 0 )
		return;
	CheckTimer = 0.25;
	for ( P = Level.PawnList; P != None; P = P.NextPawn )
		if ( IsZombie(P) && P.Health > 0 )
		{
			if ( HasOtherWeapon(P) )
				MakeZombie(P);
			ZombieBrain(Bot(P));
		}
}

function Pawn NearestVictim(Bot B)
{
	local Pawn P, Best;
	local float D, BestD;

	for ( P = Level.PawnList; P != None; P = P.NextPawn )
		if ( P != B && P.bIsPlayer && P.Health > 0 && !P.IsA('Spectator')
			&& P.PlayerReplicationInfo != None && !IsZombie(P)
			&& (!Level.Game.bTeamGame || P.PlayerReplicationInfo.Team != B.PlayerReplicationInfo.Team) )
		{
			D = VSize(P.Location - B.Location);
			if ( Best == None || D < BestD )
			{
				Best = P;
				BestD = D;
			}
		}
	return Best;
}

function ZombieBrain(Bot B)
{
	local Pawn V;

	if ( B == None || B.Health <= 0 || B.IsInState('GameEnded') || B.IsInState('Dying') )
		return;
	B.bKamikaze = true;        // never afraid: no retreating to weapon pickups
	B.bMustHunt = true;        // chase enemies it can't see
	if ( B.Enemy != None && B.Enemy.Health > 0 && !B.Enemy.bDeleteMe )
	{
		// shambling back to a pickup instead of fighting? back to the hunt
		if ( B.IsInState('Retreating') )
			B.GotoState('Attacking');
		return;
	}
	// no enemy: go after the nearest living non-zombie
	if ( !(B.IsInState('Roaming') || B.IsInState('Wandering') || B.IsInState('Retreating')
		|| B.IsInState('StakeOut') || B.IsInState('Waiting')) )
		return;
	V = NearestVictim(B);
	if ( V == None )
		return;
	B.Enemy = V;
	B.LastSeenPos = V.Location;
	B.LastSeenTime = Level.TimeSeconds;
	B.bMustHunt = true;
	B.GotoState('Attacking');
}

function bool HandlePickupQuery(Pawn Other, Inventory Item, out byte bAllowPickup)
{
	if ( IsZombie(Other) && (Weapon(Item) != None || Ammo(Item) != None) && Item.Class != ZombieWeapon )
	{
		bAllowPickup = 0;
		return true;
	}
	return Super.HandlePickupQuery(Other, Item, bAllowPickup);
}

defaultproperties
{
}
