//-----------------------------------------------------------
//
//-----------------------------------------------------------
class OLGhostFreedomMessage extends CriticalEventPlus;

var localized string MaleFreedomMessage, FemaleFreedomMessage;

static function string GetString(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{

    if (RelatedPRI_1.PlayerName != "")
    {
        if ( RelatedPRI_1.bIsFemale )
            return RelatedPRI_1.PlayerName@Default.FemaleFreedomMessage;
        else
            return RelatedPRI_1.PlayerName@Default.MaleFreedomMessage;
    }
    return "";
}

DefaultProperties
{
    MaleFreedomMessage = "earned his mortal body!"
    FemaleFreedomMessage = "earned her mortal body!"
}
