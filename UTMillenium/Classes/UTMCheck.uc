//=============================================================================
// UTMCheck - checkbox with the box on the left and the label right after it.
//=============================================================================
class UTMCheck extends UWindowCheckbox;

function Created()
{
	Super.Created();
	OverSound = Sound'UMenu.LittleSelect';
	DownSound = Sound'UMenu.BigSelect';
}

function BeforePaint(Canvas C, float X, float Y)
{
	Super.BeforePaint(C, X, Y);
	ImageX = 0;
	TextX = 22;
}

defaultproperties
{
}
