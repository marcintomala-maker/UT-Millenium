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
var int HoverIdx;
var string TipLine[8];

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
	DesiredWidth = 280;
	DesiredHeight = Y + 8;
	bReady = true;
}

function int WrapTip(Canvas C, string Text, float MaxW)
{
	local string Word, Line, Test;
	local int n, k;
	local float XL, YL;

	while ( Text != "" && n < 8 )
	{
		if ( Left(Text, 1) == "|" )
		{
			if ( Line != "" )
				TipLine[n++] = Line;
			Line = "";
			Text = Mid(Text, 1);
			continue;
		}
		k = InStr(Text, " ");
		if ( InStr(Text, "|") >= 0 && (k < 0 || InStr(Text, "|") < k) )
		{
			// word ends right at a line break: keep the "|" for the next round
			k = InStr(Text, "|");
			Word = Left(Text, k);
			Text = Mid(Text, k);
		}
		else if ( k < 0 )
		{
			Word = Text;
			Text = "";
		}
		else
		{
			Word = Left(Text, k);
			Text = Mid(Text, k + 1);
		}
		if ( Line == "" )
			Test = Word;
		else
			Test = Line @ Word;
		TextSize(C, Test, XL, YL);
		if ( XL > MaxW && Line != "" )
		{
			TipLine[n++] = Line;
			Line = Word;
		}
		else
			Line = Test;
	}
	if ( Line != "" && n < 8 )
		TipLine[n++] = Line;
	return n;
}

// mouse-over tooltip with the mutator's description
function AfterPaint(Canvas C, float X, float Y)
{
	local float XL, YL, TY, H, W, VisBottom;
	local int Lines, i;

	Super.AfterPaint(C, X, Y);
	if ( HoverDesc == "" || HoverIdx < 0 )
		return;
	C.Font = Root.Fonts[F_Normal];
	W = WinWidth - 30;   // keep clear of the scroll bar
	TextSize(C, "Wy", XL, YL);
	Lines = WrapTip(C, HoverDesc, W - 16);
	H = Lines * YL + 10;
	// below the mutator, or above it when that would leave the visible area
	VisBottom = WinHeight;
	if ( ParentWindow != None )
		VisBottom = FMin(WinHeight, ParentWindow.WinHeight - WinTop);
	TY = Checks[HoverIdx].WinTop + Checks[HoverIdx].WinHeight + 4;
	if ( TY + H > VisBottom )
		TY = Checks[HoverIdx].WinTop - H - 4;
	C.DrawColor.R = 255; C.DrawColor.G = 255; C.DrawColor.B = 255;
	DrawStretchedTexture(C, 6, TY, W, H, Texture'UMenu.MenuBlack');
	C.DrawColor.R = 255; C.DrawColor.G = 200; C.DrawColor.B = 0;
	DrawStretchedTexture(C, 6, TY, W, 1, Texture'UWindow.WhiteTexture');
	DrawStretchedTexture(C, 6, TY + H - 1, W, 1, Texture'UWindow.WhiteTexture');
	DrawStretchedTexture(C, 6, TY, 1, H, Texture'UWindow.WhiteTexture');
	DrawStretchedTexture(C, 6 + W - 1, TY, 1, H, Texture'UWindow.WhiteTexture');
	C.DrawColor.R = 240; C.DrawColor.G = 240; C.DrawColor.B = 240;
	for ( i = 0; i < Lines; i++ )
		ClipText(C, 14, TY + 5 + i * YL, TipLine[i]);
	C.DrawColor.R = 255; C.DrawColor.G = 255; C.DrawColor.B = 255;
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
			{
				HoverDesc = Descs[i];
				HoverIdx = i;
			}
			else if ( E == DE_MouseLeave && HoverIdx == i )
			{
				HoverDesc = "";
				HoverIdx = -1;
			}
		}
}

defaultproperties
{
	HoverIdx=-1
}
