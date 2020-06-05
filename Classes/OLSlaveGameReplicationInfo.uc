/*******************************************************************************
    OLSlaveGameReplicationInfo

    Creation date: 05/04/2004 22:52
    Copyright (c) 2004, Greg Laabs
    <!-- $Id$ -->
*******************************************************************************/

class OLSlaveGameReplicationInfo extends GameReplicationInfo;

var int NumSlaves;
var int NumMasters;

replication
{
    reliable if(bNetDirty && (Role == ROLE_Authority))
        NumSlaves, NumMasters;
}