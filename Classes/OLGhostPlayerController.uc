//-----------------------------------------------------------
//
//-----------------------------------------------------------
class OLSlavePlayerController extends xPlayer;

function AwardAdrenaline(float amount)
{
    if ( bAdrenalineEnabled )
    {
        if ( (Adrenaline < AdrenalineMax) && (Adrenaline+amount >= AdrenalineMax) && ((Pawn == None) || !Pawn.InCurrentCombo()) )
            ClientDelayedAnnouncementNamed('Adrenalin',30);
        Adrenaline += Amount;
        Adrenaline = Clamp( Adrenaline, 0, AdrenalineMax );
    }
}

DefaultProperties
{

}
