/*******************************************************************************
    OLGhostScoreboard

    Creation date: 15/04/2004 17:51
    Copyright (c) 2004, Greg Laabs
    <!-- $Id$ -->
*******************************************************************************/

class OLGhostScoreboard extends ScoreBoardDeathMatch;

var localized string GhostsText, GhostText;
var plane FullOn, GrayedOut;


simulated event UpdateScoreBoard(Canvas Canvas)
{
    local PlayerReplicationInfo PRI, OwnerPRI;
    local int i, FontReduction, OwnerPos, NetXPos, PlayerCount,HeaderOffsetY,HeadFoot, MessageFoot, PlayerBoxSizeY, BoxSpaceY, NameXPos, BoxTextOffsetY, OwnerOffset, ScoreXPos, DeathsXPos, BoxXPos, TitleYPos, BoxWidth;
    local float XL,YL, MaxScaling;
    local float deathsXL, scoreXL, netXL, MaxNamePos;
    local string playername[MAXPLAYERS];
    local bool bNameFontReduction;
    local plane OldColorModulate;
    local int numghosts;


    OldColorModulate = Canvas.ColorModulate;

    OwnerPRI = PlayerController(Owner).PlayerReplicationInfo;
    for (i=0; i<GRI.PRIArray.Length; i++)
    {
        PRI = GRI.PRIArray[i];
        if ( !PRI.bOnlySpectator && (!PRI.bIsSpectator || PRI.bWaitingPlayer) )
        {
            if ( PRI == OwnerPRI )
                OwnerOffset = i;
            PlayerCount++;
        }
    }
    PlayerCount = Min(PlayerCount,MAXPLAYERS);

    // Select best font size and box size to fit as many players as possible on screen
    Canvas.Font = HUDClass.static.GetMediumFontFor(Canvas);
    Canvas.StrLen("Test", XL, YL);
    BoxSpaceY = 0.25 * YL;
    PlayerBoxSizeY = 1.5 * YL;
    HeadFoot = 5*YL;
    MessageFoot = 1.5 * HeadFoot;
    if ( PlayerCount > (Canvas.ClipY - 1.5 * HeadFoot)/(PlayerBoxSizeY + BoxSpaceY) )
    {
        BoxSpaceY = 0.125 * YL;
        PlayerBoxSizeY = 1.25 * YL;
        if ( PlayerCount > (Canvas.ClipY - 1.5 * HeadFoot)/(PlayerBoxSizeY + BoxSpaceY) )
        {
            if ( PlayerCount > (Canvas.ClipY - 1.5 * HeadFoot)/(PlayerBoxSizeY + BoxSpaceY) )
                PlayerBoxSizeY = 1.125 * YL;
            if ( PlayerCount > (Canvas.ClipY - 1.5 * HeadFoot)/(PlayerBoxSizeY + BoxSpaceY) )
            {
                FontReduction++;
                Canvas.Font = GetSmallerFontFor(Canvas,FontReduction);
                Canvas.StrLen("Test", XL, YL);
                BoxSpaceY = 0.125 * YL;
                PlayerBoxSizeY = 1.125 * YL;
                HeadFoot = 5*YL;
                if ( PlayerCount > (Canvas.ClipY - HeadFoot)/(PlayerBoxSizeY + BoxSpaceY) )
                {
                    FontReduction++;
                    Canvas.Font = GetSmallerFontFor(Canvas,FontReduction);
                    Canvas.StrLen("Test", XL, YL);
                    BoxSpaceY = 0.125 * YL;
                    PlayerBoxSizeY = 1.125 * YL;
                    HeadFoot = 5*YL;
                    if ( (Canvas.ClipY >= 768) && (PlayerCount > (Canvas.ClipY - HeadFoot)/(PlayerBoxSizeY + BoxSpaceY)) )
                    {
                        FontReduction++;
                        Canvas.Font = GetSmallerFontFor(Canvas,FontReduction);
                        Canvas.StrLen("Test", XL, YL);
                        BoxSpaceY = 0.125 * YL;
                        PlayerBoxSizeY = 1.125 * YL;
                        HeadFoot = 5*YL;
                    }
                }
            }
        }
    }
    if ( Canvas.ClipX < 512 )
        PlayerCount = Min(PlayerCount, 1+(Canvas.ClipY - HeadFoot)/(PlayerBoxSizeY + BoxSpaceY) );
    else
        PlayerCount = Min(PlayerCount, (Canvas.ClipY - HeadFoot)/(PlayerBoxSizeY + BoxSpaceY) );
    if ( OwnerOffset >= PlayerCount )
        PlayerCount -= 1;

    if ( FontReduction > 2 )
        MaxScaling = 3;
    else
        MaxScaling = 2.125;
    PlayerBoxSizeY = FClamp((1+(Canvas.ClipY - 0.67 * MessageFoot))/PlayerCount - BoxSpaceY, PlayerBoxSizeY, MaxScaling * YL);

    bDisplayMessages = (PlayerCount <= (Canvas.ClipY - MessageFoot)/(PlayerBoxSizeY + BoxSpaceY));
    HeaderOffsetY = 3 * YL;
    BoxWidth = 0.9375 * Canvas.ClipX;
    BoxXPos = 0.5 * (Canvas.ClipX - BoxWidth);
    BoxWidth = Canvas.ClipX - 2*BoxXPos;
    NameXPos = BoxXPos + 0.0625 * BoxWidth;
    ScoreXPos = BoxXPos + 0.5 * BoxWidth;
    DeathsXPos = BoxXPos + 0.6875 * BoxWidth;
    NetXPos = BoxXPos + 0.8125 * BoxWidth;

    // draw background boxes
    Canvas.Style = ERenderStyle.STY_Alpha;
    Canvas.DrawColor = HUDClass.default.WhiteColor * 0.5;
    for ( i=0; i<PlayerCount; i++ )
    {
        // Only draw boxes for non-ghosts - Ghosts are drawn inside their master's box
        if( !OLGhostPlayerReplicationInfo(GRI.PRIArray[i]).bIsGhost )
        {
            numghosts = OLGhostPlayerReplicationInfo(GRI.PRIArray[i]).numghosts;
            // Make sure ghostmasters at the very bottom of the don't draw a box too large

            numghosts = min(numghosts,playercount - i - 1 );
            Canvas.SetPos(BoxXPos, HeaderOffsetY + (PlayerBoxSizeY + BoxSpaceY)*i);
            Canvas.DrawTileStretched( BoxMaterial, BoxWidth, (PlayerBoxSizeY * (numghosts + 1) ) + (BoxSpaceY * numghosts ) );
        }
    }
    Canvas.Style = ERenderStyle.STY_Translucent;

    // draw title
    Canvas.Style = ERenderStyle.STY_Normal;
    DrawTitle(Canvas, HeaderOffsetY, (PlayerCount+1)*(PlayerBoxSizeY + BoxSpaceY), PlayerBoxSizeY);

    // Draw headers
    TitleYPos = HeaderOffsetY - 1.25*YL;
    Canvas.StrLen(PointsText, ScoreXL, YL);
    Canvas.StrLen(GhostsText, DeathsXL, YL);

    Canvas.DrawColor = HUDClass.default.WhiteColor;
    Canvas.SetPos(NameXPos, TitleYPos);
    Canvas.DrawText(PlayerText,true);
    Canvas.SetPos(ScoreXPos - 0.5*ScoreXL, TitleYPos);
    Canvas.DrawText(PointsText,true);
    Canvas.SetPos(DeathsXPos - 0.5*DeathsXL, TitleYPos);
    Canvas.DrawText(GhostsText,true);

    // draw player names
    MaxNamePos = 0.9 * (ScoreXPos - NameXPos);
    for ( i=0; i<PlayerCount; i++ )
    {
        playername[i] = GRI.PRIArray[i].PlayerName;
        Canvas.StrLen(playername[i], XL, YL);
        if ( XL > MaxNamePos )
        {
            bNameFontReduction = true;
            break;
        }
    }
    if ( !bNameFontReduction && (OwnerOffset >= PlayerCount) )
    {
        playername[OwnerOffset] = GRI.PRIArray[OwnerOffset].PlayerName;
        Canvas.StrLen(playername[OwnerOffset], XL, YL);
        if ( XL > MaxNamePos )
            bNameFontReduction = true;
    }

    if ( bNameFontReduction )
        Canvas.Font = GetSmallerFontFor(Canvas,FontReduction+1);
    for ( i=0; i<PlayerCount; i++ )
    {
        playername[i] = GRI.PRIArray[i].PlayerName;
        Canvas.StrLen(playername[i], XL, YL);
        if ( XL > MaxNamePos )
            playername[i] = left(playername[i], MaxNamePos/XL * len(PlayerName[i]));
    }
    if ( OwnerOffset >= PlayerCount )
    {
        playername[OwnerOffset] = GRI.PRIArray[OwnerOffset].PlayerName;
        Canvas.StrLen(playername[OwnerOffset], XL, YL);
        if ( XL > MaxNamePos )
            playername[OwnerOffset] = left(playername[OwnerOffset], MaxNamePos/XL * len(PlayerName[OwnerOffset]));
    }

    Canvas.Style = ERenderStyle.STY_Normal;
    Canvas.DrawColor = HUDClass.default.WhiteColor;
    Canvas.SetPos(0.5 * Canvas.ClipX, HeaderOffsetY + 4);
    BoxTextOffsetY = HeaderOffsetY + 0.5 * (PlayerBoxSizeY - YL);

    Canvas.DrawColor = HUDClass.default.WhiteColor;
    for ( i=0; i<PlayerCount; i++ )
        if ( i != OwnerOffset )
        {
            if ( OLGhostPlayerReplicationInfo(GRI.PRIArray[i]).bIsGhost )
            {
                Canvas.SetPos(NameXPos + 0.02 * BoxWidth, (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY);
                Canvas.ColorModulate = GrayedOut;
            }
            else
            {
                Canvas.SetPos(NameXPos, (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY);
                Canvas.ColorModulate = FullOn;
            }

            Canvas.DrawText(playername[i],true);
        }
    if ( bNameFontReduction )
        Canvas.Font = GetSmallerFontFor(Canvas,FontReduction);

    // draw scores
    Canvas.DrawColor = HUDClass.default.WhiteColor;
    for ( i=0; i<PlayerCount; i++ )
        if ( i != OwnerOffset )
        {
            if ( OLGhostPlayerReplicationInfo(GRI.PRIArray[i]).bIsGhost )
                Canvas.ColorModulate = GrayedOut;
            else
                Canvas.ColorModulate = FullOn;

            Canvas.SetPos(ScoreXPos, (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY);
            Canvas.DrawText(int(GRI.PRIArray[i].Score),true);
        }

    // draw number of ghosts
    Canvas.DrawColor = HUDClass.default.WhiteColor;
    for ( i=0; i<PlayerCount; i++ )
        if ( i != OwnerOffset )
        {
            if ( OLGhostPlayerReplicationInfo(GRI.PRIArray[i]).bIsGhost )
            {
                Canvas.ColorModulate = GrayedOut;
                Canvas.StrLen(GhostText,Xl,Yl);
                Canvas.SetPos(DeathsXPos - (XL/2), (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY);
                Canvas.DrawText(GhostText,true);
            }
            else
            {
                Canvas.ColorModulate = FullOn;
                Canvas.SetPos(DeathsXPos, (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY);
                Canvas.DrawText( OLGhostPlayerReplicationInfo(GRI.PRIArray[i]).numghosts ,true);
            }
        }

    // If the owner is too low on the list, he gets a special line
    // draw owner line
    if ( OwnerOffset >= PlayerCount )
    {
        OwnerPos = (PlayerBoxSizeY + BoxSpaceY)*PlayerCount + BoxTextOffsetY;
        // draw extra box
        Canvas.Style = ERenderStyle.STY_Alpha;
        Canvas.DrawColor = HUDClass.default.TurqColor * 0.5;
        Canvas.SetPos(BoxXPos, HeaderOffsetY + (PlayerBoxSizeY + BoxSpaceY)*PlayerCount);
        Canvas.DrawTileStretched( BoxMaterial, BoxWidth, PlayerBoxSizeY);
        Canvas.Style = ERenderStyle.STY_Normal;
    }
    else
        OwnerPos = (PlayerBoxSizeY + BoxSpaceY)*OwnerOffset + BoxTextOffsetY;

    if ( OLGhostPlayerReplicationInfo(GRI.PRIArray[OwnerOffset]).bIsGhost )
    {
        Canvas.SetPos(NameXPos + 0.02 * BoxWidth, OwnerPos);
        Canvas.ColorModulate = GrayedOut;
    }
    else
    {
        Canvas.SetPos(NameXPos, OwnerPos);
        Canvas.ColorModulate = FullOn;
    }

    Canvas.DrawColor = HUDClass.default.GoldColor;

    if ( bNameFontReduction )
        Canvas.Font = GetSmallerFontFor(Canvas,FontReduction+1);
    Canvas.DrawText(playername[OwnerOffset],true);
    if ( bNameFontReduction )
        Canvas.Font = GetSmallerFontFor(Canvas,FontReduction);
    Canvas.SetPos(ScoreXPos, OwnerPos);
    Canvas.DrawText(int(GRI.PRIArray[OwnerOffset].Score),true);


    // Ghost indicator
    if ( OLGhostPlayerReplicationInfo(GRI.PRIArray[OwnerOffset]).bIsGhost )
    {
        Canvas.StrLen(GhostText,Xl,Yl);
        Canvas.SetPos(DeathsXPos-(XL/2), OwnerPos);
        Canvas.DrawText(GhostText,true);
    }
    else
    {
        Canvas.SetPos(DeathsXPos, OwnerPos);
        Canvas.DrawText( OLGhostPlayerReplicationInfo(GRI.PRIArray[OwnerOffset]).numghosts ,true);
    }

    if ( Level.NetMode == NM_Standalone )
        return;

    Canvas.StrLen(NetText, NetXL, YL);
    Canvas.DrawColor = HUDClass.default.WhiteColor;
    Canvas.SetPos(NetXPos + 0.5*NetXL, TitleYPos);
    Canvas.DrawText(NetText,true);

    for ( i=0; i<GRI.PRIArray.Length; i++ )
        PRIArray[i] = GRI.PRIArray[i];
    DrawNetInfo(Canvas,FontReduction,HeaderOffsetY,PlayerBoxSizeY,BoxSpaceY,BoxTextOffsetY,OwnerOffset,PlayerCount,NetXPos);
    DrawMatchID(Canvas,FontReduction);
}


// false means P2 is higher, true means P1 is higher (or a tie)
simulated function bool InOrder( PlayerReplicationInfo P1, PlayerReplicationInfo P2 )
{
    local OLGhostPlayerReplicationInfo P1S, P2S;
    local int p1i, p2i, i;

    P1S = OLGhostPlayerReplicationInfo(P1);
    P2S = OLGhostPlayerReplicationInfo(P2);

    if( P1.bOnlySpectator )
    {
        if( P2.bOnlySpectator )
            return true;
        else
            return false;
    }
    else if ( P2.bOnlySpectator )
        return true;

    // If P2 is P1's master, then P1 goes below P2.
    if (P1S.bIsGhost && !P2S.bIsGhost && P1S.Master != none && P1S.Master == P2S)
    {
        return false;
    }
    // Also, if P1 is P2's master, then P2 goes below P1.
    if (P2S.bIsGhost && !P1S.bIsGhost && P2S.Master != none && P2S.Master == P1S)
    {
        return true;
    }

    // If P1 is a ghost and P2 is not, check to see if P1's master is better than P2.
    if (P1S.bIsGhost && !P2S.bIsGhost && P1S.Master != none && !InOrder(P1S.Master, P2) )
    {
        return false;
    }

    // If P2 is a ghost and P1 is not, check to see if P2's master is better than P1
    if (P2S.bIsGhost && !P1S.bIsGhost && P2S.Master != none && !InOrder(P1, P2S.Master) )
    {
        return false;
    }

    // If they're both ghosts, check their masters.
    if (P1S.bIsGhost && P2S.bIsGhost && P1S.Master != none && P2S.Master != none && P1S.Master != P2S.Master && !InOrder(P1S.Master, P2S.Master) )
    {
        return false;
    }

    // If they're both ghosts and have the same master, check scores.
    if (P1S.bIsGhost && P2S.bIsGhost && P1S.Master != none && P2S.Master != none && P1S.Master == P2S.Master )
    {
        if (P2.Score > P1.Score)
        {
            return false;
        }
        else if (P1.Score == P2.Score)
        {
            if (P2.Deaths < P1.Deaths)
            {
                return false;
            }
            else if (P1.Deaths == P2.Deaths && (PlayerController(P2.Owner) != None) && (Viewport(PlayerController(P2.Owner).Player) != None) )
            {
                return false;
            }
        }
    }

    // If they're both not ghosts, compare number of ghosts, then score, then deaths
    if (!P1S.bIsGhost && !P2S.bIsGhost)
    {
        // No longer sorting by number of ghosts - if a player wins by capturing
        // everyone, he'll be on top anyway because ghosts go below a their
        // master.

        if (P2.Score > P1.Score)
            return false;
        else if (P1.Score == P2.Score)
        {
            if (P2.Deaths < P1.Deaths)
                return false;
            else if (P1.Deaths == P2.Deaths && (PlayerController(P2.Owner) != None) && (Viewport(PlayerController(P2.Owner).Player) != None) )
                return false;

            // Last resort: Return whatever is currently true...
            for (i=0;i<GRI.PRIArray.Length;i++)
            {
                if ( GRI.PRIArray[i] == P1 )
                    P1i = i;
                else if ( GRI.PRIArray[i] == P2 )
                    P2i = i;
            }
            if (P2i < P1i)
                return false;
        }
    }

    return true;
}

defaultproperties
{
     GhostsText="GHOSTS"
     GhostText="GHOST"
     FullOn=(W=1.000000,X=1.000000,Y=1.000000,Z=1.000000)
     GrayedOut=(W=0.750000,X=0.750000,Y=0.750000,Z=0.750000)
}
