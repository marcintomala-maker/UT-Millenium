//=============================================================================
// UTMMapListCW - tick the maps that may be picked for one game mode.
//=============================================================================
class UTMMapListCW extends UWindowDialogClientWindow;

var int Mode;
var UWindowCheckbox Checks[128];
var string Names[128];
var int Count;
var UWindowSmallButton AllButton, NoneButton;
var bool bReady;

var localized string AllText, NoneText, EmptyText;

function Created()
{
	local string List;
	local int i, n;
	local float Y;

	Super.Created();
	Mode = default.Mode;

	AllButton = UWindowSmallButton(CreateControl(class'UWindowSmallButton', 10, 6, 60, 16));
	AllButton.SetText(AllText);
	NoneButton = UWindowSmallButton(CreateControl(class'UWindowSmallButton', 76, 6, 60, 16));
	NoneButton.SetText(NoneText);

	List = class'UTMMatchMaker'.static.MapList(GetPlayerOwner(), Mode, false, n);
	Y = 30;
	for ( i = 0; i < n && Count < 128; i++ )
	{
		Names[Count] = class'UTMMatchMaker'.static.ListItem(List, i);
		Checks[Count] = UWindowCheckbox(CreateControl(class'UWindowCheckbox', 10, Y, 240, 16));
		Checks[Count].SetText(Names[Count]);
		Checks[Count].SetFont(F_Normal);
		Checks[Count].Align = TA_Left;
		Checks[Count].DownSound = Sound'UMenu.LittleSelect';
		Checks[Count].bChecked = !class'UTMSettings'.static.IsMapOff(Mode, Names[Count]);
		Count++;
		Y += 20;
	}
	DesiredWidth = 260;
	DesiredHeight = Y + 10;
	bReady = true;
}

function Paint(Canvas C, float X, float Y)
{
	Super.Paint(C, X, Y);
	if ( Count == 0 )
	{
		C.Font = Root.Fonts[F_Normal];
		C.DrawColor.R = 0; C.DrawColor.G = 0; C.DrawColor.B = 0;
		ClipText(C, 10, 34, EmptyText);
		C.DrawColor.R = 255; C.DrawColor.G = 255; C.DrawColor.B = 255;
	}
}

function SetAll(bool bOn)
{
	local int i;

	bReady = false;
	for ( i = 0; i < Count; i++ )
	{
		Checks[i].bChecked = bOn;
		class'UTMSettings'.static.SetMapOff(Mode, Names[i], !bOn);
	}
	bReady = true;
}

function Notify(UWindowDialogControl C, byte E)
{
	local int i;

	Super.Notify(C, E);
	if ( !bReady )
		return;
	if ( E == DE_Click )
	{
		if ( C == AllButton )
			SetAll(true);
		else if ( C == NoneButton )
			SetAll(false);
	}
	else if ( E == DE_Change )
	{
		for ( i = 0; i < Count; i++ )
			if ( C == Checks[i] )
				class'UTMSettings'.static.SetMapOff(Mode, Names[i], !Checks[i].bChecked);
	}
}

defaultproperties
{
	AllText="All"
	NoneText="None"
	EmptyText="No maps found for this mode."
}
