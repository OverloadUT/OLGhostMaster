/*******************************************************************************
    OLGhostGame

    Creation date: 05/04/2004 18:05
    Copyright (c) 2004, Greg Laabs
    <!-- $Id$ -->
*******************************************************************************/

class OLGhostGame extends xDeathMatch;

#exec AUDIO IMPORT FILE="Sounds\Liberated.wav" NAME="liberated" Package=OLGhostMaster
#exec AUDIO IMPORT FILE="Sounds\Insurrection.wav" NAME="insurrection" Package=OLGhostMaster
// #exec AUDIO IMPORT FILE="Sounds\Ghosted.wav" NAME="ghosted" Package=OLGhostMaster
#exec AUDIO IMPORT FILE="Sounds\EarnedFreedom.wav" NAME="earnedfreedom" Package=OLGhostMaster
#exec AUDIO IMPORT FILE="Sounds\OverloadJoinedMatch.wav" NAME="overloadjoined" Package=OLGhostMaster
#exec OBJ LOAD File="Texture\OLGhostMasterTex.utx" Package=OLGhostMaster

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
var() config bool bGhostsEthereal;
var() config float GhostSpeedMultiplier;
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
        // V.PrecacheFallbackPackage("OLGhostMaster",'ghosted'); (doesn't exist)
        V.PrecacheFallbackPackage("OLGhostMaster",'liberated');
        V.PrecacheFallbackPackage("OLGhostMaster",'earnedfreedom');
        V.PrecacheFallbackPackage("OLGhostMaster",'insurrection');
        V.PrecacheFallbackPackage("OLGhostMaster",'overloadjoined');
    }
}

event InitGame( string Options, out string Error )
{
    Super.InitGame(Options, Error);

    bForceRespawn = true;
}

// Change the default pawn class to OLGhostPawn on login.
event PlayerController Login( string Portal, string Options, out string Error )
{
    local PlayerController pc;

    pc = Super.Login(Portal, Options, Error);

    if(pc != None)
    {
        pc.PawnClass = class'OLGhostPawn';
        xPlayer(pc).ComboNameList[3] = ""; // Remove invis combo from players list.
    }

    UpdateGhostCount();

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
    if( OLGhostPlayerReplicationInfo(Exiting.PlayerReplicationInfo).Master != none )
        UpdateGhostCount( Controller(OLGhostPlayerReplicationInfo(Exiting.PlayerReplicationInfo).Master.Owner) );

    FreeGhosts(Exiting);
    UpdateGhostCount();
    CheckScore(none);

    Super.Logout(Exiting);
}

function bool BecomeSpectator(PlayerController P)
{
    if ( !Super.BecomeSpectator(P) )
        return false;

    if( OLGhostPlayerReplicationInfo(P.PlayerReplicationInfo).Master != none )
        UpdateGhostCount( Controller(OLGhostPlayerReplicationInfo(P.PlayerReplicationInfo).Master.Owner) );

    FreeGhosts(P);
    UpdateGhostCount();
    CheckScore(none);
    return true;
}

function bool AllowBecomeActivePlayer(PlayerController P)
{
    if ( Super.AllowBecomeActivePlayer(P) )
    {
        if ( OLGhostPlayerReplicationInfo(P.PlayerReplicationInfo).Master == none )
        {
            OLGhostPlayerReplicationInfo(P.PlayerReplicationInfo).bIsGhost = false;
            UpdateGhostCount();
        }
        else
            UpdateGhostCount( Controller(OLGhostPlayerReplicationInfo(P.PlayerReplicationInfo).Master.Owner) );
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
    NewBot = Spawn(class'GhostBot');

    if(NewBot != None)
    {
        InitializeBot(NewBot,BotTeam,Chosen);
        NewBot.PawnClass = class'OLGhostPawn';
    }

    UpdateGhostCount();

    return NewBot;
}

function Killed( Controller Killer, Controller Killed, Pawn KilledPawn, class<DamageType> damageType )
{
    local Controller TheRealKiller;

    if ( (Killer == none || Killer == Killed)
            && Killed != none
            && Killed.PlayerReplicationInfo != none
            && OLGhostPlayerReplicationInfo(Killed.PlayerReplicationInfo) != none
            && OLGhostPlayerReplicationInfo(Killed.PlayerReplicationInfo).LastDamagedBy != none
            && !OLGhostPlayerReplicationInfo(Killed.PlayerReplicationInfo).bIsGhost
            && !OLGhostPlayerReplicationInfo(OLGhostPlayerReplicationInfo(Killed.PlayerReplicationInfo).LastDamagedBy.PlayerReplicationInfo).bIsGhost )
    {
        TheRealKiller = OLGhostPlayerReplicationInfo(Killed.PlayerReplicationInfo).LastDamagedBy.Controller;
        OLGhostPlayerReplicationInfo(Killed.PlayerReplicationInfo).LastDamagedBy = none;
        // It won't compile unless I put "self." in front... WTF?
        self.Killed(TheRealKiller,Killed,KilledPawn,damageType);
        return;
    }

    Super.Killed(Killer, Killed, KilledPawn, damageType);
}

function NotifyKilled(Controller Killer, Controller Other, Pawn OtherPawn)
{
    // If a ghost killed their master, it's an insurrection!
    if (Killer != none && OLGhostPlayerReplicationInfo(Killer.PlayerReplicationInfo) != none)
    {
        if(OLGhostPlayerReplicationInfo(Killer.PlayerReplicationInfo).bIsGhost && OLGhostPlayerReplicationInfo(Killer.PlayerReplicationInfo).Master == Other.PlayerReplicationInfo )
        {
            ScoreEvent(Killer.PlayerReplicationInfo,2,"insurrection");
            FreeGhost(Killer, 'insurrection');
            MakeGhost(Killer, Other);
        }
        else if (Killer != none && Killer != Other && !OLGhostPlayerReplicationInfo(Killer.PlayerReplicationInfo).bIsGhost && !OLGhostPlayerReplicationInfo(Other.PlayerReplicationInfo).bIsGhost)
        {
            MakeGhost(Killer, Other);
        }

        OLGhostPlayerReplicationInfo(Other.PlayerReplicationInfo).LastDamagedBy = none;
    }

    FreeGhosts(Other);

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
        bonusscore = OLGhostPlayerReplicationInfo(other.PlayerReplicationInfo).numghosts;
        Killer.PlayerReplicationInfo.Score += 1 + bonusscore;
        Killer.PlayerReplicationInfo.NetUpdateTime = Level.TimeSeconds - 1;
        Killer.PlayerReplicationInfo.Kills++;
        ScoreEvent(Killer.PlayerReplicationInfo,1 + bonusscore,"ghostmaster_frag");
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
        // find winner - top score who is not a ghost
        for ( P=Level.ControllerList; P!=None; P=P.nextController )
            if ( P.bIsPlayer
                && !P.PlayerReplicationInfo.bOutOfLives
                && !OLGhostPlayerReplicationInfo(P.PlayerReplicationInfo).bIsGhost
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

    // Check if someone owns all the ghosts.
    for ( C=Level.ControllerList; C!=None; C=C.NextController )
    {
        if ( (OLGhostPlayerReplicationInfo(C.PlayerReplicationInfo) != None)
          && (!OLGhostPlayerReplicationInfo(C.PlayerReplicationInfo).bIsGhost)
          && (OLGhostPlayerReplicationInfo(C.PlayerReplicationInfo).numghosts >= TargetNum ) )
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

function MakeGhost(Controller Master, Controller Ghost)
{
    OLGhostPlayerReplicationInfo(Ghost.PlayerReplicationInfo).bIsGhost = true;
    OLGhostPlayerReplicationInfo(Ghost.PlayerReplicationInfo).Master = Master.PlayerReplicationInfo;
    OLGhostPlayerReplicationInfo(Ghost.PlayerReplicationInfo).Favor = 0;
    UpdateGhostCount(Master);

    // Dont let Ghosts use or pickup Adrenaline.
    // Also, make sure they have at most 99 adrenaline, so they can't perform combos.
    Ghost.bAdrenalineEnabled = false;
    Ghost.Adrenaline = FMin(99, Ghost.Adrenaline);

    if ( PlayerController(Ghost) != none )
        PlayerController(Ghost).ReceiveLocalizedMessage(class'OLGhostMaster.OLGhostMessage', 0);
}

function FreeGhosts(Controller Master)
{
    local int i;

    for(i=0;i<GameReplicationInfo.PRIArray.Length;i++)
    {
        if (OLGhostPlayerReplicationInfo(GameReplicationInfo.PRIArray[i]) == none)
            continue;

        if( /*!GameReplicationInfo.PRIArray[i].bOnlySpectator*/
            OLGhostPlayerReplicationInfo(GameReplicationInfo.PRIArray[i]).bIsGhost
            && Controller(OLGhostPlayerReplicationInfo(GameReplicationInfo.PRIArray[i]).Master.Owner) == Master)
        {
            FreeGhost( Controller(GameReplicationInfo.PRIArray[i].Owner), 'masterdied' );
        }
    }
}

function FreeGhost(Controller Ghost, optional name reason)
{
    local OLGhostPawn GhostPawn;
    local PlayerReplicationInfo oldmaster;

    GhostPawn = OLGhostPawn(Ghost.Pawn);

    oldmaster = OLGhostPlayerReplicationInfo(Ghost.PlayerReplicationInfo).Master;

    OLGhostPlayerReplicationInfo(Ghost.PlayerReplicationInfo).bIsGhost = false;
    OLGhostPlayerReplicationInfo(Ghost.PlayerReplicationInfo).Master = none;
    OLGhostPlayerReplicationInfo(Ghost.PlayerReplicationInfo).FavorPending = OLGhostPlayerReplicationInfo(Ghost.PlayerReplicationInfo).Favor;
    OLGhostPlayerReplicationInfo(Ghost.PlayerReplicationInfo).Favor = 0;

    // Re-enable adrenaline
    Ghost.bAdrenalineEnabled = true;

    if ( PlayerController(Ghost) != none )
    {
        if (reason == 'favor')
            PlayerController(Ghost).ReceiveLocalizedMessage(class'OLGhostMaster.OLGhostMessage', 2);
        else if (reason == 'masterdied')
            PlayerController(Ghost).ReceiveLocalizedMessage(class'OLGhostMaster.OLGhostMessage', 1);
        else if (reason == 'insurrection')
            PlayerController(Ghost).ReceiveLocalizedMessage(class'OLGhostMaster.OLGhostMessage', 3);
        else
            PlayerController(Ghost).ReceiveLocalizedMessage(class'OLGhostMaster.OLGhostMessage', 1);
    }
    if (PlayerController(oldmaster.owner) != none)
    {
        if (reason == 'favor')
            PlayerController(oldmaster.owner).ReceiveLocalizedMessage(class'OLGhostMaster.OLGhostFreedomMessage', 0, Ghost.PlayerReplicationInfo);
    }

    if (GhostPawn != none && Ghost.bIsPlayer && !Ghost.PlayerReplicationInfo.bOnlySpectator)
    {
        GhostPawn.FreeGhost();
    }

    RestartPlayer(Ghost);

    UpdateGhostCount( controller(oldmaster.owner) );
}

function UpdateGhostCount(optional Controller Master)
{
    local int i;
    local int NumGhosts;
    local int NumTotalGhosts;
    local int NumTotalMasters;

    NumGhosts = 0;
    NumTotalGhosts = 0;
    NumTotalMasters = 0;

    for(i=0;i<GameReplicationInfo.PRIArray.Length;i++)
    {
        if(OLGhostPlayerReplicationInfo(GameReplicationInfo.PRIArray[i]) == none || OLGhostPlayerReplicationInfo(GameReplicationInfo.PRIArray[i]).bOnlySpectator)
            continue;

        if(OLGhostPlayerReplicationInfo(GameReplicationInfo.PRIArray[i]).bIsGhost)
        {
            NumTotalGhosts++;
            if(Master != none && Controller(OLGhostPlayerReplicationInfo(GameReplicationInfo.PRIArray[i]).Master.Owner) == Master)
                NumGhosts++;
        } else
            NumTotalMasters++;
    }
    if (Master != none)
        OLGhostPlayerReplicationInfo(Master.PlayerReplicationInfo).NumGhosts = NumGhosts;
    OLGhostGameReplicationInfo(GameReplicationInfo).NumGhosts = NumTotalGhosts;
    OLGhostGameReplicationInfo(GameReplicationInfo).NumMasters = NumTotalMasters;

    if (Master != none && Master.PlayerReplicationInfo != none)
        CheckScore(Master.PlayerReplicationInfo);
    else
        CheckScore(none);
}

function GhostTaggedPlayer(pawn TaggedPawn, Controller Tagger)
{
    local Controller C;

    if (TaggedPawn == none || Tagger == none)
        return;

    // Make all bots check their enemies for validity
    for ( C=Level.ControllerList; C!=None; C=C.NextController )
    {
        if( Bot(C) != none )
            OLGhostSquadAI(Bot(C).Squad).CheckEnemies(Bot(C));
    }

    AddFavor(Tagger, 15);

    // Send message to the tagged player
    if( PlayerController(TaggedPawn.Controller) != none )
        PlayerController(TaggedPawn.Controller).ReceiveLocalizedMessage(class'OLGhostMaster.OLGhostTagMessage', 1);
    // Send message to the tagger
    if( PlayerController(Tagger) != none )
        PlayerController(Tagger).ReceiveLocalizedMessage(class'OLGhostMaster.OLGhostTagMessage', 2, TaggedPawn.PlayerReplicationInfo);
    // Send message to the master
    if( OLGhostPlayerReplicationInfo(Tagger.PlayerReplicationInfo).master != none
        && PlayerController(OLGhostPlayerReplicationInfo(Tagger.PlayerReplicationInfo).master.owner) != none )
        PlayerController(OLGhostPlayerReplicationInfo(Tagger.PlayerReplicationInfo).master.owner).ReceiveLocalizedMessage(class'OLGhostMaster.OLGhostTagMessage', 3, TaggedPawn.PlayerReplicationInfo, Tagger.PlayerReplicationInfo);
}

// Called when a player respawns.  This is when I set up the ghost stuff
function RestartPlayer( Controller aPlayer )
{
    local OLGhostPawn SP;

    Super.RestartPlayer(aPlayer);

    SP = OLGhostPawn(aPlayer.Pawn);
    SP.bIsGhost = OLGhostPlayerReplicationInfo(aPlayer.PlayerReplicationInfo).bIsGhost;
    if (SP.bIsGhost)
        SP.Master = Controller(OLGhostPlayerReplicationInfo(aPlayer.PlayerReplicationInfo).Master.Owner);
    else
        SP.Master = none;

    if (SP.bIsGhost)
    {
        SP.MakeGhost();
    } else {
        if (bRewardSystem)
            SP.RewardForFavor(OLGhostPlayerReplicationInfo(aPlayer.PlayerReplicationInfo).FavorPending);
        OLGhostPlayerReplicationInfo(aPlayer.PlayerReplicationInfo).FavorPending = 0;
    }
    UpdateGhostCount();
}

function AddFavor(controller Ghost, int amount)
{
    OLGhostPlayerReplicationInfo(Ghost.PlayerReplicationInfo).Favor += amount;
    CheckFavor(Ghost);
}

function CheckFavor(controller Ghost)
{
    if (OLGhostPlayerReplicationInfo(Ghost.PlayerReplicationInfo).Favor >= FavorTarget)
    {
        ScoreEvent(Ghost.PlayerReplicationInfo,3,"earned_freedom");
        FreeGhost(Ghost,'favor');
    }
}

function bool PickupQuery( Pawn Other, Pickup item )
{
    local byte bAllowPickup;
    local bool bDidPickup;
    local Pawn MasterPawn;
    local inventory copy, inv;
    local OLGhostPawn GhostPawn;
    local int firemode;
    local int Favor;

    GhostPawn = OLGhostPawn(Other);

    if (item == none || Other == none)
        return false;

    // Check if the picker-upper is a ghost
    if( GhostPawn.bIsGhost )
    {
        MasterPawn = GhostPawn.Master.Pawn;

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
                if (GhostPawn != none)
                    item.AnnouncePickup(GhostPawn);
                MasterPawn.PlaySound( item.PickupSound,SLOT_Interact );

                if (PlayerController(MasterPawn.Controller) != none)
                    PlayerController(MasterPawn.Controller).ReceiveLocalizedMessage(class'OLGhostGiftMessage',0,Other.Controller.PlayerReplicationInfo);

                AddFavor(Other.Controller, favor);

                item.SetRespawn();
            }
        }
        return false; // Ghost does not get to pick up items no matter what.
    }

    if ( (GameRulesModifiers != None) && GameRulesModifiers.OverridePickupQuery(Other, item, bAllowPickup) )
        if (bAllowPickup == 1)
        {
            BlankGhostGiftMessage(Other);
            return true;
        }

    if ( Other.Inventory == None )
    {
        BlankGhostGiftMessage(Other);
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

// Sends a blank "GhostGiftMessage" so that the "A Gift From XXX" doesn't linger
// after you pick up an item yourself
function BlankGhostGiftMessage(Pawn Other)
{
    // Send a blank GhostGiftMessage to clear any one currently there.
    if (PlayerController(Other.Controller) != none)
        PlayerController(Other.Controller).ReceiveLocalizedMessage(class'OLGhostGiftMessage',1);
}

function int ReduceDamage( int Damage, pawn injured, pawn instigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType )
{
    local int EndDamage;

    // Ghosts can't take damage
    if( OLGhostPawn(injured).bIsGhost )
        return 0;

    // Ghosts can only deal damage to their masters.
    // If they kill their master, it's an insurrection!
    if ( instigatedBy != none && OLGhostPawn(instigatedBy).bIsGhost && OLGhostPlayerReplicationInfo(instigatedBy.PlayerReplicationInfo).Master != injured.PlayerReplicationInfo)
        return 0;

    // Regular damage evaluation
    EndDamage = Super.ReduceDamage(Damage, injured, instigatedBy, HitLocation, Momentum, DamageType);

    if (EndDamage > 0 && OLGhostPlayerReplicationInfo(injured.PlayerReplicationInfo) != none && instigatedBy != none && instigatedBy != injured)
    {
        OLGhostPlayerReplicationInfo(injured.PlayerReplicationInfo).LastDamagedBy = instigatedBy;
    }

    return EndDamage;
}



static function FillPlayInfo(PlayInfo PI)
{
    Super.FillPlayInfo(PI);

    PI.AddSetting(default.GameGroup, "FavorTarget", default.FavorPropText, 40, 1, "Text","10;10:500",,,True);
    PI.AddSetting(default.GameGroup, "bRewardSystem", default.RewardPropText, 40, 1, "Check","",,,True);
    PI.AddSetting(default.GameGroup, "bGhostsEthereal", default.EtherealPropText, 40, 1, "Check","",,,True);
}

static event string GetDescriptionText(string PropName)
{
    switch (PropName)
    {
        case "FavorTarget": return default.FavorDescText;
        case "bRewardSystem": return default.RewardDescText;
        case "bGhostsEthereal": return default.EtherealDescText;
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
    ServerState.ServerInfo[i].Key = "GhostsEthereal";
    ServerState.ServerInfo[i].Value = Locs(bGhostsEthereal);
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
     DMSquadClass=OLGhostMaster.OLGhostSquadAI
     GameName="Ghost Master"
     Acronym="GHM"
     DecoTextName="OLGhostMaster.OLGhostGame"
     Description="When you are killed, you become a ghost bound to your killer. If your master dies, you return to your mortal body. You can also earn your body by helping your master."
     HUDType="OLGhostMaster.HUDOLGhost"
     MutatorClass="OLGhostMaster.OLGhostMutator"
     ScoreBoardType="OLGhostMaster.OLGhostScoreBoard"
     GameReplicationInfoClass=OLGhostMaster.OLGhostGameReplicationInfo
     DeathMessageClass=OLGhostMaster.OLGhostDeathMessage
     bRewardSystem=True
     RewardPropText="Use Reward System"
     RewardDescText="Rewards ghosts for serving their master well. When ghosts become free, they are awarded with weapons and health depending on how much favor they earned."
     bGhostsEthereal=False
     EtherealPropText="Ghosts are Ethereal"
     EtherealDescText="Makes ghosts ethereal. Projectiles and other players pass right through them."
     GhostSpeedMultiplier=1.3
     FavorTarget=100
     FavorPropText="Favor Needed"
     FavorDescText="Defines the amount of favor ghosts need to earn their mortal bodies."
     ScreenShotName="OLGhostMasterTex.slaveshots"
     PlayerControllerClassName="OLGhostMaster.OLGhostPlayerController"
     GHMHints(0)="Picking up valuable items such as the Super Shield Pack or Double Damage is worth a lot of favor. Go for the good items!"
     GHMHints(1)="As a ghost, you can earn extra favor by tagging other ghostmasters so your master can see where they are."
     GHMHints(2)="The more ghosts a ghostmaster controls, the more points they are worth when killed."
}
