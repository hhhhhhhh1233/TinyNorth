class AWater : AActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UAudioComponent Audio;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Water;

	default Audio.SetAutoActivate(false);

	default Water.CollisionResponseToAllChannels = ECollisionResponse::ECR_Overlap;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnActorBeginOverlap.AddUFunction(this, n"KillPlayer");
	}

	UFUNCTION()
	void KillPlayer(AActor OverlappedActor, AActor OtherActor)
	{
		if (OtherActor.IsA(AAlien))
		{
			Audio.WorldLocation = OtherActor.ActorLocation;
			Audio.Play();
			Cast<AAlien>(OtherActor).Kill();
		}
	}
};