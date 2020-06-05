/*******************************************************************************
    OLGhostSquadAI

    Creation date: 06/04/2004 22:56
    Copyright (c) 2004, Greg Laabs
    <!-- $Id$ -->
*******************************************************************************/

class OLGhostSquadAI extends DMSquad;

function PostBeginPlay()
{
    SetTimer(1,true);
}

function Timer()
{
    local Bot M;

    for ( M=SquadMembers; M!=None; M=M.NextSquadMember )
    {
        CheckEnemies(M);
    }
}

function bool SetEnemy( Bot B, Pawn NewEnemy )
{
    local OLGhostGame ghostGame;
    local OLGhostPawn ghostPawn, ghostEnemy;

    ghostGame = OLGhostGame(Level.Game);
    ghostPawn = OLGhostPawn(B.Pawn);
    ghostEnemy = OLGhostPawn(NewEnemy);

    CheckEnemies(B);

    // If this is not a ghost and the enemy is not a ghost, then behave normally.
    if( !ghostPawn.bIsGhost && !ghostEnemy.bIsGhost )
        return Super.SetEnemy(B, NewEnemy);

    if (IsValidEnemy(B,NewEnemy))
    {
        if ( !AddEnemy(NewEnemy) )
            return false;
        else
            return true;
    } else {
        return false;
    }


//    return FindNewEnemyFor(B,(B.Enemy !=None) && B.LineOfSightTo(SquadMembers.Enemy));
}

function CheckEnemies(Bot B)
{
    local int i;
    local OLGhostPawn ghostPawn, ghostEnemy;

    ghostPawn = OLGhostPawn(B.Pawn);

    if (ghostPawn != none)
    {
        for(i=0;i<8;i++)
        {
            ghostEnemy = OLGhostPawn( Enemies[i] );
            if (ghostEnemy == none)
                continue;

            if (!ghostPawn.bIsGhost && !ghostEnemy.bIsGhost)
                continue;

            if ( !IsValidEnemy(B, Enemies[i]) )
                RemoveEnemy(Enemies[i]);
        }
    }
}

function bool IsValidEnemy(Bot B, Pawn Enemy)
{
    local OLGhostGame ghostGame;
    local OLGhostPawn ghostPawn, ghostEnemy;

    ghostGame = OLGhostGame(Level.Game);
    ghostPawn = OLGhostPawn(B.Pawn);
    ghostEnemy = OLGhostPawn(Enemy);

    // If this is this bot's master, then return it can't be an enemy.
    if ( ghostPawn.bIsGhost && ghostPawn.Master == ghostEnemy.controller )
    {
        return false;
    }

    // If this is a ghost and the target is not a ghost, check to see if they have been tagged.
    if( ghostPawn.bIsGhost && !ghostEnemy.bIsGhost )
    {
        if ( !OLGhostPlayerReplicationInfo(OLGhostPlayerReplicationInfo(ghostPawn.PlayerReplicationInfo).Master).IsPlayerTagged(Enemy) )
        {
            return true;
        }
        else
        {
            return false;
        }
    }

    // If the target is a ghost, then it can't be an enemy.
    if( ghostEnemy.bIsGhost )
    {
        return false;
    }

    log("OLGhostSquadAI::IsValidEnemy() reached the end of the function. This is not supposed to happen!");
    return false;
}
