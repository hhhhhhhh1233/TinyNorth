class ADoor : AActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent DoorMesh;

	UPROPERTY()
	APhysicsButton Button;

	UPROPERTY()
	bool bInvertButtonFunctionality = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (Button == nullptr)
		{
			PrintError(f"No button connected to door {Name}");
		}
		else
		{
			Button.ButtonStatus.AddUFunction(this, n"OpenDoor");
		}

		Button.EvaluateStatus(nullptr, nullptr);
	}

	UFUNCTION()
	void OpenDoor(bool bOpen)
	{
		if (bOpen != bInvertButtonFunctionality)
		{
			DoorMesh.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
			DoorMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
			DoorMesh.SetHiddenInGame(true);
		}
		else
		{
			DoorMesh.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);
			DoorMesh.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
			DoorMesh.SetHiddenInGame(false);
		}
	}
};