/*******************************************************************************
    OLGhostNameMessage

    Creation date: 09/04/2004 22:02
    Copyright (c) 2004, Greg Laabs
    <!-- $Id$ -->
*******************************************************************************/

class OLGhostNameMessage extends LocalMessage;

var()   localized String    GhostMessage;

static function string GetString(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1, 
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{
    if(Switch == 0)
        return RelatedPRI_1.PlayerName;
    else if(Switch == 1)
        return Default.GhostMessage@RelatedPRI_1.PlayerName;
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
     GhostMessage="Ghost"
     bIsUnique=True
     bIsConsoleMessage=False
     bFadeMessage=True
     Lifetime=2
     DrawColor=(R=0)
     PosY=0.580000
}