class AAlienController : APlayerController
{
    UPROPERTY(BlueprintReadOnly)
    UInputMappingContext Mapping;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        auto Subsystem = UEnhancedInputLocalPlayerSubsystem::Get(GetLocalPlayer());
        Subsystem.AddMappingContext(Mapping, 0, FModifyContextOptions());
        SetDeprecatedInputYawScale(0.8);
    }
}