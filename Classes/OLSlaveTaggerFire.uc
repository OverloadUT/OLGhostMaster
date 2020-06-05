/*******************************************************************************
    OLSlaveTaggerFire

    Creation date: 11/04/2004 21:58
    Copyright (c) 2004, Greg Laabs
    <!-- $Id$ -->
*******************************************************************************/

class OLSlaveTaggerFire extends ProjectileFire;

function float MaxRange()
{
    return 1500;
}

defaultproperties
{
     ProjSpawnOffset=(X=20.000000,Y=9.000000,Z=-6.000000)
//     bSplashDamage=True
//     bRecommendSplashDamage=True
     bTossed=True
     FireEndAnim=
//     FireSound=SoundGroup'WeaponSounds.BioRifle.BioRifleFire'
     FireForce="BioRifleFire"
     FireRate=1.000000
     AmmoClass=OLSlaveTaggerAmmo
     AmmoPerFire=0
     ShakeRotMag=(X=70.000000)
     ShakeRotRate=(X=1000.000000)
     ShakeRotTime=1.800000
     ShakeOffsetMag=(Z=-2.000000)
     ShakeOffsetRate=(Z=1000.000000)
     ShakeOffsetTime=1.800000
     ProjectileClass=OLSlave.OLSlaveTaggerBall
     BotRefireRate=1.000000
//     FlashEmitterClass=XEffects.BioMuzFlash1st
}
