//=============================================================================
// UTMMenuGame - the "level" behind the main menu. Nothing happens here,
// it just keeps the menu music playing.
//=============================================================================
class UTMMenuGame extends UTIntro;

event PostLogin( PlayerPawn NewPlayer )
{
	local Music M;

	Super.PostLogin(NewPlayer);
	M = Music(DynamicLoadObject("utmenu23.utmenu23", class'Music'));
	if ( M != None )
		NewPlayer.ClientSetMusic(M, 0, 255, MTRAN_Fade);
}

defaultproperties
{
	GameName="UT Millenium Menu"
}
