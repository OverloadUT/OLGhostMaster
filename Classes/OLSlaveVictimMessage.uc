/*******************************************************************************
    OLSlaveVictimMessage

    Creation date: 18/04/2004 23:21
    Copyright (c) 2004, Greg Laabs
    <!-- $Id$ -->
*******************************************************************************/

class OLSlaveVictimMessage extends xVictimMessage;

var(Message) localized string YouWereEnslavedBy, EnslavedByTrailer;

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
        return Default.YouWereEnslavedBy@RelatedPRI_1.PlayerName$Default.EnslavedByTrailer;
}

defaultproperties
{
     YouWereEnslavedBy="You've been enslaved by"
     EnslavedByTrailer="!"
}
