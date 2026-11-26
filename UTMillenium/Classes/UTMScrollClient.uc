//=============================================================================
// UTMScrollClient - scrolling area; subclasses set ClientClass.
//=============================================================================
class UTMScrollClient extends UWindowScrollingDialogClient;

function Created()
{
	FixedAreaClass = None;
	Super.Created();
}

defaultproperties
{
}
