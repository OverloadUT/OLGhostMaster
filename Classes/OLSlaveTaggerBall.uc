/*******************************************************************************
    OLSlaveTaggerBall

    Creation date: 12/04/2004 21:42
    Copyright (c) 2004, Greg Laabs
    <!-- $Id$ -->
*******************************************************************************/

class OLSlaveTaggerBall extends Projectile;

var xEmitter Trail;

replication
{
//    reliable if (bNetInitial && Role == ROLE_Authority)
//        ;
}

simulated function PostBeginPlay()
{
    Super.PostBeginPlay();

    SetOwner(None);

    if (Role == ROLE_Authority)
    {
        Velocity = Vector(Rotation) * Speed;
        Velocity.Z += TossZ;
    }

    if ( Level.bDropDetail )
    {
        bDynamicLight = false;
        LightType = LT_None;
    }
}

simulated function PostNetBeginPlay()
{
    if (Role < ROLE_Authority && Physics == PHYS_None)
    {
        Landed(Vector(Rotation));
    }
}

simulated function Destroyed()
{
    Super.Destroyed();
}

simulated function Explode(vector HitLocation,vector HitNormal)
{
    PlaySound(ImpactSound, SLOT_Misc);
    if ( EffectIsRelevant(Location,false) )
    {
        HitLocation += HitNormal * 5;
//        Spawn(class'ShockExplosionCore',,, HitLocation);
//        if ( !Level.bDropDetail && (Level.DetailMode != DM_Low) )
//            Spawn(class'ShockExplosion',,, HitLocation);
    }
    SetCollisionSize(0.0, 0.0);
    Destroy();
}

function HitPlayer( pawn Other, vector HitLocation )
{
    local OLSlavePlayerReplicationInfo MySPRI;

    MySPRI = OLSlavePlayerReplicationInfo(InstigatorController.PlayerReplicationInfo);

    if ( MySPRI.bIsSlave )
        if ( OLSlavePlayerReplicationInfo(MySPRI.Master).AddTaggedPlayer(Other, MySPRI) )
            OLSlaveGame(Level.Game).SlaveTaggedPlayer(Other, InstigatorController);
    Explode( HitLocation, Normal(HitLocation-Location) );
}

auto state Flying
{
    simulated function Landed( Vector HitNormal )
    {
        if ( Level.NetMode != NM_DedicatedServer )
        {
            PlaySound(ImpactSound, SLOT_Misc);
            // explosion effects
        }
        Explode(Location, HitNormal);
    }

    simulated function HitWall( Vector HitNormal, Actor Wall )
    {
        Landed(HitNormal);
    }

    simulated function ProcessTouch(Actor Other, Vector HitLocation)
    {
        if (Other != Instigator && (Other.IsA('Pawn') || Other.IsA('DestroyableObjective') || Other.bProjTarget))
            HitPlayer(Pawn(Other), HitLocation);
        else if ( Other != Instigator && Other.bBlockActors )
            HitWall( Normal(HitLocation-Location), Other );
    }
}

defaultproperties
{
     Speed=2000.000000
     TossZ=0.000000
     bSwitchToZeroCollision=True
     Damage=0.000000
     DamageRadius=0.000000
     MomentumTransfer=40000.000000
     ImpactSound=SoundGroup'WeaponSounds.BioRifle.BioRifleGoo2'
     MaxEffectDistance=7000.000000
     LightType=LT_Steady
     LightEffect=LE_QuadraticNonIncidence
     LightHue=82
     LightSaturation=10
     LightBrightness=190.000000
     LightRadius=0.600000
     bDynamicLight=True
     bNetTemporary=False
     bOnlyDirtyReplication=True
     Physics=PHYS_Falling
     LifeSpan=20.000000
     AmbientGlow=80
     SoundVolume=255
     SoundRadius=100.000000
     CollisionRadius=10.000000
     CollisionHeight=10.000000
     bUseCollisionStaticMesh=True
     DrawType=DT_Sprite
     Texture=Texture'OLSlave.effects.tagger_core_low'
     DrawScale=0.500000
     Skins(0)=Texture'OLSlave.effects.tagger_core_low'
     Style=STY_Translucent
     bAlwaysFaceCamera=True
}
