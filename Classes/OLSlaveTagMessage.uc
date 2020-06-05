/*******************************************************************************
    OLSlaveTagMessage

    Creation date: 15/04/2004 22:40
    Copyright (c) 2004, Greg Laabs
    <!-- $Id$ -->
*******************************************************************************/

class OLSlaveTagMessage extends LocalMessage;

var() sound YouAreTaggedSound;
var() localized string YouAreTaggedMessage;
var() sound YouTaggedSound;
var() localized string YouTaggedMessage;
var() sound YourSlaveTaggedSound;
var() localized string YourSlaveTaggedMessage;
var() localized string exclam;

static function string GetString(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{
    switch(switch)
    {
        case 1:
            return default.YouAreTaggedMessage;
            break;
        case 2:
            if (RelatedPRI_1 != none && RelatedPRI_1.PlayerName != "")
                return default.YouTaggedMessage@RelatedPRI_1.PlayerName$default.exclam;
            break;
        case 3:
            if (RelatedPRI_1 != none && RelatedPRI_2 != none && RelatedPRI_1.PlayerName != "" && RelatedPRI_2.PlayerName != "")
                return RelatedPRI_1.PlayerName@default.YourSlaveTaggedMessage@RelatedPRI_2.PlayerName$default.exclam;
            break;
    }
    return "";
}

static simulated function ClientReceive(
    PlayerController P,
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{
    local sound TheSound;

    Super.ClientReceive(P, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);

    switch(switch)
    {
        case 1:
        TheSound = Default.YouAreTaggedSound;
        break;

        case 2:
            if (RelatedPRI_1 != none && RelatedPRI_1.PlayerName != "")
                TheSound = Default.YouTaggedSound;
            break;

        case 3:
            if (RelatedPRI_1 != none && RelatedPRI_2 != none && RelatedPRI_1.PlayerName != "" && RelatedPRI_2.PlayerName != "")
                TheSound = Default.YourSlaveTaggedSound;
            break;
    }

    P.PlayAnnouncement(TheSound,1,true);
}

defaultproperties
{
     YouAreTaggedSound=Sound'GameSounds.DDAverted'
     YouAreTaggedMessage="You have been tagged!"
     YouTaggedSound=Sound'GameSounds.DDAverted'
     YouTaggedMessage="You tagged"
     YourSlaveTaggedSound=Sound'GameSounds.DDAverted'
     YourSlaveTaggedMessage="has been tagged by your slave,"
     Exclam="!"
     bIsUnique=True
     bFadeMessage=True
     Lifetime=6
     DrawColor=(B=128,G=0)
     StackMode=SM_Down
     PosY=0.242000
}
