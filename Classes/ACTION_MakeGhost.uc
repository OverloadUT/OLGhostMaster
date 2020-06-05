//-----------------------------------------------------------
//
//-----------------------------------------------------------
class ACTION_MakeGhost extends ScriptedAction;

var(Action) name MasterTag;
var(Action) bool bMakeSlave;

function bool InitActionFor(ScriptedController C)
{
    local Pawn a;

//    log("ACTION_MakeGhost executing... MasterTag: "$MasterTag);

    if (MasterTag != 'None')
        ForEach C.AllActors(class'Pawn', a, MasterTag)
        {
//            log("Found master: "$a);
            OLGhostPawn(C.Pawn).Master = a.Controller;
        }
    else
        OLGhostPawn(C.Pawn).Master = none;

    OLGhostPawn(C.Pawn).bIsSlave = bMakeSlave;
    OLGhostPawn(C.Pawn).MakeSlave();

    return false;
}

DefaultProperties
{
     ActionString="Make a Ghost"
}
