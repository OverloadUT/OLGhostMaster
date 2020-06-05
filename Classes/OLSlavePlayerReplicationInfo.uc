/*******************************************************************************
    OLSlavePayerReplicationInfo

    Creation date: 09/04/2004 21:54
    Copyright (c) 2004, Greg Laabs
    <!-- $Id$ -->
*******************************************************************************/

class OLSlavePlayerReplicationInfo extends xPlayerReplicationInfo;

var bool bIsSlave;
var PlayerReplicationInfo Master;
var int NumSlaves;
var int Favor;
var int FavorPending;
var int MasterHealth;
var int MasterShields;
var int MasterShieldsMax;
var int MasterAdren;
var int MasterAdrenMax;
struct WeaponInfoStruct
{
    var bool bDefined;
    var float AmmoStatus;
    var int InventoryGroup;
};
struct WeaponInfoStructTwo
{
    var Material IconMaterial;
    var IntBox IconCoords;
    var Weapon Weapon;
};
var WeaponInfoStruct WeaponInfo[10];
var WeaponInfoStructTwo WeaponInfoTwo[10];

struct TaggedPlayer
{
    var Pawn Pawn;
    var PlayerReplicationInfo Tagger;
};

var array<TaggedPlayer> TaggedPlayers;
var PlayerReplicationInfo TaggedPRI[16];
var vector TaggedPlayerLocation[16];
var int TaggedPlayerHealth[16];
var int numtags;

var Pawn LastDamagedBy;

replication
{
    // Things the server should send to the client.
    reliable if ( bNetDirty && (Role == Role_Authority) )
        bIsSlave, Master, NumSlaves, MasterShields, MasterShieldsMax, MasterHealth,
        MasterAdren, MasterAdrenMax, WeaponInfo, WeaponInfoTwo, numtags, Favor,
        TaggedPRI;

    // Only the owner needs his tagged peoples to be replicated.
    unreliable if ( bNetOwner && bNetDirty && (Role == ROLE_Authority) )
        TaggedPlayerLocation, TaggedPlayerHealth;
}

function bool AddTaggedPlayer(pawn TaggedPawn, PlayerReplicationInfo Tagger)
{
    local int i;

    if (TaggedPawn == none)
        return false;

    if (OLSlavePlayerReplicationInfo(TaggedPawn.PlayerReplicationInfo).bIsSlave)
        return false;

    if ( TaggedPawn.PlayerReplicationInfo == self )
        return false;

    if ( IsPlayerTagged(TaggedPawn) )
        return false;

    i = TaggedPlayers.length;
    TaggedPlayers.length = i + 1;
    TaggedPlayers[i].Pawn = TaggedPawn;
    TaggedPlayers[i].Tagger = Tagger;

    return true;
}

simulated function bool IsPlayerTagged(pawn Other)
{
    local int i;

    if (Other == none)
        return false;

    for(i=0;i<numtags;i++)
    {
        if( TaggedPRI[i] == Other.PlayerReplicationInfo )
            return true;
    }
    return false;
}

function Tick(float Delta)
{
    local Weapon W;
    local Inventory Inv;
    local int i, slot;

    Super.Tick(Delta);

    // Tagged Player Replication
    for (i=0;i<TaggedPlayers.Length;i++)
    {
        if( TaggedPlayers[i].Pawn == none || bIsSlave || TaggedPlayers[i].Pawn.Health <= 0)
        {
            TaggedPlayers.Remove(i--,1);
            continue;
        } else {
            TaggedPlayerLocation[i] = TaggedPlayers[i].Pawn.Location;
            TaggedPlayerHealth[i] = TaggedPlayers[i].Pawn.Health;
            TaggedPRI[i] = TaggedPlayers[i].Pawn.PlayerReplicationInfo;
            NetUpdateTime = Level.TimeSeconds - 1;
        }
    }
    numtags = i;

    // Master weapon replication
    if (bIsslave && Master != none
        && Controller(Master.Owner) != none
        && Controller(Master.Owner).Pawn != none)
    {
        for(i=0;i<10;i++)
        {
            WeaponInfo[i].bDefined = false;
        }

        for( Inv=Controller(Master.Owner).Pawn.Inventory; Inv!=None; Inv=Inv.Inventory )
        { // MASTER WEAPON DATA, for use in the HUD
            W = Weapon(Inv);
            if (W == none || W.IconMaterial == none)
                continue;

            if (W.InventoryGroup == 0)
                slot = 8;
            else if (W.InventoryGroup < 10)
                slot = W.InventoryGroup - 1;
            else
                continue;

            if( WeaponInfo[slot].bDefined )
                continue;

            WeaponInfo[slot].bDefined = true;
            WeaponInfo[slot].AmmoStatus = W.AmmoStatus();
            WeaponInfo[slot].InventoryGroup = W.InventoryGroup;
            WeaponInfoTwo[slot].IconMaterial = W.IconMaterial;
            WeaponInfoTwo[slot].IconCoords = W.IconCoords;
        }

        // Other Master stuff for the Slave HUD
        MasterHealth = Controller(Master.Owner).Pawn.Health;
        MasterShields = xPawn(Controller(Master.Owner).Pawn).ShieldStrength;
        MasterShieldsMax = xPawn(Controller(Master.Owner).Pawn).ShieldStrengthMax;
        MasterAdren = Controller(Master.Owner).Adrenaline;
        MasterAdrenMax = Controller(Master.Owner).AdrenalineMax;
    }
}

defaultproperties
{
    NetUpdateFrequency=10.000000
}
