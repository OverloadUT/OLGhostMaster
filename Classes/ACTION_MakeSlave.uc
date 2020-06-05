//-----------------------------------------------------------
//
//-----------------------------------------------------------
class ACTION_MakeSlave extends ScriptedAction;

var(Action) name MasterTag;
var(Action) bool bMakeSlave;

function bool InitActionFor(ScriptedController C)
{
    local Pawn a;

//    log("ACTION_MakeSlave executing... MasterTag: "$MasterTag);

    if (MasterTag != 'None')
        ForEach C.AllActors(class'Pawn', a, MasterTag)
        {
//            log("Found master: "$a);
            OLSlavePawn(C.Pawn).Master = a.Controller;
        }
    else
        OLSlavePawn(C.Pawn).Master = none;

    OLSlavePawn(C.Pawn).bIsSlave = bMakeSlave;
    OLSlavePawn(C.Pawn).MakeSlave();

    return false;
}

DefaultProperties
{
     ActionString="Make a Slave"
}
