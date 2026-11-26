//=============================================================================
// UTMCreditsCW - everybody who made this possible.
// The Unreal Tournament team credits are the original credit "cards" from
// the game's own credits map (credits.utx).
//=============================================================================
class UTMCreditsCW extends UWindowDialogClientWindow;

// Kind: 0 = big heading, 1 = small heading, 2 = text, 3 = image, 4 = gap
var int    Kind[64];
var string Line[64];
var int    NumLines;
var Texture Pics[8];

function Add(int K, string S)
{
	if ( NumLines >= 64 )
		return;
	Kind[NumLines] = K;
	Line[NumLines] = S;
	NumLines++;
}

function Created()
{
	Super.Created();

	Add(0, "UT MILLENIUM");
	Add(1, "Idea and Mod Design");
	Add(2, "Marcin Tomala");
	Add(4, "");

	Add(0, "OLDUNREAL PATCH 469e");
	Add(2, "The community patch that makes UT run well on Windows 11.");
	Add(1, "Primary developers");
	Add(2, "AnthraX, Higor, Buggie, Dots, Smirftsch");
	Add(1, "Testers and contributors");
	Add(2, "Chamberly, Casey, Ooper, Feralidragon, Berserker, Che, Sizzl, Lightning, batonix, ue, Zim, uZi, zkyp, the UTCTF.pug community, Sp0ngeb0b, proasm, Deepu, Eternity, Dizzy, NuLL, Deaod, Metallicafan212, dpJudas, Masterkent, rX");
	Add(1, "Special thanks");
	Add(2, "Stacey Conley (Flak), Ryan C. Gordon (icculus), Chris Dohnal (UTGLR OpenGL and Direct3D 9 renderers)");
	Add(1, "Third-party libraries in the patch");
	Add(2, "OpenAL Soft (kcat), mpg123 (Michael Hipp and others), libogg (Xiph.Org Foundation), libxmp, libsndfile, FMOD, musl libc (Rich Felker), SDL2 and SDL2_ttf (Sam Lantinga and others)");
	Add(4, "");

	Add(0, "UNREAL TOURNAMENT");
	Add(2, "Game of the Year Edition. Developed by Epic Games and Digital Extremes. (c) 1999, 2000 Epic Games, Inc.");
	Add(3, "credits.Wall.Credit_1");
	Add(3, "credits.Wall.Credit_2");
	Add(3, "credits.Wall.Credit_3");
	Add(3, "credits.Wall.Credit_4");
	Add(3, "credits.Wall.Credit_5");
	Add(3, "credits.Wall.Credit_6");
	Add(4, "");

	Add(2, "Unreal and Unreal Tournament are trademarks of Epic Games, Inc. UT Millenium is a free fan mod. It needs your own copy of Unreal Tournament and is not made or endorsed by Epic Games.");
	Add(4, "");

	Add(1, "Mod Programming");
	Add(2, "Claude (Anthropic)");

	DesiredWidth = 300;
	DesiredHeight = 2000;
}

function Paint(Canvas C, float X, float Y)
{
	local int i;
	local float CY, XL, YL, Sz;
	local Texture T;

	DrawStretchedTexture(C, 0, 0, WinWidth, WinHeight, Texture'UMenu.MenuBlack');
	CY = 10;
	for ( i = 0; i < NumLines; i++ )
	{
		switch ( Kind[i] )
		{
		case 0:
			C.Font = class'UTMMainWindow'.static.PickFont(Root, 18);
			C.DrawColor.R = 255; C.DrawColor.G = 190; C.DrawColor.B = 0;
			TextSize(C, Line[i], XL, YL);
			ClipText(C, (WinWidth - XL) / 2, CY, Line[i]);
			CY += YL + 6;
			break;
		case 1:
			C.Font = Root.Fonts[F_Bold];
			C.DrawColor.R = 90; C.DrawColor.G = 150; C.DrawColor.B = 255;
			TextSize(C, Line[i], XL, YL);
			ClipText(C, (WinWidth - XL) / 2, CY, Line[i]);
			CY += YL + 2;
			break;
		case 2:
			C.Font = Root.Fonts[F_Normal];
			C.DrawColor.R = 220; C.DrawColor.G = 220; C.DrawColor.B = 220;
			TextSize(C, "Wy", XL, YL);
			CY += YL * WrapClipText(C, 12, CY, Line[i]) + 6;
			break;
		case 3:
			T = Texture(DynamicLoadObject(Line[i], class'Texture'));
			if ( T != None )
			{
				Sz = FMin(WinWidth - 40, 200);
				C.DrawColor.R = 255; C.DrawColor.G = 255; C.DrawColor.B = 255;
				DrawStretchedTexture(C, (WinWidth - Sz) / 2, CY, Sz, Sz, T);
				CY += Sz + 4;
			}
			break;
		case 4:
			CY += 14;
			break;
		}
	}
	C.DrawColor.R = 255; C.DrawColor.G = 255; C.DrawColor.B = 255;
	DesiredHeight = CY + 10;
}

defaultproperties
{
}
