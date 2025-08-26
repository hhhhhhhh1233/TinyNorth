class ATutorialTriggerBox : AActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	default Mesh.CollisionResponseToAllChannels = ECollisionResponse::ECR_Overlap;
	default Mesh.SetHiddenInGame(true);

	UPROPERTY(BlueprintReadWrite)
	bool bIsVaultTutorial = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnActorBeginOverlap.AddUFunction(this, n"AddTutorials");
	}

	UFUNCTION()
	void AddTutorials(AActor OverlappedActor, AActor OtherActor)
	{
		if (OtherActor.IsA(AAlien))
		{
			if (bIsVaultTutorial)
			{
				UTutorialManager::Get().AddVaultTutorial();
			}
			else
			{
				UTutorialManager::Get().AddTutorials();
			}
			OnActorBeginOverlap.Unbind(this, n"AddTutorials");
		}
	}
};