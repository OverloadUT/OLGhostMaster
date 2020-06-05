/*******************************************************************************
    OLGhostKillerMessagePlus

    Creation date: 18/04/2004 23:28
    Copyright (c) 2004, Greg Laabs
    <!-- $Id$ -->
*******************************************************************************/

class OLGhostKillerMessagePlus extends xKillerMessagePlus;

var(Message) localized string YouEnslaved;
var(Message) localized string YouEnslavedTrailer;

static function string GetString(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1, 
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject 
    )
{
    if (RelatedPRI_1 == None)
        return "";
    if (RelatedPRI_2 == None)
        return "";

    if (RelatedPRI_2.PlayerName != "")
        return Default.YouEnslaved@RelatedPRI_2.PlayerName@Default.YouEnslavedTrailer;
}

defaultproperties
{
     YouEnslavedTrailer="is now bound to you"
}