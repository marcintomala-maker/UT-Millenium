//=============================================================================
// UTMDominationHUD - the original Domination HUD, but the control point
// icons are squeezed to fit between the chat messages and the bottom HUD,
// so they don't cover the messages on 1080p / laptop screens.
//=============================================================================
class UTMDominationHUD extends ChallengeDominationHUD;

simulated function PostRender( canvas Canvas )
{
	local int Count;
	local float X, Y, Top, Bottom, Step, IconScale, XL, YL;
	local ControlPoint CP;
	local NavigationPoint N;
	local Texture CPTexture;

	Super(ChallengeTeamHUD).PostRender( Canvas );

	if ( bHideHud
		|| ((Canvas.ClipX <= 400) && ((PlayerPawn(Owner).bShowScores) || bForceScores)) )
		return;
	if ( TournamentConsole(PlayerPawn(Owner).Player.Console) != None
		&& TournamentConsole(PlayerPawn(Owner).Player.Console).bShowSpeech )
		return;

	for ( N = Level.NavigationPointList; N != None; N = N.NextNavigationPoint )
		if ( N.IsA('ControlPoint') )
			Count++;
	if ( Count == 0 )
		return;

	// original layout: first icon at ClipY - 384*Scale, then 140*Scale apart, upwards
	Bottom = Canvas.ClipY - 384 * Scale;
	Top = Canvas.ClipY * 0.30;        // keep clear of the message area
	Step = 140 * Scale;
	if ( Count > 1 && Bottom - Step * (Count - 1) < Top )
		Step = FMax((Bottom - Top) / (Count - 1), 40);
	IconScale = Scale * FMin(1.0, Step / (140 * Scale));

	X = 0;
	Y = Bottom;
	Canvas.Style = Style;
	Canvas.Font = MyFonts.GetSmallFont( Canvas.ClipX );
	for ( N = Level.NavigationPointList; N != None; N = N.NextNavigationPoint )
		if ( N.IsA('ControlPoint') )
		{
			CP = ControlPoint(N);
			if ( CP.ControllingTeam != None )
				CPTexture = TeamIcon[CP.ControllingTeam.TeamIndex];
			else
				CPTexture = texture'I_TeamN';
			Canvas.DrawColor = BaseColor;
			Canvas.SetPos(X, Y + 96 * (Scale - IconScale));
			Canvas.DrawIcon(CPTexture, IconScale);

			if ( CP.ControllingTeam != None )
				Canvas.DrawColor = TeamColor[CP.ControllingTeam.TeamIndex];
			else
				Canvas.DrawColor = WhiteColor;
			Canvas.StrLen(CP.PointName, XL, YL);
			Canvas.SetPos(0, Y + 96 * Scale - YL);
			Canvas.DrawText(CP.PointName);
			Y -= Step;
		}
}

// The original stacks the team scores 128 units apart, upwards from near the
// bottom. With 3-4 teams on a widescreen that runs into the status doll in
// the top right corner, so squeeze the stack to fit below it.
simulated function DrawTeam(Canvas Canvas, TeamInfo TI)
{
	local float XL, YL, Bottom, Top, Step, IconScale, Y;
	local int i, N, Slot;
	local TournamentGameReplicationInfo GRI;

	if ( TI == None || TI.Size <= 0 )
		return;
	GRI = TournamentGameReplicationInfo(PlayerPawn(Owner).GameReplicationInfo);
	N = 0;
	Slot = 0;
	for ( i = 0; i < 4; i++ )
		if ( GRI != None && GRI.Teams[i] != None && GRI.Teams[i].Size > 0 )
		{
			if ( GRI.Teams[i] == TI )
				Slot = N;
			N++;
		}
	N = Max(N, 1);

	Bottom = Canvas.ClipY - 336 * Scale;
	Top = 200 * Scale;                 // below the status doll
	Step = 128 * Scale;
	if ( N > 1 && Bottom - Step * (N - 1) < Top )
		Step = FMax((Bottom - Top) / (N - 1), 24);
	IconScale = Scale * FMin(1.0, Step / (72 * Scale));
	Y = Bottom - Step * Slot;

	Canvas.Font = MyFonts.GetHugeFont( Canvas.ClipX );
	if ( IconScale < Scale * 0.8 )
		Canvas.Font = MyFonts.GetBigFont( Canvas.ClipX );
	Canvas.DrawColor = TeamColor[TI.TeamIndex];
	Canvas.SetPos(Canvas.ClipX - 64 * IconScale, Y);
	Canvas.DrawIcon(TeamIcon[TI.TeamIndex], IconScale);
	Canvas.StrLen(int(TI.Score), XL, YL);
	Canvas.SetPos(Canvas.ClipX - XL - 66 * IconScale, Y + ((64 * IconScale) - YL) / 2);
	Canvas.DrawText(int(TI.Score), false);
}

defaultproperties
{
}
