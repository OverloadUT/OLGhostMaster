/*******************************************************************************
    OLSlaveHUDMessage

    Creation date: 10/04/2004 20:14
    Copyright (c) 2004, Greg Laabs
    <!-- $Id$ -->
*******************************************************************************/

class OLSlaveHUDMessage extends LocalMessage;

var(Message) localized string YouAreServingString;
var(Message) color RedColor;

static function color GetColor(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1, 
    optional PlayerReplicationInfo RelatedPRI_2
    )
{
    if (Switch == 0)
        return Default.RedColor;
}

static function string GetString(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1, 
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{
    if (Switch == 0)
        return Default.YouAreServingString@RelatedPRI_1.PlayerName;
}

defaultproperties
{
     YouAreServingString="You are serving"
     RedColor=(R=255,A=255)
     bIsPartiallyUnique=True
     bIsConsoleMessage=False
     bFadeMessage=True
     Lifetime=1
     DrawColor=(G=160,R=0)
     StackMode=SM_Down
     PosY=0.100000
     FontSize=1
}