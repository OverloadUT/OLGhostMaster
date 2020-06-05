/*******************************************************************************
    OLGhostMutator

    Creation date: 10/04/2004 16:38
    Copyright (c) 2004, Greg Laabs
    <!-- $Id$ -->
*******************************************************************************/

class OLGhostMutator extends DMMutator
    HideDropDown
    CacheExempt;

function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
    if (Controller(Other) != None && MessagingSpectator(Other) == None)
    {
        Controller(Other).PlayerReplicationInfoClass = class'OLGhostPlayerReplicationInfo';
    }

    return true;
}

defaultproperties
{
}