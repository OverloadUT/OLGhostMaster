/*******************************************************************************
    OLGhostMessage

    Creation date: 11/04/2004 20:59
    Copyright (c) 2004, Greg Laabs
    <!-- $Id$ -->
*******************************************************************************/

class OLGhostMessage extends LocalMessage;

//#exec OBJ LOAD FILE=..\Sounds\GameSounds.uax

var() name EnslavedSound;
var() localized string EnslavedMessage;
var() name LiberatedSound;
var() localized string LiberatedMessage;
var() name EarnedFreedomSound;
var() localized string EarnedFreedomMessage;
var() name InsurrectionSound;
var() localized string InsurrectionMessage;

static function string GetString(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{
    switch(switch)
    {
        case 0:
            return default.EnslavedMessage;
        case 1:
            return default.LiberatedMessage;
        case 2:
            return default.EarnedFreedomMessage;
        case 3:
            return default.InsurrectionMessage;
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
    local float atten;

    if(P.ViewTarget == none)
        return;

    Atten = 2.0 * FClamp(0.1 + float(P.AnnouncerVolume)*0.225,0.2,1.0);

    switch(Switch)
    {
        // case 0:
        // FIXME
        //     P.PlayStatusAnnouncement(default.EnslavedSound,2, false);
        // break;

        case 1:
            P.PlayStatusAnnouncement(default.LiberatedSound,2, true);
        break;

        case 2:
            P.PlayStatusAnnouncement(default.EarnedFreedomSound,2, true);
        break;

        case 3:
            P.PlayStatusAnnouncement(default.InsurrectionSound,2, true);
        break;
    }

    Super.ClientReceive(P, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
}

defaultproperties
{

    // EnslavedSound="enslaved"
    EnslavedMessage="Ghosted!"
    LiberatedSound="liberated"
    LiberatedMessage="Liberated!"
    EarnedFreedomSound="earnedfreedom"
    EarnedFreedomMessage="You have earned your freedom"
    InsurrectionSound="insurrection"
    InsurrectionMessage="INSURRECTION!"
    bIsUnique=True
    bFadeMessage=True
    Lifetime=6
    DrawColor=(B=128,G=0)
    StackMode=SM_Down
    PosY=0.242000
}
