//=============================================================================
// UTMSettings - everything UT Millenium remembers between sessions.
// Stored in System\UTMillenium.ini
//=============================================================================
class UTMSettings extends Object
	config(UTMillenium);

// Main menu toggles
var config bool   bOrigSpeed;      // false = everybody moves 10% slower
var config bool   bMaxBots;        // true  = fill the map to its maximum player count
var config bool   bJustTwoTeams;   // true  = TDM / Domination always use 2 teams

// Sound
var config bool   bMuted;
var config int    SavedMusicVolume;
var config int    SavedSoundVolume;
var config int    SavedSpeechVolume;

// Stats
var config int    Kills;
var config int    Deaths;
var config int    Wins;
var config int    Losses;
var config int    Captures;
var config int    Matches;
var config int    Streak;          // current winning streak
var config int    BestStreak;      // highest winning streak ever

// Game modes allowed (0=DM 1=TDM 2=CTF 3=DOM 4=AS 5=LMS)
var config byte   ModeOn[6];
// Disabled maps per mode, stored as ";Map1;Map2;" (empty = every map allowed)
var config string OffMaps[6];
// Enabled mutators, comma separated class names
var config string Mutators;
var config string LastMap;

// Set by the ADD MAPS button; the launcher picks it up after the game closes
var config bool   bAddMapsRequest;

// Which version of the UT Millenium default settings (keys, volumes,
// brightness) was applied already. Applied once, later changes are the player's.
var config int    DefaultsVersion;

// Window geometry (written by the launcher, which knows the desktop size)
var config int    PortraitX, PortraitY;
var config int    DesktopX, DesktopY;

static function Save()
{
	StaticSaveConfig();
}

static function ResetStats()
{
	default.Kills = 0;
	default.Deaths = 0;
	default.Wins = 0;
	default.Losses = 0;
	default.Captures = 0;
	default.Matches = 0;
	default.Streak = 0;
	default.BestStreak = 0;
	StaticSaveConfig();
}

static function bool IsMapOff(int Mode, string MapName)
{
	return InStr(Caps(default.OffMaps[Mode]), ";"$Caps(MapName)$";") >= 0;
}

static function SetMapOff(int Mode, string MapName, bool bOff)
{
	local string S, Key;
	local int i;

	S = default.OffMaps[Mode];
	if ( S == "" )
		S = ";";
	Key = ";"$MapName$";";
	i = InStr(Caps(S), Caps(Key));
	if ( bOff && i < 0 )
		S = S $ MapName $ ";";
	else if ( !bOff && i >= 0 )
		S = Left(S, i+1) $ Mid(S, i + Len(Key));
	if ( S == ";" )
		S = "";
	default.OffMaps[Mode] = S;
	StaticSaveConfig();
}

static function bool IsMutatorOn(string MutClass)
{
	return InStr(","$Caps(default.Mutators)$",", ","$Caps(MutClass)$",") >= 0;
}

static function SetMutatorOn(string MutClass, bool bOn)
{
	local string S, Key;
	local int i;

	S = ","$default.Mutators$",";
	Key = ","$MutClass$",";
	i = InStr(Caps(S), Caps(Key));
	if ( bOn && i < 0 )
		S = S $ MutClass $ ",";
	else if ( !bOn && i >= 0 )
		S = Left(S, i+1) $ Mid(S, i + Len(Key));
	// trim the commas we added
	while ( Left(S, 1) == "," )
		S = Mid(S, 1);
	while ( Right(S, 1) == "," )
		S = Left(S, Len(S) - 1);
	default.Mutators = S;
	StaticSaveConfig();
}

defaultproperties
{
	bOrigSpeed=False
	bMaxBots=False
	bMuted=False
	SavedMusicVolume=204
	SavedSoundVolume=204
	SavedSpeechVolume=179
	DefaultsVersion=0
	ModeOn(0)=1
	ModeOn(1)=1
	ModeOn(2)=1
	ModeOn(3)=1
	ModeOn(4)=0
	ModeOn(5)=0
	PortraitX=450
	PortraitY=800
	DesktopX=0
	DesktopY=0
}
