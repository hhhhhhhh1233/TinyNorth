class UHudInterface:UActorComponent
{
    // Responsible for housing methods for accessing values used by HUD
    AAlien Alien;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        Alien = Cast<AAlien>(GetOwner());
    }

    UFUNCTION(BlueprintCallable)
    bool GrapplePossible()
    {
        if(!Alien.Grapple.bRopeGrappleEnabled)
            return false;
        TArray<AActor> IgnoreList;
        FHitResult Res;
        FVector StartPoint = Alien.Camera.GetWorldLocation();
        FVector EndPoint = Alien.Camera.GetWorldLocation() + Alien.Camera.GetForwardVector() * Alien.Grapple.MaxRopeLength;
        return System::LineTraceSingle(StartPoint, EndPoint, ETraceTypeQuery::TraceTypeQuery1, true, IgnoreList, EDrawDebugTrace::None, Res, true) && Res.Component.ComponentHasTag(n"GrappleObject");
    }

    UFUNCTION(BlueprintCallable)
    bool HasGrapple()
    {
        return Alien.Grapple.bRopeGrappleEnabled;
    }

    UFUNCTION(BlueprintCallable)
    FString GetTutorialText()
    {
        FString Text = "";
        if(UTutorialManager::Get().Tutorials.Num() > 0 && UTutorialManager::Get().Tutorials[0].bActive)
        {
            Text = UTutorialManager::Get().Tutorials[0].Tip;
        }
        return Text;
    }

    UFUNCTION(BlueprintCallable)
    FString GetInteractText()
    {
        FString Text = "";
        UInteractComponent InteractComponent = Alien.CheckInteract();
        if(InteractComponent != nullptr)
        {
            Text = InteractComponent.Prompt;
        }
        return Text;
    }
}
