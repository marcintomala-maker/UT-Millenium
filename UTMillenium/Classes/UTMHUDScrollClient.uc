//=============================================================================
// UTMHUDScrollClient - the original UT HUD page (HUD colors, crosshairs...).
//=============================================================================
class UTMHUDScrollClient extends UWindowScrollingDialogClient;

function Created()
{
	ClientClass = class<UWindowDialogClientWindow>(DynamicLoadObject("UTMenu.UTChallengeHUDConfig", class'Class'));
	FixedAreaClass = None;
	Super.Created();
}
