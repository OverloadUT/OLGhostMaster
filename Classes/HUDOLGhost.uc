/*******************************************************************************
    HUDOLGhost

    Creation date: 09/04/2004 21:32
    Copyright (c) 2004, Greg Laabs

    The Heads up Display for the Ghost Master gametype. Handles displaying the
    location of "tagged" players, as well as changing the hud for ghosts.
    Ghosts' HUDS show the inventory of their masters, as they have no inventory
    themselves.

*******************************************************************************/

class HUDOLGhost extends HudCDeathMatch;

var()   Texture             GhostBeaconMat;
var()   Color               GhostBeaconColor;
var()   Texture             MasterBeaconMat;
var()   Color               MasterBeaconColor;
var()   Texture             TaggedBeaconMat;
var()   Color               TaggedBeaconColor;
var()   Color               ObstructedTaggedColor;

// For number of ghosts / favor
var() NumericWidget myOtherGhostsNum;
var() NumericWidget myGhostMasterNum;
var() NumericWidget myGhostsNum;
var() NumericWidget myFavor;
var() SpriteWidget FavorIcon,FavorBackgroundDisc;

var int LastFavor;
var float LastFavorTime;
var float Global_Delta;
var float fBlink, fPulse;

var localized string    IP_Bracket_Open, IP_Bracket_Close;
var localized string    MetersString;

var config  float   ObjectiveScale;                 // Size scale of visible objective reticles

simulated function Tick(float DeltaTime)
{
    super.Tick( DeltaTime );

    Global_Delta = DeltaTime;

    fBlink += DeltaTime;
    while ( fBlink > 0.5 )
        fBlink -= 0.5;

    fPulse = Abs(1.f - 4*fBlink);
}

simulated function PostBeginPlay()
{
    Super.PostBeginPlay();
    SetTimer(1.0, True);
}

simulated function bool PRIIsGhost(PlayerReplicationInfo PRI)
{
    local OLGhostPlayerReplicationInfo GhostInfo;

    GhostInfo = OLGhostPlayerReplicationInfo( PRI );
    if(GhostInfo != none && GhostInfo.bIsGhost)
        return true;
    else
        return false;
}

simulated function PlayerReplicationInfo PRIGetMaster(PlayerReplicationInfo PRI)
{
    local OLGhostPlayerReplicationInfo GhostInfo;

    GhostInfo = OLGhostPlayerReplicationInfo( PRI );

    return GhostInfo.Master;
}

simulated function DrawTaggedPlayers(Canvas C)
{
    local int           i;
    local vector        ScreenPos;
    local vector        CamLoc;
    local rotator       CamRot;
    local OLGhostPlayerReplicationInfo GhostPRI;
    local float     ProgressPct;

    GhostPRI = OLGhostPlayerReplicationInfo(PawnOwnerPRI);

    for(i=0;i<GhostPRI.numtags;i++)
    {
        C.DrawColor = HudColorBlue;
        C.Style     = ERenderStyle.STY_Alpha;
        C.GetCameraLocation( CamLoc, CamRot );
        ProgressPct = float(GhostPRI.TaggedPlayerHealth[i]) / 100;

        if ( IsLocationVisible( C, GhostPRI.TaggedPlayerLocation[i], ScreenPos, CamLoc, CamRot ) )
        {

        }
        else if ( IsTargetInFrontOfPlayer( C, GhostPRI.TaggedPlayerLocation[i], ScreenPos, CamLoc, CamRot ) )
        {
            DrawLocationTracking_Obstructed( C, GhostPRI.TaggedPlayerLocation[i], false, CamLoc, ScreenPos );
        }
        else
        {

        }
    }

/*
    ForEach DynamicActors(class'Pawn',P)
        if ( P.Health > 0 )
        {
            IsLocationVisible( C, P.Location, ScreenPos, CamLoc, CamRot );
            DrawLocationTracking_Obstructed( C, P.Location, false, CamLoc, ScreenPos );
        }
*/
}

simulated function DrawLocationTracking_Obstructed( Canvas C, Vector A, bool bOptionalIndicator, vector CamLoc, out vector ScreenPos )
{
    local String    DistanceText;
    local float     XL, YL, tileX, tileY, width, height;
    local vector    IndicatorPos;

    C.Style         = ERenderStyle.STY_Alpha;
    DistanceText    = IP_Bracket_Open $ int(VSize(A-CamLoc)*0.01875.f) $ MetersString $ IP_Bracket_Close;
    C.Font          = GetConsoleFont( C );

    C.StrLen(DistanceText, XL, YL);
    XL = XL*0.5;
    YL = YL*0.5;

    tileX   = 64.f * 0.45 * ResScaleX * ObjectiveScale * HUDScale;
    tileY   = 64.f * 0.45 * ResScaleY * ObjectiveScale * HUDScale;

    width   = FMax(tileX*0.5, XL);
    height  = tileY*0.5 + YL*2;
    ClipScreenCoords( C, ScreenPos.X, ScreenPos.Y, width, height );

    // Objective Icon
    IndicatorPos.X = ScreenPos.X;
    IndicatorPos.Y = ScreenPos.Y - height + YL + tileY*0.5;
    DrawObstructedIcon( C, bOptionalIndicator, IndicatorPos.X - tileX*0.5, IndicatorPos.Y - tileY*0.5, tileX, tileY );

    // Distance reading
    C.SetPos(IndicatorPos.X - XL, IndicatorPos.Y + tileY*0.5 );
    C.DrawText(DistanceText, false);

    ScreenPos = IndicatorPos;
}

simulated function DrawObstructedIcon( Canvas C, bool bOptionalObjective, float posX, float posY, float tileX, float tileY )
{
    C.SetPos(posX, posY);
    C.DrawColor = ObstructedTaggedColor;

    C.DrawTile( TexRotator'HUDContent.Reticles.rotReticle001', tileX, tileY, 0.f, 0.f, 256, 256);
}

static function Color GetGYRColorRamp( float Pct )
{
    local Color GYRColor;

    GYRColor.A = 255;

    if ( Pct < 0.34 )
    {
        GYRColor.R = 128 + 127 * FClamp(3.f*Pct, 0.f, 1.f);
        GYRColor.G = 0;
        GYRColor.B = 0;
    }
    else if ( Pct < 0.67 )
    {
        GYRColor.R = 255;
        GYRColor.G = 255 * FClamp(3.f*(Pct-0.33), 0.f, 1.f);
        GYRColor.B = 0;
    }
    else
    {
        GYRColor.R = 255 * FClamp(3.f*(1.f-Pct), 0.f, 1.f);
        GYRColor.G = 255;
        GYRColor.B = 0;
    }

    return GYRColor;
}

simulated final function bool IsLocationVisible( Canvas C, Vector Target, out vector ScreenPos,
                                                 Vector CamLoc, Rotator CamRot )
{
    local vector        TargetLocation, TargetDir;
    local float         Dist;

    Dist = VSize(Target - CamLoc);

    // Target is located behind camera
    if ( !IsTargetInFrontOfPlayer( C, Target, ScreenPos, CamLoc, CamRot ) )
        return false;

    // Simple Line check to see if we hit geometry
    TargetDir       = Target - CamLoc;
    TargetDir.Z     = 0;
//    TargetLocation  = Target.Location - 2.f * Target.CollisionRadius * vector(rotator(TargetDir));
    TargetLocation  = Target - 2.f * 32 * vector(rotator(TargetDir));

    if ( !FastTrace( TargetLocation, CamLoc ) )
        return false;

    return true;
}

/* returns true if target is projected on visible canvas area */
static function bool IsTargetInFrontOfPlayer( Canvas C, Vector Target, out Vector ScreenPos,
                                             Vector CamLoc, Rotator CamRot )
{
    // Is Target located behind camera ?
    if ( (Target - CamLoc) Dot vector(CamRot) < 0)
        return false;

    // Is Target on visible canvas area ?
    ScreenPos = C.WorldToScreen( Target );
    if ( ScreenPos.X <= 0 || ScreenPos.X >= C.ClipX ) return false;
    if ( ScreenPos.Y <= 0 || ScreenPos.Y >= C.ClipY ) return false;

    return true;
}

static function ClipScreenCoords( Canvas C, out float X, out float Y, optional float XL, optional float YL )
{
    if ( X < XL ) X = XL;
    if ( Y < YL ) Y = YL;
    if ( X > C.ClipX - XL ) X = C.ClipX - XL;
    if ( Y > C.ClipY - YL ) Y = C.ClipY - YL;
}

simulated function CalculateHealth()
{
    local bool bIsGhost;
    local PlayerReplicationInfo Master;

    if ( PRIIsGhost(PawnOwnerPRI) )
    {
        bIsGhost = true;
        Master = PRIGetMaster(PawnOwnerPRI);
    }

    LastHealth = CurHealth;

    if (!bIsGhost)
    {
        if (Vehicle(PawnOwner) != None)
        {
            if ( Vehicle(PawnOwner).Driver != None )
                CurHealth = Vehicle(PawnOwner).Driver.Health;
            LastVehicleHealth = CurVehicleHealth;
            CurVehicleHealth = PawnOwner.Health;
        }
        else
        {
            CurHealth = PawnOwner.Health;
            CurVehicleHealth = 0;
        }
    } else {
        CurHealth = OLGhostPlayerReplicationInfo(PawnOwnerPRI).MasterHealth;
    }
}

simulated function UpdateRankAndSpread(Canvas C)
{
    local bool bIsGhost;
    local PlayerReplicationInfo Master;

    if ( PRIIsGhost(PawnOwnerPRI) )
    {
        bIsGhost = true;
        Master = PRIGetMaster(PawnOwnerPRI);
    }

    if ( (Scoreboard == None) || !Scoreboard.UpdateGRI() )
        return;

    if( !bIsGhost )
    {
        myGhostsNum.Value = OLGhostPlayerReplicationInfo(PawnOwnerPRI).NumGhosts;
        myGhostMasterNum.Value = OLGhostGameReplicationInfo(PlayerOwner.GameReplicationInfo).NumMasters - 1;
        myOtherGhostsNum.Value = OLGhostGameReplicationInfo(PlayerOwner.GameReplicationInfo).NumGhosts - OLGhostPlayerReplicationInfo(PawnOwnerPRI).NumGhosts;

        if( bShowPoints )
        {
            DrawSpriteWidget( C, MyScoreBackground );
            MyScoreBackground.Tints[TeamIndex] = HudColorBlack;
            MyScoreBackground.Tints[TeamIndex].A = 150;

            DrawNumericWidget (C, myGhostMasterNum, DigitsBig);
            if ( C.ClipX >= 640 )
                DrawNumericWidget (C, myOtherGhostsNum, DigitsBig);
            DrawNumericWidget (C, myGhostsNum, DigitsBig);
        }
    } else {
        myFavor.Value = OLGhostPlayerReplicationInfo(PawnOwnerPRI).Favor;

        if( bShowPoints )
        {
            if (LastFavor < myFavor.Value)
                LastFavorTime = Level.TimeSeconds;
            LastFavor = myFavor.Value;

            DrawSpriteWidget( C, MyScoreBackground );
            DrawSpriteWidget( C, FavorBackgroundDisc );
            MyScoreBackground.Tints[TeamIndex] = HudColorBlack;
            MyScoreBackground.Tints[TeamIndex].A = 150;

            DrawSpriteWidget( C, FavorIcon );

            DrawNumericWidget (C, myFavor, DigitsBig);

            DrawHUDAnimWidget( FavorIcon, default.FavorIcon.TextureScale, LastFavorTime, 0.4, 0.4);
        }
    }
}

simulated function CalculateShield()
{
    local xPawn P;
    local bool bIsGhost;
    local PlayerReplicationInfo Master;

    if ( PRIIsGhost(PawnOwnerPRI) )
    {
        bIsGhost = true;
        Master = PRIGetMaster(PawnOwnerPRI);
    }

    LastShield = CurShield;

    if (!bIsGhost)
    {
        if (Vehicle(PawnOwner) != None)
            P = xPawn(Vehicle(PawnOwner).Driver);
        else
            P = xPawn(PawnOwner);

        if( P != None )
        {
            MaxShield = P.ShieldStrengthMax;
            CurShield = Clamp(P.ShieldStrength, 0, MaxShield);
        }
        else
        {
            MaxShield = 100;
            CurShield = 0;
        }
    } else {
        MaxShield = OLGhostPlayerReplicationInfo(PawnOwnerPRI).MasterShieldsMax;
        CurShield = Clamp(OLGhostPlayerReplicationInfo(PawnOwnerPRI).MasterShields, 0, MaxShield);
    }
}

simulated function CalculateEnergy()
{
    local bool bIsGhost;
    local PlayerReplicationInfo Master;

    if ( PRIIsGhost(PawnOwnerPRI) )
    {
        bIsGhost = true;
        Master = PRIGetMaster(PawnOwnerPRI);
    }

    if (!bIsGhost)
    {
        if ( PawnOwner.Controller == None )
        {
            MaxEnergy = PlayerOwner.AdrenalineMax;
            CurEnergy = Clamp (PlayerOwner.Adrenaline, 0, MaxEnergy);
        }
        else
        {
            MaxEnergy = PawnOwner.Controller.AdrenalineMax;
            CurEnergy = Clamp (PawnOwner.Controller.Adrenaline, 0, MaxEnergy);
        }
    } else {
        MaxEnergy = OLGhostPlayerReplicationInfo(PawnOwnerPRI).MasterAdrenMax;
        CurEnergy = Clamp (OLGhostPlayerReplicationInfo(PawnOwnerPRI).MasterAdren, 0, MaxEnergy);
    }
}

function DisplayEnemyName(Canvas C, PlayerReplicationInfo PRI)
{
    if( PRIIsGhost( PRI ) )
    {
        PlayerOwner.ReceiveLocalizedMessage(class'OLGhostNameMessage',1,PRI); // First part of name message
        if ( PRIGetMaster(PRI) != none )
            PlayerOwner.ReceiveLocalizedMessage(class'OLGhostSubNameMessage',1,PRI,PRIGetMaster(PRI)); // "Serving X" message
    }
    else
    {
        PlayerOwner.ReceiveLocalizedMessage(class'OLGhostNameMessage',0,PRI); // First part of name message
        PlayerOwner.ReceiveLocalizedMessage(class'OLGhostSubNameMessage',0,PRI); // First part of name message
    }
}

simulated function DrawCustomBeacon(Canvas C, Pawn P, float ScreenLocX, float ScreenLocY)
{
    if (P.PlayerReplicationInfo == none || OLGhostPlayerReplicationInfo(P.PlayerReplicationInfo) == none)
        return;

    if ( OLGhostPlayerReplicationInfo(PawnOwnerPRI).bIsGhost && OLGhostPlayerReplicationInfo(OLGhostPlayerReplicationInfo(PawnOwnerPRI).Master).IsPlayerTagged(P) )
    {
        C.DrawColor = TaggedBeaconColor;
        C.SetPos(ScreenLocX - 0.125 * GhostBeaconMat.USize, ScreenLocY - 0.125 * TaggedBeaconMat.VSize);
        C.DrawTile(TaggedBeaconMat,
            0.25 * TaggedBeaconMat.USize,
            0.25 * TaggedBeaconMat.VSize,
            0.0,
            0.0,
            TaggedBeaconMat.USize,
            TaggedBeaconMat.VSize);
    }
    else if ( !OLGhostPlayerReplicationInfo(PawnOwnerPRI).bIsGhost && OLGhostPlayerReplicationInfo(PawnOwnerPRI).IsPlayerTagged(P) )
    {
        C.DrawColor = TaggedBeaconColor;
        C.SetPos(ScreenLocX - 0.125 * GhostBeaconMat.USize, ScreenLocY - 0.125 * TaggedBeaconMat.VSize);
        C.DrawTile(TaggedBeaconMat,
            0.25 * TaggedBeaconMat.USize,
            0.25 * TaggedBeaconMat.VSize,
            0.0,
            0.0,
            TaggedBeaconMat.USize,
            TaggedBeaconMat.VSize);
    }
    else if ( OLGhostPlayerReplicationInfo(PawnOwnerPRI).bIsGhost && OLGhostPlayerReplicationInfo(PawnOwnerPRI).Master == P.PlayerReplicationInfo )
    {
        C.DrawColor = MasterBeaconColor;
        C.SetPos(ScreenLocX - 0.125 * MasterBeaconMat.USize, ScreenLocY - 0.125 * MasterBeaconMat.VSize);
        C.DrawTile(GhostBeaconMat,
            0.25 * MasterBeaconMat.USize,
            0.25 * MasterBeaconMat.VSize,
            0.0,
            0.0,
            MasterBeaconMat.USize,
            MasterBeaconMat.VSize);
    }
}

function Timer()
{

    local bool bIsGhost;
    local PlayerReplicationInfo Master;

    if ( PRIIsGhost(PawnOwnerPRI) )
    {
        bIsGhost = true;
        Master = PRIGetMaster(PawnOwnerPRI);
    }

    Super.Timer();

    if ( (PawnOwnerPRI == None)
        || (PlayerOwner.IsSpectating() && (PlayerOwner.bBehindView || (PlayerOwner.ViewTarget == PlayerOwner))) )
        return;

    if ( bIsGhost )
        PlayerOwner.ReceiveLocalizedMessage( class'OLGhostHUDMessage', 0, Master );
}


simulated function DrawWeaponBar( Canvas C )
{
    local int i, Count, Pos;
    local float IconOffset;
    local float HudScaleOffset, HudMinScale;

//    local Weapon Weapons[WEAPON_BAR_SIZE];
    local OLGhostPlayerReplicationInfo.WeaponInfoStruct Weapons[WEAPON_BAR_SIZE];
    local OLGhostPlayerReplicationInfo.WeaponInfoStructTwo WeaponsTwo[WEAPON_BAR_SIZE];
    local byte ExtraWeapon[WEAPON_BAR_SIZE];
    local Inventory Inv;
    local OLGhostPlayerReplicationInfo.WeaponInfoStruct WI;
    local OLGhostPlayerReplicationInfo.WeaponInfoStructTwo WIT;
    local Weapon W, PendingWeapon;

    local bool bIsGhost;
    local PlayerReplicationInfo Master;

    if ( PRIIsGhost(PawnOwnerPRI) )
    {
        bIsGhost = true;
        Master = PRIGetMaster(PawnOwnerPRI);
    }

    HudMinScale=0.5;
    // CurHudScale = HudScale;
    //no weaponbar for vehicles
    if (Vehicle(PawnOwner) != None)
    return;

    if (PawnOwner.PendingWeapon != None)
        PendingWeapon = PawnOwner.PendingWeapon;
    else
        PendingWeapon = PawnOwner.Weapon;

    // fill:

    if ( !bIsGhost )
    {
        for( Inv=PawnOwner.Inventory; Inv!=None; Inv=Inv.Inventory )
        {
            W = Weapon( Inv );
            Count++;
            if ( Count > 100 )
                break;

            if( (W == None) || (W.IconMaterial == None) )
                continue;

            if ( W.InventoryGroup == 0 )
                Pos = 8;
            else if ( W.InventoryGroup < 10 )
                Pos = W.InventoryGroup-1;
            else
                continue;

            if ( Weapons[Pos].bDefined )
                ExtraWeapon[Pos] = 1;
            else
            {
                Weapons[Pos].bDefined = true;
                Weapons[Pos].AmmoStatus = W.AmmoStatus();
                Weapons[Pos].InventoryGroup = W.InventoryGroup;
                WeaponsTwo[Pos].IconMaterial = W.IconMaterial;
                WeaponsTwo[Pos].IconCoords = W.IconCoords;
                WeaponsTwo[Pos].Weapon = W;
            }
        }
    } else {
        for( i=0; i<WEAPON_BAR_SIZE; i++ )
        {
            Count++;
            if ( Count > 100 )
                break;

            WI = OLGhostPlayerReplicationInfo(PawnOwnerPRI).WeaponInfo[i];
            WIT = OLGhostPlayerReplicationInfo(PawnOwnerPRI).WeaponInfoTwo[i];

            if(!WI.bDefined)
                continue;

            if ( WI.InventoryGroup == 0 )
                Pos = 8;
            else if ( WI.InventoryGroup < 10 )
                Pos = WI.InventoryGroup-1;
            else
                continue;

            if ( Weapons[Pos].bDefined )
                ExtraWeapon[Pos] = 1;
            else
            {
                Weapons[Pos] = WI;
                WeaponsTwo[Pos] = WIT;
            }
        }
    }


    if ( PendingWeapon != None )
    {
        if ( PendingWeapon.InventoryGroup == 0 )
            WeaponsTwo[8].Weapon = PendingWeapon;
        else if ( PendingWeapon.InventoryGroup < 10 )
            WeaponsTwo[PendingWeapon.InventoryGroup-1].Weapon = PendingWeapon;
    }

    // Draw:
    for( i=0; i<WEAPON_BAR_SIZE; i++ )
    {
        WI = Weapons[i];
        WIT = WeaponsTwo[i];

        // Keep weaponbar organized when scaled
        HudScaleOffset= 1-(HudScale-HudMinScale)/HudMinScale;
        BarBorder[i].PosX =  default.BarBorder[i].PosX+( BarBorderScaledPosition[i] - default.BarBorder[i].PosX) *HudScaleOffset;
        BarWeaponIcon[i].PosX = BarBorder[i].PosX;

        IconOffset = (default.BarBorder[i].TextureCoords.X2 - default.BarBorder[i].TextureCoords.X1) *0.5 ;
        BarWeaponIcon[i].OffsetX =  IconOffset;

        if(bIsGhost)
        { // Use the grey color if this is a ghost
            BarBorder[i].Tints[0] = HudColorNormal;
            BarBorder[i].Tints[1] = HudColorNormal;
        } else {
            BarBorder[i].Tints[0] = HudColorRed;
            BarBorder[i].Tints[1] = HudColorBlue;
        }

        BarBorder[i].OffsetY = 0;
        BarWeaponIcon[i].OffsetY = default.BarWeaponIcon[i].OffsetY;

        if( !WI.bDefined )
        {
            BarWeaponStates[i].HasWeapon = false;
            if ( bShowMissingWeaponInfo )
            {
                if ( BarWeaponIcon[i].Tints[TeamIndex] != HudColorBlack )
                {
                    BarWeaponIcon[i].WidgetTexture = default.BarWeaponIcon[i].WidgetTexture;
                    BarWeaponIcon[i].TextureCoords = default.BarWeaponIcon[i].TextureCoords;
                    BarWeaponIcon[i].TextureScale = default.BarWeaponIcon[i].TextureScale;
                    BarWeaponIcon[i].Tints[TeamIndex] = HudColorBlack;
                    BarWeaponIconAnim[i] = 0;
                }
                DrawSpriteWidget( C, BarBorder[i] );
                DrawSpriteWidget( C, BarWeaponIcon[i] ); // FIXME- have combined version
            }
       }
        else
        {
            if( !BarWeaponStates[i].HasWeapon )
            {
                // just picked this weapon up!
                BarWeaponStates[i].PickupTimer = Level.TimeSeconds;
                BarWeaponStates[i].HasWeapon = true;
            }

            BarBorderAmmoIndicator[i].PosX = BarBorder[i].PosX;
            BarBorderAmmoIndicator[i].OffsetY = 0;
            BarWeaponIcon[i].WidgetTexture = WIT.IconMaterial;
            BarWeaponIcon[i].TextureCoords = WIT.IconCoords;

            BarBorderAmmoIndicator[i].Scale = WI.AmmoStatus;
            BarWeaponIcon[i].Tints[TeamIndex] = HudColorNormal;

            if( BarWeaponIconAnim[i] == 0 )
            {
                if ( BarWeaponStates[i].PickupTimer > Level.TimeSeconds - 0.6 )
                {
                   if ( BarWeaponStates[i].PickupTimer > Level.TimeSeconds - 0.3 )
                   {
                        BarWeaponIcon[i].TextureScale = default.BarWeaponIcon[i].TextureScale * (1 + 1.3 * (Level.TimeSeconds - BarWeaponStates[i].PickupTimer));
                        BarWeaponIcon[i].OffsetX =  IconOffset - IconOffset * ( Level.TimeSeconds - BarWeaponStates[i].PickupTimer );
                   }
                   else
                   {
                        BarWeaponIcon[i].TextureScale = default.BarWeaponIcon[i].TextureScale * (1 + 1.3 * (BarWeaponStates[i].PickupTimer + 0.6 - Level.TimeSeconds));
                        BarWeaponIcon[i].OffsetX = IconOffset - IconOffset * (BarWeaponStates[i].PickupTimer + 0.6 - Level.TimeSeconds);
                   }
                }
                else
                {
                    BarWeaponIconAnim[i] = 1;
                    BarWeaponIcon[i].TextureScale = default.BarWeaponIcon[i].TextureScale;
                }
            }

            if (WIT.Weapon == PendingWeapon && !bIsGhost)
            {
                // Change color to highlight and possibly changeTexture or animate it
                BarBorder[i].Tints[TeamIndex] = HudColorHighLight;
                BarBorder[i].OffsetY = -10;
                BarBorderAmmoIndicator[i].OffsetY = -10;
                BarWeaponIcon[i].OffsetY += -10;
            }
            if ( ExtraWeapon[i] == 1 )
            {
                if ( WIT.Weapon == PendingWeapon && !bIsGhost)
                {
                    BarBorder[i].Tints[0] = HudColorRed;
                    BarBorder[i].Tints[1] = HudColorBlue;
                    BarBorder[i].OffsetY = 0;
                    BarBorder[i].TextureCoords.Y1 = 80;
                    DrawSpriteWidget( C, BarBorder[i] );
                    BarBorder[i].TextureCoords.Y1 = 39;
                    BarBorder[i].OffsetY = -10;
                    BarBorder[i].Tints[TeamIndex] = HudColorHighLight;
                }
                else
                {
                    BarBorder[i].OffsetY = -52;
                    BarBorder[i].TextureCoords.Y2 = 48;
                    DrawSpriteWidget( C, BarBorder[i] );
                    BarBorder[i].TextureCoords.Y2 = 93;
                    BarBorder[i].OffsetY = 0;
                }
            }
            DrawSpriteWidget( C, BarBorder[i] );
            DrawSpriteWidget( C, BarBorderAmmoIndicator[i] );
            DrawSpriteWidget( C, BarWeaponIcon[i] );
       }
    }
}


simulated function DrawHudPassA (Canvas C)
{
    local Pawn RealPawnOwner;
    local class<Ammunition> AmmoClass;

    local bool bIsGhost;
    local PlayerReplicationInfo Master;

    if ( PRIIsGhost(PawnOwnerPRI) )
    {
        bIsGhost = true;
        Master = PRIGetMaster(PawnOwnerPRI);
    }

    ZoomFadeOut(C);

    if ( PawnOwner != None )
    {
        if( !bIsGhost && bShowWeaponInfo && (PawnOwner.Weapon != None) )
        {
            if ( PawnOwner.Weapon.bShowChargingBar )
                DrawChargeBar(C);

            DrawSpriteWidget( C, HudBorderAmmo );

            if( PawnOwner.Weapon != None )
            {
                AmmoClass = PawnOwner.Weapon.GetAmmoClass(0);
                if ( (AmmoClass != None) && (AmmoClass.Default.IconMaterial != None) )
                {
                    if( (CurAmmoPrimary/MaxAmmoPrimary) < 0.15)
                    {
                        DrawSpriteWidget(C, HudAmmoALERT);
                        HudAmmoALERT.Tints[TeamIndex] = HudColorTeam[TeamIndex];
                        AmmoIcon.WidgetTexture = Material'HudContent.Generic.HUDPulse';
                    }
                    else
                    {
                        AmmoIcon.WidgetTexture = AmmoClass.default.IconMaterial;
                    }

                    AmmoIcon.TextureCoords = AmmoClass.Default.IconCoords;
                    DrawSpriteWidget (C, AmmoIcon);
                }
            }
            DrawNumericWidget( C, DigitsAmmo, DigitsBig);
        }

        if ( bShowWeaponBar && (PawnOwner.Weapon != None || bIsGhost) )
            DrawWeaponBar(C);

        if( bShowPersonalInfo )
        {
            if ( Vehicle(PawnOwner) != None && Vehicle(PawnOwner).Driver != None )
            {
                if (Vehicle(PawnOwner).bShowChargingBar)
                    DrawVehicleChargeBar(C);
                RealPawnOwner = PawnOwner;
                PawnOwner = Vehicle(PawnOwner).Driver;
            }

            DrawHUDAnimWidget( HudBorderHealthIcon, default.HudBorderHealthIcon.TextureScale, LastHealthPickupTime, 0.6, 0.6);
            DrawSpriteWidget( C, HudBorderHealth );

            if(CurHealth/PawnOwner.HealthMax < 0.26)
            {
                HudHealthALERT.Tints[TeamIndex] = HudColorTeam[TeamIndex];
                DrawSpriteWidget( C, HudHealthALERT);
                HudBorderHealthIcon.WidgetTexture = Material'HudContent.Generic.HUDPulse';
            }
            else
                HudBorderHealthIcon.WidgetTexture = default.HudBorderHealth.WidgetTexture;

            DrawSpriteWidget( C, HudBorderHealthIcon);

            if( CurHealth < LastHealth )
                LastDamagedHealth = Level.TimeSeconds;

            DrawHUDAnimDigit( DigitsHealth, default.DigitsHealth.TextureScale, LastDamagedHealth, 0.8, default.DigitsHealth.Tints[TeamIndex], HudColorHighLight);
            DrawNumericWidget( C, DigitsHealth, DigitsBig);

            if(CurHealth > 999)
            {
                DigitsHealth.OffsetX=220;
                DigitsHealth.OffsetY=-35;
                DigitsHealth.TextureScale=0.39;
            }
            else
            {
                DigitsHealth.OffsetX = default.DigitsHealth.OffsetX;
                DigitsHealth.OffsetY = default.DigitsHealth.OffsetY;
                DigitsHealth.TextureScale = default.DigitsHealth.TextureScale;
            }

            if (RealPawnOwner != None)
            {
                PawnOwner = RealPawnOwner;

                DrawSpriteWidget( C, HudBorderVehicleHealth );

                if (CurVehicleHealth/PawnOwner.HealthMax < 0.26)
                {
                    HudVehicleHealthALERT.Tints[TeamIndex] = HudColorTeam[TeamIndex];
                    DrawSpriteWidget(C, HudVehicleHealthALERT);
                    HudBorderVehicleHealthIcon.WidgetTexture = Material'HudContent.Generic.HUDPulse';
                }
                else
                    HudBorderVehicleHealthIcon.WidgetTexture = default.HudBorderVehicleHealth.WidgetTexture;

                DrawSpriteWidget(C, HudBorderVehicleHealthIcon);

                if (CurVehicleHealth < LastVehicleHealth )
                    LastDamagedVehicleHealth = Level.TimeSeconds;

                DrawHUDAnimDigit(DigitsVehicleHealth, default.DigitsVehicleHealth.TextureScale, LastDamagedVehicleHealth, 0.8, default.DigitsVehicleHealth.Tints[TeamIndex], HudColorHighLight);
                DrawNumericWidget(C, DigitsVehicleHealth, DigitsBig);

                if (CurVehicleHealth > 999)
                {
                    DigitsVehicleHealth.OffsetX = 220;
                    DigitsVehicleHealth.OffsetY = -35;
                    DigitsVehicleHealth.TextureScale = 0.39;
                }
                else
                {
                    DigitsVehicleHealth.OffsetX = default.DigitsVehicleHealth.OffsetX;
                    DigitsVehicleHealth.OffsetY = default.DigitsVehicleHealth.OffsetY;
                    DigitsVehicleHealth.TextureScale = default.DigitsVehicleHealth.TextureScale;
                }
            }

            DrawAdrenaline(C);
        }
    }

    UpdateRankAndSpread(C);
    DrawTaggedPlayers(C);
    DrawUDamage(C);

    if(bDrawTimer)
        DrawTimer(C);

    // Temp Drawwwith Hud Colors
    if(bIsGhost)
    {
        HudBorderShield.Tints[0] = HudColorNormal;
        HudBorderShield.Tints[1] = HudColorNormal;
        HudBorderHealth.Tints[0] = HudColorNormal;
        HudBorderHealth.Tints[1] = HudColorNormal;
        HudBorderVehicleHealth.Tints[0] = HudColorNormal;
        HudBorderVehicleHealth.Tints[1] = HudColorNormal;
        HudBorderAmmo.Tints[0] = HudColorNormal;
        HudBorderAmmo.Tints[1] = HudColorNormal;
    } else {
        HudBorderShield.Tints[0] = HudColorRed;
        HudBorderShield.Tints[1] = HudColorBlue;
        HudBorderHealth.Tints[0] = HudColorRed;
        HudBorderHealth.Tints[1] = HudColorBlue;
        HudBorderVehicleHealth.Tints[0] = HudColorRed;
        HudBorderVehicleHealth.Tints[1] = HudColorBlue;
        HudBorderAmmo.Tints[0] = HudColorRed;
        HudBorderAmmo.Tints[1] = HudColorBlue;
    }

    if( bShowPersonalInfo && (CurShield > 0) )
    {
        DrawSpriteWidget( C, HudBorderShield );
        DrawSpriteWidget( C, HudBorderShieldIcon);
        DrawNumericWidget( C, DigitsShield, DigitsBig);
        DrawHUDAnimWidget( HudBorderShieldIcon, default.HudBorderShieldIcon.TextureScale, LastArmorPickupTime, 0.6, 0.6);
    }

    if( Level.TimeSeconds - LastVoiceGainTime < 0.333 )
        DisplayVoiceGain(C);

    DisplayLocalMessages (C);
}

defaultproperties
{
     myOtherGhostsNum=(RenderStyle=STY_Alpha,TextureScale=0.300000,DrawPivot=DP_MiddleLeft,OffsetX=30,OffsetY=170,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
     myGhostMasterNum=(RenderStyle=STY_Alpha,TextureScale=0.300000,DrawPivot=DP_MiddleLeft,OffsetX=30,OffsetY=132,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
     myGhostsNum=(RenderStyle=STY_Alpha,TextureScale=0.490000,DrawPivot=DP_MiddleLeft,PosX=0.015000,OffsetX=70,OffsetY=94,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
     myFavor=(RenderStyle=STY_Alpha,TextureScale=0.490000,DrawPivot=DP_MiddleLeft,PosX=0.015000,OffsetX=70,OffsetY=94,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
     FavorIcon=(WidgetTexture=Texture'OLGhostMasterTex.Icons.favor',RenderStyle=STY_Alpha,TextureCoords=(X1=0,Y1=0,X2=128,Y2=128),TextureScale=0.220000,OffsetX=0,OffsetY=134,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
     FavorBackgroundDisc=(WidgetTexture=Texture'HUDContent.Generic.HUD',RenderStyle=STY_Alpha,TextureCoords=(X1=119,Y1=258,X2=173,Y2=313),TextureScale=0.530000,OffsetY=59,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))

     GhostBeaconMat=TeamSymbols.TeamBeaconT
     GhostBeaconColor=(B=255,G=255,A=255)

     MasterBeaconMat=TeamSymbols.TeamBeaconT
     MasterBeaconColor=(B=255,G=255,A=255)

     TaggedBeaconMat=TeamSymbols.TeamBeaconT
     TaggedBeaconColor=(R=255,A=255)

     ObstructedTaggedColor=(R=255,A=255)

     IP_Bracket_Open="["
     IP_Bracket_Close="]"
     MetersString="m"
     ObjectiveScale=1.000000
}
