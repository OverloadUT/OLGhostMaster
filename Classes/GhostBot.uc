/*******************************************************************************
    GhostBot

    Creation date: 06/04/2004 20:42
    Copyright (c) 2004, Greg Laabs
    <!-- $Id$ -->
*******************************************************************************/

class GhostBot extends xBot;

event float Desireability(Pickup P)
{
    if ( OLGhostPawn(Pawn).bIsGhost )
        return P.BotDesireability(OLGhostPawn(Pawn).Master.Pawn);
    return Super.Desireability(P);
}

event float SuperDesireability(Pickup P)
{
    if ( OLGhostPawn(Pawn).bIsGhost )
        return P.BotDesireability(OLGhostPawn(Pawn).Master.Pawn);
    return Super.SuperDesireability(P);
}

function float AdjustAimError(float aimerror, float TargetDist, bool bDefendMelee, bool bInstantProj, bool bLeadTargetNow )
{
    local float AdjustedError;

    AdjustedError = Super.AdjustAimError(aimerror, TargetDist, bDefendMelee, bInstantProj, bLeadTargetNow);

    // Greatly increase the bot's accuracy if his target has been tagged.
    if( Pawn(Target) != none && OLGhostPlayerReplicationInfo(PlayerReplicationInfo).IsPlayerTagged(Pawn(Target)) )
    {
        AdjustedError *= 0.4;
    }

    return AdjustedError;
}
