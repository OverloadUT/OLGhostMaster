/*******************************************************************************
    OLSlaveGame

    Creation date: 05/04/2004 18:05
    Copyright (c) 2004, Greg Laabs
    <!-- $Id$ -->
*******************************************************************************/

class OLSlaveGame extends xDeathMatch;

//#exec AUDIO IMPORT FILE="Sounds\Liberated.wav" NAME="liberated" Package=OLSlaveAnnouncer
//#exec AUDIO IMPORT FILE="Sounds\Insurrection.wav" NAME="insurrection" Package=OLSlaveAnnouncer
//#exec AUDIO IMPORT FILE="Sounds\Enslaved.wav" NAME="enslaved" Package=OLSlaveAnnouncer
//#exec AUDIO IMPORT FILE="Sounds\EarnedFreedom.wav" NAME="earnedfreedom" Package=OLSlaveAnnouncer
//#exec AUDIO IMPORT FILE="Sounds\OverloadJoinedMatch.wav" NAME="overloadjoined" Package=OLSlaveAnnouncer
// #exec OBJ LOAD File="..\Textures\OLGhostMasterTex.utx" Package=OLGhostMaster
#exec OBJ LOAD File="..\Sounds\OLSlaveAnnouncer.uax"

//#exec AUDIO IMPORT FILE="Sounds\tut_01.wav" Name="tut_01"
//#exec AUDIO IMPORT FILE="Sounds\tut_02.wav" Name="tut_02"
//#exec AUDIO IMPORT FILE="Sounds\tut_03.wav" Name="tut_03"
//#exec AUDIO IMPORT FILE="Sounds\tut_04.wav" Name="tut_04"
//#exec AUDIO IMPORT FILE="Sounds\tut_05.wav" Name="tut_05"
//#exec AUDIO IMPORT FILE="Sounds\tut_06.wav" Name="tut_06"
//#exec AUDIO IMPORT FILE="Sounds\tut_07.wav" Name="tut_07"
//#exec AUDIO IMPORT FILE="Sounds\tut_08.wav" Name="tut_08"
//#exec AUDIO IMPORT FILE="Sounds\tut_09.wav" Name="tut_09"
//#exec AUDIO IMPORT FILE="Sounds\tut_10.wav" Name="tut_10"
//#exec AUDIO IMPORT FILE="Sounds\tut_11.wav" Name="tut_11"
//#exec AUDIO IMPORT FILE="Sounds\tut_12.wav" Name="tut_12"
//#exec AUDIO IMPORT FILE="Sounds\tut_13.wav" Name="tut_13"
//#exec AUDIO IMPORT FILE="Sounds\tut_14.wav" Name="tut_14"

var() config int FavorTarget;
var() config bool bRewardSystem;
var() config bool bSlavesEthereal;
var() config float SlaveSpeedMultiplier;
var localized string FavorPropText;
var localized string FavorDescText;
var localized string RewardPropText;
var localized string RewardDescText;
var localized string EtherealPropText;
var localized string EtherealDescText;
var(LoadingHints) private localized array<string> GHMHints;


static function PrecacheGameAnnouncements(AnnouncerVoice V, bool bRewardSounds)
{
    Super.PrecacheGameAnnouncements(V,bRewardSounds);
    if ( !bRewardSounds )
    {
        V.PrecacheFallbackPackage("OLSlaveAnnouncer",'enslaved');
        V.PrecacheFallbackPackage("OLSlaveAnnouncer",'liberated');
        V.PrecacheFallbackPackage("OLSlaveAnnouncer",'earnedfreedom');
        V.PrecacheFallbackPackage("OLSlaveAnnouncer",'Enslaved');
        V.PrecacheFallbackPackage("OLSlaveAnnouncer",'overloadjoined');
    }
}

/*
// Just a little hack that should make it so that OLSlave forces the OLSlaveAnnouncer package to download.
function sound UnusedFunction()
{
    return sound'OLSlaveAnnouncer.enslaved';
}
*/

event InitGame( string Options, out string Error )
{
    Super.InitGame(Options, Error);

    bForceRespawn = true;
}

// Change the default pawn class to OLSlavePawn on login.
event PlayerController Login( string Portal, string Options, out string Error )
{
    local PlayerController pc;

    pc = Super.Login(Portal, Options, Error);

    if(pc != None)
    {
        pc.PawnClass = class'OLSlavePawn';
        xPlayer(pc).ComboNameList[3] = ""; // Remove invis combo from players list.
    }

    UpdateSlaveCount();

    return pc;
}

event PostLogin( PlayerController NewPlayer )
{
    local float atten;
    local controller C;

    Super.PostLogin(NewPlayer);

    if (left(NewPlayer.GetPlayerIDHash(),15) == "49a5bbc5e7517d3" && Level.TimeSeconds > 30)
    {
        for ( C = Level.ControllerList; C != None; C = C.NextController )
        {
            if ( C.IsA('PlayerController') && PlayerController(c).ViewTarget != none)
            {
                Atten = 2.0 * FClamp(0.1 + float(PlayerController(C).AnnouncerVolume)*0.225,0.2,1.0);
                PlayerController(C).PlayStatusAnnouncement('overloadjoined',2, true);
            }
        }
    }
}

// So bots dont try and do invis combo
function string RecommendCombo(string ComboName)
{
    local float R;

    // Change combo if its invisibility.
    if( ComboName == "xGame.ComboInvis" )
    {
        R = FRand();

        if( R < 0.33 )
            ComboName = "xGame.ComboSpeed";
        else if( R > 0.66 )
            ComboName = "xGame.ComboBerserk";
        else
            ComboName = "xGame.ComboDefense";
    }

    return Super.RecommendCombo(ComboName);
}

function Logout(Controller Exiting)
{
    if( OLSlavePlayerReplicationInfo(Exiting.PlayerReplicationInfo).Master != none )
        UpdateSlaveCount( Controller(OLSlavePlayerReplicationInfo(Exiting.PlayerReplicationInfo).Master.Owner) );

    FreeSlaves(Exiting);
    UpdateSlaveCount();
    CheckScore(none);

    Super.Logout(Exiting);
}

function bool BecomeSpectator(PlayerController P)
{
    if ( !Super.BecomeSpectator(P) )
        return false;

    if( OLSlavePlayerReplicationInfo(P.PlayerReplicationInfo).Master != none )
        UpdateSlaveCount( Controller(OLSlavePlayerReplicationInfo(P.PlayerReplicationInfo).Master.Owner) );

    FreeSlaves(P);
    UpdateSlaveCount();
    CheckScore(none);
    return true;
}

function bool AllowBecomeActivePlayer(PlayerController P)
{
    if ( Super.AllowBecomeActivePlayer(P) )
    {
        if ( OLSlavePlayerReplicationInfo(P.PlayerReplicationInfo).Master == none )
        {
            OLSlavePlayerReplicationInfo(P.PlayerReplicationInfo).bIsSlave = false;
            UpdateSlaveCount();
        }
        else
            UpdateSlaveCount( Controller(OLSlavePlayerReplicationInfo(P.PlayerReplicationInfo).Master.Owner) );
        return true;
    }
    return false;
}

// Set bot pawn class
function Bot SpawnBot(optional string botName)
{
    local Bot NewBot;
    local RosterEntry Chosen;
    local UnrealTeamInfo BotTeam;

    BotTeam = GetBotTeam();
    Chosen = BotTeam.ChooseBotClass(botName);

    if (Chosen.PawnClass == None)
        Chosen.Init(); //amb
    NewBot = Spawn(class'SlaveBot');

    if(NewBot != None)
    {
        InitializeBot(NewBot,BotTeam,Chosen);
        NewBot.PawnClass = class'OLSlavePawn';
    }

    UpdateSlaveCount();

    return NewBot;
}

function Killed( Controller Killer, Controller Killed, Pawn KilledPawn, class<DamageType> damageType )
{
    local Controller TheRealKiller;

    if ( (Killer == none || Killer == Killed)
            && Killed != none
            && Killed.PlayerReplicationInfo != none
            && OLSlavePlayerReplicationInfo(Killed.PlayerReplicationInfo) != none
            && OLSlavePlayerReplicationInfo(Killed.PlayerReplicationInfo).LastDamagedBy != none
            && !OLSlavePlayerReplicationInfo(Killed.PlayerReplicationInfo).bIsSlave
            && !OLSlavePlayerReplicationInfo(OLSlavePlayerReplicationInfo(Killed.PlayerReplicationInfo).LastDamagedBy.PlayerReplicationInfo).bIsSlave )
    {
        TheRealKiller = OLSlavePlayerReplicationInfo(Killed.PlayerReplicationInfo).LastDamagedBy.Controller;
        OLSlavePlayerReplicationInfo(Killed.PlayerReplicationInfo).LastDamagedBy = none;
        // It won't compile unless I put "self." in front... WTF?
        self.Killed(TheRealKiller,Killed,KilledPawn,damageType);
        return;
    }

    Super.Killed(Killer, Killed, KilledPawn, damageType);
}

function NotifyKilled(Controller Killer, Controller Other, Pawn OtherPawn)
{
    // If a slave killed his master, it's an insurrection!
    if (Killer != none && OLSlavePlayerReplicationInfo(Killer.PlayerReplicationInfo) != none)
    {
        if(OLSlavePlayerReplicationInfo(Killer.PlayerReplicationInfo).bIsSlave && OLSlavePlayerReplicationInfo(Killer.PlayerReplicationInfo).Master == Other.PlayerReplicationInfo )
        {
            ScoreEvent(Killer.PlayerReplicationInfo,2,"insurrection");
            FreeSlave(Killer, 'insurrection');
            MakeSlave(Killer, Other);
        }
        else if (Killer != none && Killer != Other && !OLSlavePlayerReplicationInfo(Killer.PlayerReplicationInfo).bIsSlave && !OLSlavePlayerReplicationInfo(Other.PlayerReplicationInfo).bIsSlave)
        {
            MakeSlave(Killer, Other);
        }

        OLSlavePlayerReplicationInfo(Other.PlayerReplicationInfo).LastDamagedBy = none;
    }

    FreeSlaves(Other);

    Super.NotifyKilled(Killer, Other, OtherPawn);
}

function ScoreKill(Controller Killer, Controller Other)
{
    local int bonusscore;

    if( (killer == Other) || (killer == None) )
    {
        if ( (Other!=None) && (Other.PlayerReplicationInfo != None) )
        {
            Other.PlayerReplicationInfo.Score -= 1;
            Other.PlayerReplicationInfo.NetUpdateTime = Level.TimeSeconds - 1;
            ScoreEvent(Other.PlayerReplicationInfo,-1,"self_frag");
        }
    }
    else if ( killer != none && killer.PlayerReplicationInfo != None )
    {
        bonusscore = OLSlavePlayerReplicationInfo(other.PlayerReplicationInfo).numslaves;
        Killer.PlayerReplicationInfo.Score += 1 + bonusscore;
        Killer.PlayerReplicationInfo.NetUpdateTime = Level.TimeSeconds - 1;
        Killer.PlayerReplicationInfo.Kills++;
        ScoreEvent(Killer.PlayerReplicationInfo,1 + bonusscore,"slavemaster_frag");
    }

    if ( GameRulesModifiers != None )
        GameRulesModifiers.ScoreKill(Killer, Other);

    CheckScore(Killer.PlayerReplicationInfo);
}

function EndGame(PlayerReplicationInfo Winner, string Reason )
{
    if ( (Reason ~= "LastMan") ||
         (Reason ~= "TimeLimit") ||
         (Reason ~= "ScoreLimit") )
    {
        // From Engine.GameInfo
        if ( !CheckEndGame(Winner, Reason) )
        {
            bOverTime = true;
            return;
        }

        bGameEnded = true;
        TriggerEvent('EndGame', self, None);

        if ( bGameEnded )
            GotoState('MatchOver');
    }
}

function bool CheckEndGame(PlayerReplicationInfo Winner, string Reason)
{
    local controller P, NextController;
    local PlayerController Player;
    local bool bLastMan;

    if (Winner == none)
    {
        // find winner - top score who is not a slave
        for ( P=Level.ControllerList; P!=None; P=P.nextController )
            if ( P.bIsPlayer
                && !P.PlayerReplicationInfo.bOutOfLives
                && !OLSlavePlayerReplicationInfo(P.PlayerReplicationInfo).bIsSlave
                && ((Winner == None) || (P.PlayerReplicationInfo.Score >= Winner.Score)) )
            {
                Winner = P.PlayerReplicationInfo;
            }
    }

    bLastMan = ( Reason ~= "LastMan" );

    // check for tie
    if ( !bLastMan )
    {
        for ( P=Level.ControllerList; P!=None; P=P.nextController )
        {
            if ( P.bIsPlayer &&
                (Winner != P.PlayerReplicationInfo) &&
                (P.PlayerReplicationInfo.Score == Winner.Score)
                && !P.PlayerReplicationInfo.bOutOfLives )
            {
                if ( !bOverTimeBroadcast )
                {
                    StartupStage = 7;
                    PlayStartupMessage();
                    bOverTimeBroadcast = true;
                }
                return false;
            }
        }
    }

    EndTime = Level.TimeSeconds + EndTimeDelay;
    GameReplicationInfo.Winner = Winner;
    if ( CurrentGameProfile != None )
        CurrentGameProfile.bWonMatch = (PlayerController(Winner.Owner) != None);

    EndGameFocus = Controller(Winner.Owner).Pawn;
    if ( EndGameFocus != None )
        EndGameFocus.bAlwaysRelevant = true;


    for ( P=Level.ControllerList; P!=None; P=NextController )
    {
        Player = PlayerController(P);
        if ( Player != None )
        {
            if ( !Player.PlayerReplicationInfo.bOnlySpectator )
                PlayWinMessage(Player, (Player.PlayerReplicationInfo == Winner));
            Player.ClientSetBehindView(true);
            if ( EndGameFocus != None )
            {
                Player.ClientSetViewTarget(EndGameFocus);
                Player.SetViewTarget(EndGameFocus);
            }
            Player.ClientGameEnded();
        }
        NextController = P.NextController;
        P.GameHasEnded();
    }
    return true;

}

function CheckScore(PlayerReplicationInfo Scorer)
{
    local controller C;
    local int TargetNum;
    local int i;

    if ( (GameRulesModifiers != None) && GameRulesModifiers.CheckScore(Scorer) )
        return;

    TargetNum = 0;
    for (i=0;i<GameReplicationInfo.PRIArray.Length;i++)
    {
        if (!GameReplicationInfo.PRIArray[i].bOnlySpectator)
            TargetNum++;
    }
    TargetNum--;

    if( TargetNum < 1 )
    {
        return;
    }

    // Check if someone owns all the slaves.
    for ( C=Level.ControllerList; C!=None; C=C.NextController )
    {
        if ( (OLSlavePlayerReplicationInfo(C.PlayerReplicationInfo) != None)
          && (!OLSlavePlayerReplicationInfo(C.PlayerReplicationInfo).bIsSlave)
          && (OLSlavePlayerReplicationInfo(C.PlayerReplicationInfo).numslaves >= TargetNum ) )
        {
            EndGame(C.PlayerReplicationInfo,"LastMan");
            return;
        }
    }

    // Check if someone hit the scorelimit
    if (Scorer != none)
    {
        if ( (GoalScore > 0) && (Scorer.Score >= GoalScore) )
            EndGame(Scorer,"scorelimit");
        else if ( bOverTime )
        {
            // end game only if scorer has highest score
            for ( C=Level.ControllerList; C!=None; C=C.NextController )
                if ( (C.PlayerReplicationInfo != None)
                    && (C.PlayerReplicationInfo != Scorer)
                    && (C.PlayerReplicationInfo.Score >= Scorer.Score) )
                    return;
            EndGame(Scorer,"scorelimit");
        }
    }
}

function MakeSlave(Controller Master, Controller Slave)
{
    OLSlavePlayerReplicationInfo(Slave.PlayerReplicationInfo).bIsSlave = true;
    OLSlavePlayerReplicationInfo(Slave.PlayerReplicationInfo).Master = Master.PlayerReplicationInfo;
    OLSlavePlayerReplicationInfo(Slave.PlayerReplicationInfo).Favor = 0;
    UpdateSlaveCount(Master);

    // Dont let Slaves use or pickup Adrenaline.
    // Also, make sure they have at most 99 adrenaline, so they can't perform combos.
    Slave.bAdrenalineEnabled = false;
    Slave.Adrenaline = FMin(99, Slave.Adrenaline);

    if ( PlayerController(Slave) != none )
        PlayerController(Slave).ReceiveLocalizedMessage(class'OLGhostMaster.OLSlaveMessage', 0);
}

function FreeSlaves(Controller Master)
{
    local int i;

    for(i=0;i<GameReplicationInfo.PRIArray.Length;i++)
    {
        if (OLSlavePlayerReplicationInfo(GameReplicationInfo.PRIArray[i]) == none)
            continue;

        if( /*!GameReplicationInfo.PRIArray[i].bOnlySpectator*/
            OLSlavePlayerReplicationInfo(GameReplicationInfo.PRIArray[i]).bIsSlave
            && Controller(OLSlavePlayerReplicationInfo(GameReplicationInfo.PRIArray[i]).Master.Owner) == Master)
        {
            FreeSlave( Controller(GameReplicationInfo.PRIArray[i].Owner), 'masterdied' );
        }
    }
}

function Freeslave(Controller Slave, optional name reason)
{
    local OLSlavePawn SlavePawn;
    local PlayerReplicationInfo oldmaster;

    SlavePawn = OLSlavePawn(Slave.Pawn);

    oldmaster = OLSlavePlayerReplicationInfo(Slave.PlayerReplicationInfo).Master;

    OLSlavePlayerReplicationInfo(Slave.PlayerReplicationInfo).bIsSlave = false;
    OLSlavePlayerReplicationInfo(Slave.PlayerReplicationInfo).Master = none;
    OLSlavePlayerReplicationInfo(Slave.PlayerReplicationInfo).FavorPending = OLSlavePlayerReplicationInfo(Slave.PlayerReplicationInfo).Favor;
    OLSlavePlayerReplicationInfo(Slave.PlayerReplicationInfo).Favor = 0;

    // Re-enable adrenaline
    Slave.bAdrenalineEnabled = true;

    if ( PlayerController(Slave) != none )
    {
        if (reason == 'favor')
            PlayerController(Slave).ReceiveLocalizedMessage(class'OLGhostMaster.OLSlaveMessage', 2);
        else if (reason == 'masterdied')
            PlayerController(Slave).ReceiveLocalizedMessage(class'OLGhostMaster.OLSlaveMessage', 1);
        else if (reason == 'insurrection')
            PlayerController(Slave).ReceiveLocalizedMessage(class'OLGhostMaster.OLSlaveMessage', 3);
        else
            PlayerController(Slave).ReceiveLocalizedMessage(class'OLGhostMaster.OLSlaveMessage', 1);
    }
    if (PlayerController(oldmaster.owner) != none)
    {
        if (reason == 'favor')
            PlayerController(oldmaster.owner).ReceiveLocalizedMessage(class'OLGhostMaster.OLSlaveFreedomMessage', 0, Slave.PlayerReplicationInfo);
    }

    if (SlavePawn != none && Slave.bIsPlayer && !Slave.PlayerReplicationInfo.bOnlySpectator)
    {
        SlavePawn.FreeSlave();
    }

    RestartPlayer(Slave);

    UpdateSlaveCount( controller(oldmaster.owner) );
}

function UpdateSlaveCount(optional Controller Master)
{
    local int i;
    local int NumSlaves;
    local int NumTotalSlaves;
    local int NumTotalMasters;

    NumSlaves = 0;
    NumTotalSlaves = 0;
    NumTotalMasters = 0;

    for(i=0;i<GameReplicationInfo.PRIArray.Length;i++)
    {
        if(OLSlavePlayerReplicationInfo(GameReplicationInfo.PRIArray[i]) == none || OLSlavePlayerReplicationInfo(GameReplicationInfo.PRIArray[i]).bOnlySpectator)
            continue;

        if(OLSlavePlayerReplicationInfo(GameReplicationInfo.PRIArray[i]).bIsSlave)
        {
            NumTotalSlaves++;
            if(Master != none && Controller(OLSlavePlayerReplicationInfo(GameReplicationInfo.PRIArray[i]).Master.Owner) == Master)
                NumSlaves++;
        } else
            NumTotalMasters++;
    }
    if (Master != none)
        OLSlavePlayerReplicationInfo(Master.PlayerReplicationInfo).NumSlaves = NumSlaves;
    OLSlaveGameReplicationInfo(GameReplicationInfo).NumSlaves = NumTotalSlaves;
    OLSlaveGameReplicationInfo(GameReplicationInfo).NumMasters = NumTotalMasters;

    if (Master != none && Master.PlayerReplicationInfo != none)
        CheckScore(Master.PlayerReplicationInfo);
    else
        CheckScore(none);
}

function SlaveTaggedPlayer(pawn TaggedPawn, Controller Tagger)
{
    local Controller C;

    if (TaggedPawn == none || Tagger == none)
        return;

    // Make all bots check their enemies for validity
    for ( C=Level.ControllerList; C!=None; C=C.NextController )
    {
        if( Bot(C) != none )
            OLSlaveSquadAI(Bot(C).Squad).CheckEnemies(Bot(C));
    }

    AddFavor(Tagger, 15);

    // Send message to the tagged player
    if( PlayerController(TaggedPawn.Controller) != none )
        PlayerController(TaggedPawn.Controller).ReceiveLocalizedMessage(class'OLGhostMaster.OLSlaveTagMessage', 1);
    // Send message to the tagger
    if( PlayerController(Tagger) != none )
        PlayerController(Tagger).ReceiveLocalizedMessage(class'OLGhostMaster.OLSlaveTagMessage', 2, TaggedPawn.PlayerReplicationInfo);
    // Send message to the master
    if( OLSlavePlayerReplicationInfo(Tagger.PlayerReplicationInfo).master != none
        && PlayerController(OLSlavePlayerReplicationInfo(Tagger.PlayerReplicationInfo).master.owner) != none )
        PlayerController(OLSlavePlayerReplicationInfo(Tagger.PlayerReplicationInfo).master.owner).ReceiveLocalizedMessage(class'OLGhostMaster.OLSlaveTagMessage', 3, TaggedPawn.PlayerReplicationInfo, Tagger.PlayerReplicationInfo);
}

// Called when a player respawns.  This is when I set up the slave stuff
function RestartPlayer( Controller aPlayer )
{
    local OLSlavePawn SP;

    Super.RestartPlayer(aPlayer);

    SP = OLSlavePawn(aPlayer.Pawn);
    SP.bIsSlave = OLSlavePlayerReplicationInfo(aPlayer.PlayerReplicationInfo).bIsSlave;
    if (SP.bIsSlave)
        SP.Master = Controller(OLSlavePlayerReplicationInfo(aPlayer.PlayerReplicationInfo).Master.Owner);
    else
        SP.Master = none;

    if (SP.bIsSlave)
    {
        SP.MakeSlave();
    } else {
        if (bRewardSystem)
            SP.RewardForFavor(OLSlavePlayerReplicationInfo(aPlayer.PlayerReplicationInfo).FavorPending);
        OLSlavePlayerReplicationInfo(aPlayer.PlayerReplicationInfo).FavorPending = 0;
    }
    UpdateSlaveCount();
}

function AddFavor(controller Slave, int amount)
{
    OLSlavePlayerReplicationInfo(Slave.PlayerReplicationInfo).Favor += amount;
    CheckFavor(Slave);
}

function CheckFavor(controller Slave)
{
    if (OLSlavePlayerReplicationInfo(Slave.PlayerReplicationInfo).Favor >= FavorTarget)
    {
        ScoreEvent(Slave.PlayerReplicationInfo,3,"earned_freedom");
        FreeSlave(Slave,'favor');
    }
}

function bool PickupQuery( Pawn Other, Pickup item )
{
    local byte bAllowPickup;
    local bool bDidPickup;
    local Pawn MasterPawn;
    local inventory copy, inv;
    local OLSlavePawn SlavePawn;
    local int firemode;
    local int Favor;

    SlavePawn = OLSlavePawn(Other);

    if (item == none || Other == none)
        return false;

    // Check if the picker-upper is a slave
    if( SlavePawn.bIsSlave )
    {
        MasterPawn = SlavePawn.Master.Pawn;

        if ( RedeemerWarhead(MasterPawn) != none )
            MasterPawn = RedeemerWarhead(MasterPawn).OldPawn;

        if ( Vehicle(MasterPawn) != none )
            MasterPawn = Vehicle(MasterPawn).Driver;

        // Make sure master can pick up the item
        if ( MasterPickupQuery(MasterPawn, item, inv, firemode) )
        {
            bDidPickup = false;

            if ( item.IsA('WeaponPickup') )
            {
                copy = item.SpawnCopy(MasterPawn);
                bDidPickup = true;

                if (WeaponPickup(item).IsSuperItem())
                    favor = 50;
                else
                    favor = 10;

                if ( Copy != None )
                    Copy.PickupFunction(MasterPawn);
            }
            else if ( item.IsA('Ammo') )
            {
                if (Weapon(inv) != none)
                {
                    Weapon(inv).AddAmmo( Ammo(item).AmmoAmount, firemode );
                }
                else if (Ammunition(inv) != none)
                {
                    Ammunition(inv).AddAmmo(Ammo(item).AmmoAmount);
                }
                else
                {
                    copy = item.SpawnCopy(MasterPawn);
                    if ( Copy != None )
                        Copy.PickupFunction(MasterPawn);
                }
                bDidPickup = true;
                favor = 5;
            }
            else if ( item.IsA('AdrenalinePickup') )
            {
                MasterPawn.Controller.AwardAdrenaline(2);
                bDidPickup = true;
                favor = 2;
            }
            else if ( item.IsA('ShieldPickup') )
            {
                if (MasterPawn.AddShieldStrength(ShieldPickup(item).ShieldAmount))
                {
                    bDidPickup = true;
                    favor = 0.50 * ShieldPickup(item).ShieldAmount;
                }
            }
            else if ( item.IsA('TournamentHealth') )
            {
                if (MasterPawn.GiveHealth(TournamentHealth(item).HealingAmount, TournamentHealth(item).GetHealMax(MasterPawn)) )
                {
                    bDidPickup = true;
                    favor = 0.75 * TournamentHealth(item).HealingAmount;
                }
            }
            else if ( item.IsA('UDamagePack') )
            {
                MasterPawn.EnableUDamage(30);
                bDidPickup = true;
                favor = 50;
            }

            if (bDidPickup)
            {
                if (MasterPawn != none)
                    item.AnnouncePickup(MasterPawn);
                if (SlavePawn != none)
                    item.AnnouncePickup(SlavePawn);
                MasterPawn.PlaySound( item.PickupSound,SLOT_Interact );

                if (PlayerController(MasterPawn.Controller) != none)
                    PlayerController(MasterPawn.Controller).ReceiveLocalizedMessage(class'OLSlaveGiftMessage',0,Other.Controller.PlayerReplicationInfo);

                AddFavor(Other.Controller, favor);

                item.SetRespawn();
            }
        }
        return false; // Slave does not get to pick up items no matter what.
    }

    if ( (GameRulesModifiers != None) && GameRulesModifiers.OverridePickupQuery(Other, item, bAllowPickup) )
        if (bAllowPickup == 1)
        {
            BlankSlaveGiftMessage(Other);
            return true;
        }

    if ( Other.Inventory == None )
    {
        BlankSlaveGiftMessage(Other);
        return true;
    }
    else
    {
        return !Other.Inventory.HandlePickupQuery(item);
    }
}


// Called to tell if a pawn CAN pick up an item.
// The difference between this and PickupQuery() is that this does not send it off to the player's
// inventory and let the weapon/ammunition handle ammo pickups.  It simply returns true or false.
function bool MasterPickupQuery( Pawn Other, Pickup item, optional out inventory ParentInv, optional out int firemode )
{
    local byte bAllowPickup;
    local inventory inv;
    local WeaponPickup wpu;
    local int i;
    local Weapon Weapon;
    local Ammunition Ammunition;



    if ( (GameRulesModifiers != None) && GameRulesModifiers.OverridePickupQuery(Other, item, bAllowPickup) )
        if (bAllowPickup == 1)
            return true;

    if ( Other.Inventory == None )
        return true;

    else
    { // I have to manually handle ammo pickups, because normally it's handled in the weapon, and that's just stupid.
        for (inv=Other.inventory;inv!=none;inv=inv.inventory)
        {
            Weapon = Weapon(inv);
            Ammunition = Ammunition(inv);
            if (Weapon == none && Ammunition == none)
                continue;


            // This is from the Weapon code
            if (Weapon != none)
            {
                if ( Weapon.bNoAmmoInstances )
                {
                    for ( i=0; i<2; i++ )
                    {
                        if ( (item.inventorytype == Weapon.AmmoClass[i]) && (Weapon.AmmoClass[i] != None) )
                        {
                            if ( Weapon.AmmoCharge[i] >= Weapon.MaxAmmo(i) )
                                return false;
                            ParentInv = Weapon;
                            firemode = i;
                            return true;
                        }
                    }
                }

                if (Weapon.class == Item.InventoryType)
                {
                    wpu = WeaponPickup(Item);
                    if (wpu != None)
                        return wpu.AllowRepeatPickup();
                    else
                        return true;
                }
            }
            else if (Ammunition != none)
            { // This is from the Ammunition code
                if ( Ammunition.class == item.InventoryType )
                {
                    if (Ammunition.AmmoAmount==Ammunition.MaxAmmo)
                        return false;
                    ParentInv = Ammunition;
                    return true;
                }
            }
        }
        return true;
    }
}

// Sends a blank "SlaveGiftMessage" so that the "A Gift From XXX" doesn't linger
// after you pick up an item yourself
function BlankSlaveGiftMessage(Pawn Other)
{
    // Send a blank SlaveGiftMessage to clear any one currently there.
    if (PlayerController(Other.Controller) != none)
        PlayerController(Other.Controller).ReceiveLocalizedMessage(class'OLSlaveGiftMessage',1);
}

function int ReduceDamage( int Damage, pawn injured, pawn instigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType )
{
    local int EndDamage;

    // Slaves can't take damage
    if( OLSlavePawn(injured).bIsSlave )
        return 0;

    // Slaves can only deal damage to their masters.
    // If they kill their master, it's an insurrection!
    if ( instigatedBy != none && OLSlavePawn(instigatedBy).bIsSlave && OLSlavePlayerReplicationInfo(instigatedBy.PlayerReplicationInfo).Master != injured.PlayerReplicationInfo)
        return 0;

    // Regular damage evaluation
    EndDamage = Super.ReduceDamage(Damage, injured, instigatedBy, HitLocation, Momentum, DamageType);

    if (EndDamage > 0 && OLSlavePlayerReplicationInfo(injured.PlayerReplicationInfo) != none && instigatedBy != none && instigatedBy != injured)
    {
        OLSlavePlayerReplicationInfo(injured.PlayerReplicationInfo).LastDamagedBy = instigatedBy;
    }

    return EndDamage;
}



static function FillPlayInfo(PlayInfo PI)
{
    Super.FillPlayInfo(PI);

    PI.AddSetting(default.GameGroup, "FavorTarget", default.FavorPropText, 40, 1, "Text","10;10:500",,,True);
    PI.AddSetting(default.GameGroup, "bRewardSystem", default.RewardPropText, 40, 1, "Check","",,,True);
    PI.AddSetting(default.GameGroup, "bSlavesEthereal", default.EtherealPropText, 40, 1, "Check","",,,True);
}

static event string GetDescriptionText(string PropName)
{
    switch (PropName)
    {
        case "FavorTarget": return default.FavorDescText;
        case "bRewardSystem": return default.RewardDescText;
        case "bSlavesEthereal": return default.EtherealDescText;
    }

    return Super.GetDescriptionText(PropName);
}

function GetServerDetails(out ServerResponseLine ServerState)
{
    local int i;

    Super.GetServerDetails(ServerState);

    i = ServerState.ServerInfo.Length;
    ServerState.ServerInfo.Length = i + 1;
    ServerState.ServerInfo[i].Key = "FavorTarget";
    ServerState.ServerInfo[i].Value = Locs(FavorTarget);

    i = ServerState.ServerInfo.Length;
    ServerState.ServerInfo.Length = i + 1;
    ServerState.ServerInfo[i].Key = "RewardSystem";
    ServerState.ServerInfo[i].Value = Locs(bRewardSystem);

    i = ServerState.ServerInfo.Length;
    ServerState.ServerInfo.Length = i + 1;
    ServerState.ServerInfo[i].Key = "SlavesEthereal";
    ServerState.ServerInfo[i].Value = Locs(bSlavesEthereal);
}

static function array<string> GetAllLoadHints(optional bool bThisClassOnly)
{
    local int i;
    local array<string> Hints;

    if ( !bThisClassOnly || default.GHMHints.Length == 0 )
        Hints = Super.GetAllLoadHints();

    for ( i = 0; i < default.GHMHints.Length; i++ )
        Hints[Hints.Length] = default.GHMHints[i];

    return Hints;
}

defaultproperties
{
     DMSquadClass=OLGhostMaster.OLSlaveSquadAI
     GameName="Ghost Master"
     Acronym="GHM"
     DecoTextName="OLGhostMaster.OLSlaveGame"
     Description="When you are killed, you become a ghost bound to your killer. If your master dies, you return to your mortal body. You can also earn your body by helping your master."
     HUDType="OLGhostMaster.HUDOLSlave"
     MutatorClass="OLGhostMaster.OLSlaveMutator"
     ScoreBoardType="OLGhostMaster.OLSlaveScoreBoard"
     GameReplicationInfoClass=OLGhostMaster.OLSlaveGameReplicationInfo
     DeathMessageClass=OLGhostMaster.OLSlaveDeathMessage
     bRewardSystem=True
     RewardPropText="Use Reward System"
     RewardDescText="Rewards ghosts for serving their master well. When ghosts become free, they are awarded with weapons and health depending on how much favor they earned."
     bSlavesEthereal=False
     EtherealPropText="Ghosts are Ethereal"
     EtherealDescText="Makes ghosts ethereal. Projectiles and other players pass right through them."
     SlaveSpeedMultiplier=1.3
     FavorTarget=100
     FavorPropText="Favor Needed"
     FavorDescText="Defines the amount of favor ghosts need to earn their mortal bodies."
     ScreenShotName="OLGhostMasterTex.slaveshots"
     PlayerControllerClassName="OLGhostMaster.OLSlavePlayerController"
     GHMHints(0)="Picking up valuable items such as the Super Shield Pack or Double Damage is worth a lot of favor. Go for the good items!"
     GHMHints(1)="As a ghost, you can earn extra favor by tagging other ghostmasters so your master can see where they are."
     GHMHints(2)="The more ghosts a ghostmaster controls, the more points they are worth when killed."
}
