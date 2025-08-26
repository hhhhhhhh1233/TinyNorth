class ACheckpoint : AActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Checkpoint;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent PlayerRespawnPosition;

	UPROPERTY(DefaultComponent, Attach = PlayerRespawnPosition)
	USphereComponent PlayerFrontIndicator;

	UPROPERTY(DefaultComponent)
	UPuzzleResetComponent Reset;

	default Checkpoint.CollisionResponseToAllChannels = ECollisionResponse::ECR_Overlap;
	default Checkpoint.bHiddenInGame = true;

	default PlayerRespawnPosition.bAbsoluteLocation = true;
	default PlayerRespawnPosition.bAbsoluteRotation = true;
	default PlayerRespawnPosition.bAbsoluteScale = true;

	default PlayerRespawnPosition.LineThickness = 1.5;
	default PlayerFrontIndicator.LineThickness = 0.5;

	default PlayerRespawnPosition.ShapeColor = FColor::Blue;
	default PlayerFrontIndicator.ShapeColor = FColor::Red;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnActorBeginOverlap.AddUFunction(this, n"SaveCheckpoint");
	}

	UFUNCTION()
	void SaveCheckpoint(AActor OverlappedActor, AActor OtherActor)
	{
		if (OtherActor.IsA(AAlien))
		{
			Cast<AAlien>(OtherActor).CurrentCheckpoint = this;
		}
	}
};