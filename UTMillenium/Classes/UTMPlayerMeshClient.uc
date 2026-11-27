//=============================================================================
// UTMPlayerMeshClient - character preview with modern controls:
// press and hold + drag to rotate, mouse wheel to zoom in on the face.
//=============================================================================
class UTMPlayerMeshClient extends UMenuPlayerMeshClient;

var bool  bDragging;
var float LastDragX;
var float Zoom;        // 0 = whole body, 1 = face
var float ZoomGoal;
var name  IdleAnim;
var localized string HintText;

function Created()
{
	Super.Created();
	// the old click-left/click-right/click-centre areas and the Face button
	// are replaced by drag and mouse wheel
	CenterButton.HideWindow();
	LeftButton.HideWindow();
	RightButton.HideWindow();
	FaceButton.HideWindow();
}

function Resized()
{
	Super.Resized();
}

function BeforePaint(Canvas C, float X, float Y)
{
}

function Paint(Canvas C, float X, float Y)
{
	local float OldFov, XL, YL, Dist;
	local vector Offset;

	DrawStretchedTexture(C, 0, 0, WinWidth, WinHeight, Texture'UMenu.MenuBlack');

	if ( MeshActor != None )
	{
		OldFov = GetPlayerOwner().FOVAngle;
		GetPlayerOwner().SetFOVAngle(30);
		// DrawClippedActor puts the model at a distance where the view is
		// 10 units high. Zooming moves it closer (up to ~3.3x) and lowers it
		// so the face ends up in the middle.
		Dist = 5.0 * (WinWidth / FMax(WinHeight, 1)) / 0.2679;
		Offset = vect(0, 0, 0);
		Offset.X = -0.70 * Dist * Zoom;
		Offset.Z = -3.3 * Zoom;
		DrawClippedActor(C, WinWidth / 2, WinHeight / 2, MeshActor, False, ViewRotator, Offset);
		GetPlayerOwner().SetFOVAngle(OldFov);
	}

	C.Font = Root.Fonts[F_Normal];
	C.DrawColor.R = 150; C.DrawColor.G = 150; C.DrawColor.B = 150;
	TextSize(C, HintText, XL, YL);
	ClipText(C, (WinWidth - XL) / 2, WinHeight - YL - 3, HintText);
	C.DrawColor.R = 255; C.DrawColor.G = 255; C.DrawColor.B = 255;
}

function Tick(float Delta)
{
	// smooth zoom
	if ( Abs(ZoomGoal - Zoom) < 0.01 )
		Zoom = ZoomGoal;
	else
		Zoom += (ZoomGoal - Zoom) * FMin(1.0, Delta * 10.0);
}

function LMouseDown(float X, float Y)
{
	Super(UWindowDialogClientWindow).LMouseDown(X, Y);
	bDragging = true;
	LastDragX = X;
}

function LMouseUp(float X, float Y)
{
	Super(UWindowDialogClientWindow).LMouseUp(X, Y);
	bDragging = false;
}

function MouseMove(float X, float Y)
{
	Super(UWindowDialogClientWindow).MouseMove(X, Y);
	if ( bDragging )
	{
		if ( !bMouseDown )
			bDragging = false;
		else
		{
			ViewRotator.Yaw -= int((X - LastDragX) * 220);
			LastDragX = X;
		}
	}
}

// UWindow sends both events for every notch; the "up" one carries the
// direction (negative = wheel rolled forward).
function bool MouseWheelDown(float ScrollDelta)
{
	return true;
}

function bool MouseWheelUp(float ScrollDelta)
{
	if ( ScrollDelta < 0 )
		ZoomGoal = FMin(1.0, ZoomGoal + 0.25);
	else if ( ScrollDelta > 0 )
		ZoomGoal = FMax(0.0, ZoomGoal - 0.25);
	return true;
}

//-----------------------------------------------------------------------------
// Idle animation: not every model has the 'Breath3' the original expects.

function name PickIdle()
{
	local name Cands[8];
	local int i;

	Cands[0] = 'Breath3';
	Cands[1] = 'Breath1';
	Cands[2] = 'Breath2';
	Cands[3] = 'Breath';
	Cands[4] = 'Breath1L';
	Cands[5] = 'Idle';
	Cands[6] = 'Look';
	Cands[7] = 'Breathe';
	if ( MeshActor == None || MeshActor.Mesh == None )
		return '';
	for ( i = 0; i < 8; i++ )
		if ( MeshActor.HasAnim(Cands[i]) )
			return Cands[i];
	return '';
}

function SetMesh(mesh NewMesh)
{
	MeshActor.bMeshEnviroMap = False;
	MeshActor.DrawType = DT_Mesh;
	MeshActor.Mesh = NewMesh;
	IdleAnim = PickIdle();
	if ( IdleAnim != '' )
		MeshActor.LoopAnim(IdleAnim, 0.5);
}

function AnimEnd(MeshActor MyMesh)
{
	if ( IdleAnim != '' && MyMesh.HasAnim(IdleAnim) )
		MyMesh.LoopAnim(IdleAnim, 0.5);
}

defaultproperties
{
	HintText="Drag to rotate - mouse wheel to zoom"
}
