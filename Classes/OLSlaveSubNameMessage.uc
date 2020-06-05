/*******************************************************************************
    OLSlaveSubNameMessage

    Creation date: 10/04/2004 17:11
    Copyright (c) 2004, Greg Laabs
    <!-- $Id$ -->
*******************************************************************************/

class OLSlaveSubNameMessage extends LocalMessage;

var()   localized String    ControllingMessage, SlavesPluralMessage, SlavesSingularMessage, ServingMessage;

static function string GetString(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1, 
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{
    local int NumSlaves;
    
    if(Switch == 0) // "Controlling X Slaves"
    {
        NumSlaves = OLSlavePlayerReplicationInfo(RelatedPRI_1).NumSlaves;
        if (NumSlaves == 1) // Singular
            return Default.ControllingMessage@NumSlaves@Default.SlavesSingularMessage;
        else // Plural
            return Default.ControllingMessage@NumSlaves@Default.SlavesPluralMessage;
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
     SlavesPluralMessage = "slaves"
     SlavesSingularMessage = "slave"
     ServingMessage = "Serving"
     bIsUnique=True
     bIsConsoleMessage=False
     bFadeMessage=True
     Lifetime=2
     DrawColor=(R=0)
     PosY=0.620000
}