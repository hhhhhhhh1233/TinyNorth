event void FButtonStatus(bool Active);

class APhysicsButton : AActor
{
	FButtonStatus ButtonStatus;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent ButtonBase;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent TriggerVolume;

	default TriggerVolume.CollisionObjectType = ECollisionChannel::ECC_WorldStatic;

	default ButtonBase.GenerateOverlapEvents = false;
	default ButtonBase.SetCollisionResponseToChannel(ECollisionChannel::ECC_PhysicsBody, ECollisionResponse::ECR_Ignore);

	// default TriggerVolume.SetCollisionEnabled(ECollisionEnabled::ECollisionEnabled_MAX);
	default TriggerVolume.CollisionResponseToAllChannels = ECollisionResponse::ECR_Overlap;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnActorBeginOverlap.AddUFunction(this, n"EvaluateStatus");
		OnActorEndOverlap.AddUFunction(this, n"EvaluateStatus");
	}

	UFUNCTION()
	void EvaluateStatus(AActor A, AActor B)
	{
		// TArray<UPrimitiveComponent> OverlappingComponents;
		// TriggerVolume.GetOverlappingComponents(OverlappingComponents);

		TArray<AActor> OverlappingActors;
		TriggerVolume.GetOverlappingActors(OverlappingActors);
		int NumActors = OverlappingActors.Num();

		for(int i = 0; i < OverlappingActors.Num(); i++)
		{
			if(OverlappingActors[i].IsA(AGrappleHook))
			{
				NumActors--;
			}
		}

		ButtonStatus.Broadcast(NumActors > 0);
	}
};