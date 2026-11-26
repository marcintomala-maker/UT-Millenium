//=============================================================================
// UTMTeamHUD - Team Deathmatch HUD with room for 3 and 4 teams.
//=============================================================================
class UTMTeamHUD extends ChallengeTeamHUD;

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
