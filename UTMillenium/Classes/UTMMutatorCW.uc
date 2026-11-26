//=============================================================================
// UTMMutatorCW - tick the mutators to use in every match.
// Lists every mutator the game knows (original UT ones + UT Millenium's).
//=============================================================================
class UTMMutatorCW extends UWindowDialogClientWindow;

var UWindowCheckbox Checks[64];
var string Classes[64];
var string Descs[64];
var int Count;
var bool bReady;
var string HoverDesc;
var float DescY;

function Created()
{
	local string Entry, Desc, Name;
	local int i, k;
	local float Y;

	Super.Created();
	Y = 8;
	GetPlayerOwner().GetNextIntDesc("Engine.Mutator", 0, Entry, Desc);
	while ( Entry != "" && Count < 64 && i < 256 )
	{
		k = InStr(Desc, ",");
		if ( k >= 0 )
		{
			Name = Left(Desc, k);
			Descs[Count] = Mid(Desc, k + 1);
		}
		else
		{
			Name = Desc;
			Descs[Count] = "";
		}
		if ( Name == "" )
			Name = Entry;
		Classes[Count] = Entry;
		Checks[Count] = UWindowCheckbox(CreateControl(class'UWindowCheckbox', 10, Y, 260, 16));
		Checks[Count].SetText(Name);
		Checks[Count].SetFont(F_Normal);
		Checks[Count].Align = TA_Left;
		Checks[Count].DownSound = Sound'UMenu.LittleSelect';
		Checks[Count].bChecked = class'UTMSettings'.static.IsMutatorOn(Entry);
		Count++;
		Y += 20;
		i++;
		GetPlayerOwner().GetNextIntDesc("Engine.Mutator", i, Entry, Desc);
	}
	DescY = Y + 6;
	DesiredWidth = 280;
	DesiredHeight = Y + 60;
	bReady = true;
}

function Paint(Canvas C, float X, float Y)
{
	Super.Paint(C, X, Y);
	if ( HoverDesc != "" )
	{
		C.Font = Root.Fonts[F_Normal];
		C.DrawColor.R = 0; C.DrawColor.G = 0; C.DrawColor.B = 0;
		WrapClipText(C, 10, DescY, HoverDesc);
		C.DrawColor.R = 255; C.DrawColor.G = 255; C.DrawColor.B = 255;
	}
}

function Notify(UWindowDialogControl C, byte E)
{
	local int i;

	Super.Notify(C, E);
	if ( !bReady )
		return;
	for ( i = 0; i < Count; i++ )
		if ( C == Checks[i] )
		{
			if ( E == DE_Change )
				class'UTMSettings'.static.SetMutatorOn(Classes[i], Checks[i].bChecked);
			else if ( E == DE_MouseEnter )
				HoverDesc = Descs[i];
		}
}

defaultproperties
{
}
