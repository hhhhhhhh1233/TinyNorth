// Meant to be put on actors that can kill the player to reset any necessary puzzles
// Has a list of actors that it saves the transforms from at beginplay and then sets the actors transform to whatever it was at beginplay
class UPuzzleResetComponent:UActorComponent
{
	UPROPERTY(EditAnywhere)
	TArray<AActor> ActorsToReset;
	TArray<FTransform> ActorTransforms;
	TArray<FTransform> ComponentTransforms;
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (int i = 0; i < ActorsToReset.Num(); i++)
		{
			ActorTransforms.Add(ActorsToReset[i].ActorTransform);
			TArray<UActorComponent> OutComp;
			ActorsToReset[i].GetAllComponents(UMeshComponent, OutComp);
			for(int y = 0; y < OutComp.Num(); y++)
			{
				UMeshComponent Mesh = Cast<UMeshComponent>(OutComp[y]);
				ComponentTransforms.Add(Mesh.WorldTransform);
			}
		}
	}
	UFUNCTION()
	void ResetPuzzles()
	{
		int y = 0;
		for (int i = 0; i < ActorsToReset.Num(); i++)
		{
			if(ActorsToReset[i] == nullptr)
			{
				return;
			}
			ActorsToReset[i].ActorTransform = ActorTransforms[i];

			if(ActorsToReset[i].IsA(ABoulder))
			{
				Cast<ABoulder>(ActorsToReset[i]).bHasPlayed=false;
			}
			else if(ActorsToReset[i].IsA(ALog))
			{
				Cast<ALog>(ActorsToReset[i]).bHasPlayedStart=false;
				Cast<ALog>(ActorsToReset[i]).bHasPlayedEnd=false;
			}

			TArray<UActorComponent> OutComp;
			ActorsToReset[i].GetAllComponents(UMeshComponent, OutComp);
			for(UActorComponent Comp:OutComp)
			{
				if(Comp==nullptr)
				{
					return;
				}
				UMeshComponent Mesh = Cast<UMeshComponent>(Comp);
				Mesh.SetWorldTransform(ComponentTransforms[y]);
				Mesh.SetPhysicsAngularVelocityInRadians(FVector::ZeroVector);
				Mesh.SetPhysicsLinearVelocity(FVector::ZeroVector);
				y++;
			}
		}
	}
}