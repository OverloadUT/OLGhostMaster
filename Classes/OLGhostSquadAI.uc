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
    local OLGhostGame slaveGame;
    local OLGhostPawn slavePawn, slaveEnemy;

    slaveGame = OLGhostGame(Level.Game);
    slavePawn = OLGhostPawn(B.Pawn);
    slaveEnemy = OLGhostPawn(NewEnemy);

    CheckEnemies(B);

    // If this is not a slave and the enemy is not a slave, then behave normally.
    if( !slavePawn.bIsSlave && !slaveEnemy.bIsSlave )
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
    local OLGhostPawn slavePawn, slaveEnemy;

    slavePawn = OLGhostPawn(B.Pawn);

    if (slavePawn != none)
    {
        for(i=0;i<8;i++)
        {
            slaveEnemy = OLGhostPawn( Enemies[i] );
            if (slaveEnemy == none)
                continue;

            if (!slavePawn.bIsSlave && !slaveEnemy.bIsSlave)
                continue;

            if ( !IsValidEnemy(B, Enemies[i]) )
                RemoveEnemy(Enemies[i]);
        }
    }
}

function bool IsValidEnemy(Bot B, Pawn Enemy)
{
    local OLGhostGame slaveGame;
    local OLGhostPawn slavePawn, slaveEnemy;

    slaveGame = OLGhostGame(Level.Game);
    slavePawn = OLGhostPawn(B.Pawn);
    slaveEnemy = OLGhostPawn(Enemy);

    // If this is this bot's master, then return it can't be an enemy.
    if ( slavePawn.bIsSlave && slavePawn.Master == slaveEnemy.controller )
    {
        return false;
    }

    // If this is a slave and the target is not a slave, check to see if they have been tagged.
    if( slavePawn.bIsSlave && !slaveEnemy.bIsSlave )
    {
        if ( !OLGhostPlayerReplicationInfo(OLGhostPlayerReplicationInfo(slavePawn.PlayerReplicationInfo).Master).IsPlayerTagged(Enemy) )
        {
            return true;
        }
        else
        {
            return false;
        }
    }

    // If the target is a slave, then it can't be an enemy.
    if( slaveEnemy.bIsSlave )
    {
        return false;
    }

    log("OLGhostSquadAI::IsValidEnemy() reached the end of the function. This is not supposed to happen!");
    return false;
}
