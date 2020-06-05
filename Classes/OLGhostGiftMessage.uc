/*******************************************************************************
    OLSlaveGiftMessage

    Creation date: 10/04/2004 19:47
    Copyright (c) 2004, Greg Laabs
    <!-- $Id$ -->
*******************************************************************************/

class OLSlaveGiftMessage extends LocalMessage;

var()   localized String    GiftMessage;

static function string GetString(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1, 
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{
    if(Switch == 0)
        return Default.GiftMessage@RelatedPRI_1.PlayerName;
    else if (Switch == 1)
        return "";
        
}

static function color GetColor(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1, 
    optional PlayerReplicationInfo RelatedPRI_2
    )
{
    if ( Switch == 0 )
        return Default.DrawColor;
}

defaultproperties
{
     GiftMessage="A gift from"
     bIsUnique=True
     bFadeMessage=True
     PosY=0.860000
}