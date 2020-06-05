/*******************************************************************************
    OLGhostPawn

    Creation date: 05/04/2004 22:45
    Copyright (c) 2004, Greg Laabs
    <!-- $Id$ -->
*******************************************************************************/

class OLGhostPawn extends xPawn;

#exec OBJ LOAD FILE=MutantSkins.utx

var OLGhostGameReplicationInfo  OLGhostGRI;
var bool bIsGhost;
var Controller Master;

var bool            bGhostEffect;
var bool            bOldGhostEffect;
var Emitter         GhostFX;
var Class<Emitter>  GhostFXClass;

var(DeRes) InterpCurve GhostDeResLiftVel; // speed (over time) at which body rises
var(DeRes) InterpCurve GhostDeResLiftSoftness; // vertical 'sprinyness' (over time) of bone lifters
var(DeRes) float  GhostDeResGravScale; // reduce gravity on corpse during de-res
var(DeRes) float  GhostDeResLateralFriction; // sideways friction while lifting

replication
{
    reliable if(Role == ROLE_Authority)
        OLGhostGRI, bIsGhost, Master;
}

event PostBeginPlay()
{
    Super.PostBeginPlay();

    // Send GRI to Pawn
    if(Role == ROLE_Authority && Level.Game != None)
    {
        OLGhostGRI = OLGhostGameReplicationInfo(Level.Game.GameReplicationInfo);
    }

}

function RewardForFavor(int favor)
{
    local int i;

    // Reward weapons, 1 for every 20 favor.
    for(i=20;i<=favor;i+=20)
    {
        GiveRandomWeapon();
    }

    // Reward health, 1 for every 2 favor.
    GiveHealth(favor / 2, SuperHealthMax);

    // Reward armor, 1 for every 4 favor.
    AddShieldStrength(favor / 4);

    // Reward adrenaline, 1 for every 2 favor.
    Controller.AwardAdrenaline(favor/2);

    // If player earned his freedom, award an extra 50 adren.
    if(favor >= OLGhostGame(Level.Game).FavorTarget)
        Controller.AwardAdrenaline(50);
}

function GiveRandomWeapon()
{
    local int random;
    local Inventory item;
    local class<Inventory> itemclass;

    random = rand(7);
    // 0 = Bio Rifle
    // 1 = Shock Rifle
    // 2 = Link Gun
    // 3 = Minigun
    // 4 = Flak Cannon
    // 5 = Rocket Launcher
    // 6 = Lightning Gun

    switch(random)
    {
        case 0:
            itemclass = class'BioRifle';
            break;
        case 1:
            itemclass = class'ShockRifle';
            break;
        case 2:
            itemclass = class'LinkGun';
            break;
        case 3:
            itemclass = class'Minigun';
            break;
        case 4:
            itemclass = class'FlakCannon';
            break;
        case 5:
            itemclass = class'RocketLauncher';
            break;
        case 6:
            itemclass = class'SniperRifle';
            break;
    }

    item = spawn(itemclass);
    item.GiveTo(self);
}

function FreeGhost()
{
//    PlayDyingAnimation(class'DamageType', vect(0,0,0));
//    Health = 0;
//    GoToState('Dying');
    Destroy();
}

function MakeGhost()
{
    local float GhostSpeedMultiplier;

    // Remove all of the player's inventory
    while(Inventory != none)
        Inventory.Destroy();

    CreateInventory("OLGhostMaster.OLGhostTagger");
    Controller.ClientSetWeapon(class'OLGhostTagger');


    // Invisibility
    SetInvisibility(2000000.0);


    GhostSpeedMultiplier = OLGhostGame(Level.Game).GhostSpeedMultiplier;

    AirControl = Default.AirControl * GhostSpeedMultiplier;
    GroundSpeed = Default.GroundSpeed * GhostSpeedMultiplier;
    WaterSpeed = Default.WaterSpeed * GhostSpeedMultiplier;
    AirSpeed = Default.AirSpeed * GhostSpeedMultiplier;
    JumpZ = Default.JumpZ * GhostSpeedMultiplier;
    bCanBeDamaged = false;
    bProjTarget = !OLGhostGame(Level.Game).bGhostsEthereal;
    bBlockActors = !OLGhostGame(Level.Game).bGhostsEthereal;
    bBlockZeroExtentTraces = OLGhostGame(Level.Game).bGhostsEthereal;
    bBlockNonZeroExtentTraces = OLGhostGame(Level.Game).bGhostsEthereal;

    if ( Bot(Controller) != none )
    {
        Bot(Controller).bHasTranslocator = false;
        Bot(Controller).bHasImpactHammer = false;
    }
}

simulated function TickFX(float DeltaTime)
{
    Super.TickFX(DeltaTime);

    // See if this is a ghost
    if( bIsGhost )
        bGhostEffect = true;
    else
        bGhostEffect = false;

    if(bGhostEffect && !bOldGhostEffect)
    {
        // Spawn funky glowy effect
        GhostFX = Spawn(GhostFXClass, self, , Location);
        if ( GhostFX != None )
        {
            GhostFX.Emitters[0].SkeletalMeshActor = self;
            GhostFX.SetLocation(Location - vect(0, 0, 49));
            GhostFX.SetRotation(Rotation + rot(0, -16384, 0));
            GhostFX.SetBase(self);
        }
    }
    else if(!bGhostEffect && bOldGhostEffect)
    {
        // Remove funky glowy effect
        if( GhostFX != None )
        {
            GhostFX.Emitters[0].SkeletalMeshActor = None;
            GhostFX.Kill();
            GhostFX = None;
        }
    }

    bOldGhostEffect = bGhostEffect;
}

simulated function Destroyed()
{
    Super.Destroyed();

    if( GhostFX != None )
    {
        GhostFX.Emitters[0].SkeletalMeshActor = None;
        GhostFX.Kill();
        GhostFX = None;
    }
}



simulated function StartDeRes()
{
    local KarmaParamsSkel skelParams;
    local int i;

    if( Level.NetMode == NM_DedicatedServer )
        return;

    AmbientGlow=254;
    MaxLights=0;

    DeResFX = Spawn(class'DeResPart', self, , Location);
    if ( DeResFX != None )
    {
        DeResFX.Emitters[0].SkeletalMeshActor = self;
        DeResFX.SetBase(self);
    }

    if (!bIsGhost)
    {
        Skins[0] = DeResMat0;
        Skins[1] = DeResMat1;
        if ( Skins.Length > 2 )
        {
            for ( i=2; i<Skins.Length; i++ )
                Skins[i] = DeResMat0;
        }
    }

    if( Physics == PHYS_KarmaRagdoll )
    {
        if (!bIsGhost)
        {
            // Attach bone lifter to raise body
            KAddBoneLifter('bip01 Spine', DeResLiftVel, DeResLateralFriction, DeResLiftSoftness);
            KAddBoneLifter('bip01 Spine2', DeResLiftVel, DeResLateralFriction, DeResLiftSoftness);

            // Turn off gravity while de-res-ing
            KSetActorGravScale(DeResGravScale);

            // Turn off collision with the world for the ragdoll.
            KSetBlockKarma(false);

            // Turn off convulsions during de-res
            skelParams = KarmaParamsSkel(KParams);
            skelParams.bKDoConvulsions = false;
        } else {
            // Attach bone lifter to raise body
            KAddBoneLifter('bip01 Spine', GhostDeResLiftVel, GhostDeResLateralFriction, GhostDeResLiftSoftness);
            KAddBoneLifter('bip01 Spine2', GhostDeResLiftVel, GhostDeResLateralFriction, GhostDeResLiftSoftness);

            // Turn off gravity while de-res-ing
            KSetActorGravScale(DeResGravScale);

            // Turn off collision with the world for the ragdoll.
            KSetBlockKarma(false);

            // Turn off convulsions during de-res
            skelParams = KarmaParamsSkel(KParams);
            skelParams.bKDoConvulsions = false;

        }
    }

    AmbientSound = Sound'GeneralAmbience.Texture19';
    SoundRadius = 40.0;

    // Turn off collision when we de-res (avoids rockets etc. hitting corpse!)
    SetCollision(false, false, false);

    // Remove/disallow projectors
    Projectors.Remove(0, Projectors.Length);
    bAcceptsProjectors = false;

    // Remove shadow
    if(PlayerShadow != None)
        PlayerShadow.bShadowActive = false;

    // Remove flames
    RemoveFlamingEffects();

    // Turn off any overlays
    SetOverlayMaterial(None, 0.0f, true);

    bDeRes = true;
}

function PlayDyingAnimation(class<DamageType> DamageType, vector HitLoc)
{
    local vector shotDir, hitLocRel, deathAngVel, shotStrength;
    local float maxDim;
    local string RagSkelName;
    local KarmaParamsSkel skelParams;
    local bool PlayersRagdoll;
    local PlayerController pc;

    if ( Level.NetMode != NM_DedicatedServer )
    {
        // Is this the local player's ragdoll?
        if(OldController != None)
            pc = PlayerController(OldController);
        if( pc != None && pc.ViewTarget == self )
            PlayersRagdoll = true;

        // In low physics detail, if we were not just controlling this pawn,
        // and it has not been rendered in 3 seconds, just destroy it.
        if( (Level.PhysicsDetailLevel != PDL_High) && !PlayersRagdoll && (Level.TimeSeconds - LastRenderTime > 3) )
        {
            Destroy();
            return;
        }

        // Try and obtain a rag-doll setup. Use optional 'override' one out of player record first, then use the species one.
        if( RagdollOverride != "")
            RagSkelName = RagdollOverride;
        else if(Species != None)
            RagSkelName = Species.static.GetRagSkelName( GetMeshName() );
        else
            Log("xPawn.PlayDying: No Species");

        // If we managed to find a name, try and make a rag-doll slot availbale.
        if( RagSkelName != "" )
        {
            KMakeRagdollAvailable();
        }

        if( KIsRagdollAvailable() && RagSkelName != "" )
        {
            skelParams = KarmaParamsSkel(KParams);
            skelParams.KSkeleton = RagSkelName;

            // Stop animation playing.
            StopAnimating(true);

            if( DamageType != None )
            {
                if ( DamageType.default.bLeaveBodyEffect )
                    TearOffMomentum = vect(0,0,0);

                if( DamageType.default.bKUseOwnDeathVel )
                {
                    RagDeathVel = DamageType.default.KDeathVel;
                    RagDeathUpKick = DamageType.default.KDeathUpKick;
                }
            }

            // Set the dude moving in direction he was shot in general
            shotDir = Normal(TearOffMomentum);
            shotStrength = RagDeathVel * shotDir;

            // Calculate angular velocity to impart, based on shot location.
            hitLocRel = TakeHitLocation - Location;

            // We scale the hit location out sideways a bit, to get more spin around Z.
            hitLocRel.X *= RagSpinScale;
            hitLocRel.Y *= RagSpinScale;

            // If the tear off momentum was very small for some reason, make up some angular velocity for the pawn
            if( VSize(TearOffMomentum) < 0.01 )
            {
                //Log("TearOffMomentum magnitude of Zero");
                deathAngVel = VRand() * 18000.0;
            }
            else
            {
                deathAngVel = RagInvInertia * (hitLocRel Cross shotStrength);
            }

            // Set initial angular and linear velocity for ragdoll.
            // Scale horizontal velocity for characters - they run really fast!
            if ( DamageType.Default.bRubbery )
                skelParams.KStartLinVel = vect(0,0,0);
            if ( Damagetype.default.bKUseTearOffMomentum )
                skelParams.KStartLinVel = TearOffMomentum + Velocity;
            else
            {
                skelParams.KStartLinVel.X = 0.6 * Velocity.X;
                skelParams.KStartLinVel.Y = 0.6 * Velocity.Y;
                skelParams.KStartLinVel.Z = 1.0 * Velocity.Z;
                    skelParams.KStartLinVel += shotStrength;
            }
            // If not moving downwards - give extra upward kick
            if( !DamageType.default.bLeaveBodyEffect && !DamageType.Default.bRubbery && (Velocity.Z > -10) )
                skelParams.KStartLinVel.Z += RagDeathUpKick;

            if ( DamageType.Default.bRubbery )
            {
                Velocity = vect(0,0,0);
                skelParams.KStartAngVel = vect(0,0,0);
            }
            else
            {
                skelParams.KStartAngVel = deathAngVel;

                // Set up deferred shot-bone impulse
                maxDim = Max(CollisionRadius, CollisionHeight);

                skelParams.KShotStart = TakeHitLocation - (1 * shotDir);
                skelParams.KShotEnd = TakeHitLocation + (2*maxDim*shotDir);
                skelParams.KShotStrength = RagShootStrength;
            }

            // If this damage type causes convulsions, turn them on here.
            if(DamageType != None && DamageType.default.bCauseConvulsions)
            {
                RagConvulseMaterial=DamageType.default.DamageOverlayMaterial;
                skelParams.bKDoConvulsions = true;
            }

            // Turn on Karma collision for ragdoll.
            KSetBlockKarma(true);

            // Set physics mode to ragdoll.
            // This doesn't actaully start it straight away, it's deferred to the first tick.
            SetPhysics(PHYS_KarmaRagdoll);

            // If viewing this ragdoll, set the flag to indicate that it is 'important'
            if( PlayersRagdoll )
                skelParams.bKImportantRagdoll = true;

            skelParams.bRubbery = DamageType.Default.bRubbery;
            bRubbery = DamageType.Default.bRubbery;

            skelParams.KActorGravScale = RagGravScale;

            if (bIsGhost)
                StartDeres();

            return;
        }
        // jag
    }

    // non-ragdoll death fallback
    Velocity += TearOffMomentum;
    BaseEyeHeight = Default.BaseEyeHeight;
    SetTwistLook(0, 0);
    SetInvisibility(0.0);
    PlayDirectionalDeath(HitLoc);
    SetPhysics(PHYS_Falling);
}



state Dying
{
    simulated function BeginState()
    {
//        if (!bIsGhost)
            Super.BeginState();
//        else
            AmbientSound = None;
    }
}

defaultproperties
{
     InvisMaterial=FinalBlend'MutantSkins.Shaders.MutantGlowFinal'
     GhostFXClass=OLGhostMaster.OLGhostGlow
     GhostDeResLiftVel=(Points=(,(InVal=2.500000,OutVal=32.000000),(InVal=100.000000,OutVal=32.000000)))
     GhostDeResLiftSoftness=(Points=((OutVal=0.300000),(InVal=2.500000,OutVal=0.050000),(InVal=100.000000,OutVal=0.050000)))
     GhostDeResLateralFriction=0.300000
     bScriptPostRender = true;
}
