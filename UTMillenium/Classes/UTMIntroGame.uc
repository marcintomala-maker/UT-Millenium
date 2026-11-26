//=============================================================================
// UTMIntroGame - plays the original Unreal Tournament intro (CityIntro)
// once, then goes back to the menu instead of looping.
//=============================================================================
class UTMIntroGame extends UTIntro;

// CityIntro ends on the UT logo and then teleports back to its own start
// ("CityIntro#IntroIn"). That teleport is our cue to leave.
function SendPlayer( PlayerPawn aPlayer, string URL )
{
	aPlayer.ClientTravel(class'UTMConsole'.default.MenuURL, TRAVEL_Absolute, false);
}

defaultproperties
{
	GameName="UT Millenium Intro"
}
