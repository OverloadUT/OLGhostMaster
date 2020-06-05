/*******************************************************************************
    OLGhostVictimMessage

    Creation date: 18/04/2004 23:21
    Copyright (c) 2004, Greg Laabs
    <!-- $Id$ -->
*******************************************************************************/

class OLGhostVictimMessage extends xVictimMessage;

var(Message) localized string YouWereGhostedBy, GhostedByTrailer;

static function string GetString(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{
    if (RelatedPRI_1 == None)
        return "";

    if (RelatedPRI_1.PlayerName != "")
        return Default.YouWereGhostedBy@RelatedPRI_1.PlayerName$Default.GhostedByTrailer;
}

defaultproperties
{
     YouWereGhostedBy="You've been bound to"
     GhostedByTrailer="!"
}
