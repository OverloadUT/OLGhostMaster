/*******************************************************************************
    OLGhostSubNameMessage

    Creation date: 10/04/2004 17:11
    Copyright (c) 2004, Greg Laabs
    <!-- $Id$ -->
*******************************************************************************/

class OLGhostSubNameMessage extends LocalMessage;

var()   localized String    ControllingMessage, GhostsPluralMessage, GhostsSingularMessage, ServingMessage;

static function string GetString(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1, 
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{
    local int NumGhosts;
    
    if(Switch == 0) // "Controlling X Ghosts"
    {
        NumGhosts = OLGhostPlayerReplicationInfo(RelatedPRI_1).NumGhosts;
        if (NumGhosts == 1) // Singular
            return Default.ControllingMessage@NumGhosts@Default.GhostsSingularMessage;
        else // Plural
            return Default.ControllingMessage@NumGhosts@Default.GhostsPluralMessage;
    }
    else if(Switch == 1)
        return Default.ServingMessage@RelatedPRI_2.PlayerName; // "Serving X"
}

static function color GetColor(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1, 
    optional PlayerReplicationInfo RelatedPRI_2
    )
{
    if ( Switch == 0 )
        return class'PlayerNameMessage'.Default.DrawColor;
    else
        return Default.DrawColor;
}

defaultproperties
{
     ControllingMessage = "Controlling"
     GhostsPluralMessage = "ghosts"
     GhostsSingularMessage = "ghost"
     ServingMessage = "Bound to"
     bIsUnique=True
     bIsConsoleMessage=False
     bFadeMessage=True
     Lifetime=2
     DrawColor=(R=0)
     PosY=0.620000
}