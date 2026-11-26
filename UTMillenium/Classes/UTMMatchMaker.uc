//=============================================================================
// UTMMatchMaker - picks a random allowed game mode and map and builds the
// travel URL for a new match.
//=============================================================================
class UTMMatchMaker extends Object;

const NUM_MODES = 6;

static function string ModeName(int Mode)
{
	switch ( Mode )
	{
		case 0: return "Deathmatch";
		case 1: return "Team Deathmatch";
		case 2: return "Capture the Flag";
		case 3: return "Domination";
		case 4: return "Assault";
		case 5: return "Last Man Standing";
	}
	return "";
}

static function string ModeGameClass(int Mode)
{
	switch ( Mode )
	{
		case 0: return "UTMillenium.UTMGameDM";
		case 1: return "UTMillenium.UTMGameTDM";
		case 2: return "UTMillenium.UTMGameCTF";
		case 3: return "UTMillenium.UTMGameDOM";
		case 4: return "UTMillenium.UTMGameAS";
		case 5: return "UTMillenium.UTMGameLMS";
	}
	return "";
}

static function string ModePrefix(int Mode)
{
	switch ( Mode )
	{
		case 2: return "CTF";
		case 3: return "DOM";
		case 4: return "AS";
	}
	return "DM";
}

static function string StripExt(string S)
{
	local int i;

	i = InStr(Caps(S), ".UNR");
	if ( i >= 0 )
		return Left(S, i);
	return S;
}

// All maps of a mode as ";Map1;Map2;...;" (tutorials left out).
static function string MapList(PlayerPawn P, int Mode, bool bOnlyAllowed, out int Count)
{
	local string First, Next, Name, List;
	local int Guard;

	Count = 0;
	List = ";";
	First = P.GetMapName(ModePrefix(Mode), "", 0);
	Next = First;
	while ( Next != "" && Guard < 512 )
	{
		Guard++;
		Name = StripExt(Next);
		if ( InStr(Caps(Name), "TUTORIAL") < 0
			&& Caps(Left(Name, Len(ModePrefix(Mode)) + 1)) == (ModePrefix(Mode)$"-")
			&& InStr(Caps(List), ";"$Caps(Name)$";") < 0
			&& (!bOnlyAllowed || !class'UTMSettings'.static.IsMapOff(Mode, Name)) )
		{
			List = List $ Name $ ";";
			Count++;
		}
		Next = P.GetMapName(ModePrefix(Mode), Next, 1);
		if ( Next == First )
			break;
	}
	return List;
}

// Returns the Nth entry (0-based) of a ";a;b;c;" list.
static function string ListItem(string List, int N)
{
	local int i;

	List = Mid(List, 1);
	for ( i = 0; i < N; i++ )
	{
		if ( InStr(List, ";") < 0 )
			return "";
		List = Mid(List, InStr(List, ";") + 1);
	}
	if ( InStr(List, ";") < 0 )
		return List;
	return Left(List, InStr(List, ";"));
}

static function string BuildURL(PlayerPawn P, int Tier)
{
	local int Modes[6], NumModes, i, Mode, Count, Pick;
	local string List, Map, URL;

	for ( i = 0; i < NUM_MODES; i++ )
		if ( class'UTMSettings'.default.ModeOn[i] != 0 )
		{
			MapList(P, i, true, Count);
			if ( Count > 0 )
				Modes[NumModes++] = i;
		}
	if ( NumModes == 0 )
		return "";

	Mode = Modes[Rand(NumModes)];
	List = MapList(P, Mode, true, Count);
	Pick = Rand(Count);
	Map = ListItem(List, Pick);
	if ( Count > 1 && Map ~= class'UTMSettings'.default.LastMap )
		Map = ListItem(List, (Pick + 1 + Rand(Count - 1)) % Count);

	class'UTMSettings'.default.LastMap = Map;
	class'UTMSettings'.static.Save();

	if ( Mode == 4 )
		class'UTMGameAS'.static.ResetGame();   // always start Assault at the first half

	URL = Map $ "?Game=" $ ModeGameClass(Mode) $ "?UTMTier=" $ Tier;
	if ( class'UTMSettings'.default.Mutators != "" )
		URL = URL $ "?Mutator=" $ class'UTMSettings'.default.Mutators;
	return URL;
}
