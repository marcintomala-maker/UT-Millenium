//=============================================================================
// UTMZombieMutator - base for the "zombie" mutators.
// Every enemy bot (the other team, or every bot in non-team games) only gets
// ZombieWeapon and can't pick up any other weapon or ammo.
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
		if ( IsZombie(P) && P.Health > 0 && HasOtherWeapon(P) )
			MakeZombie(P);
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
