class UInteractComponent:UActorComponent
{
	FString Prompt;
	void Interact()
	{

	}
}

class UInteractableGrappleGun:UInteractComponent
{
	PickupRopeGrappleEvent RopeTutorialEvent;
	default Prompt = "Press E to pick up grapple gun!";

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RopeTutorialEvent.AddUFunction(UTutorialManager::Get().PickupRopeGrappleTutorial, FName("Trigger"));    
	}

	void Interact() override
	{
		Super::Interact();
		RopeTutorialEvent.Broadcast();
		Cast<AAlien>(Gameplay::GetPlayerPawn(0)).ActivateGrapple();
		Owner.DestroyActor();
	}
}
class UInteractableNextLevelLoad:UInteractComponent
{
	default Prompt = "Press E to see what's next!";
	UPROPERTY(EditAnywhere)
	TSoftObjectPtr<UWorld> WorldToLoad;
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	
	}

	void Interact() override
	{
		Super::Interact();
		Gameplay::OpenLevelBySoftObjectPtr(WorldToLoad);
	}
}
class UInteractableReset:UInteractComponent
{
	default Prompt = "Press E to reset puzzle!";

	void Interact() override
	{
		Super::Interact();
		Owner.GetComponent(UPuzzleResetComponent).ResetPuzzles();
	}
}
