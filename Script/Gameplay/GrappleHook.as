class AGrappleHook : AActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UStaticMeshComponent VisualMesh;

	UPROPERTY(ToolTip = "Scales the forward vector by this much to add the inital impulse to the hook")
	float InitialForce = 1500;

	// Stored for later
	AAlien PlayerAlien;
	UGrappleComponent PlayerGrapple;

	UPROPERTY(DefaultComponent)
	USplineComponent Spline;

	UPROPERTY()
	UStaticMesh RopeMesh;

	// Array even though this version only ever has one spline mesh, in the future though it probably will be more dynamic
	TArray<USplineMeshComponent> SplineMeshes;

	default VisualMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	default Mesh.bHiddenInGame = true;

	// default Mesh.CollisionResponseToAllChannels = ECollisionResponse::ECR_Overlap;
	default Mesh.SetCollisionResponseToChannel(ECollisionChannel::ECC_Pawn, ECollisionResponse::ECR_Ignore);

	default Mesh.SimulatePhysics = true;
	default Mesh.EnableGravity = false;
	default Mesh.SetUseCCD(true);

	default SetTickGroup(ETickingGroup::TG_PostUpdateWork);

	bool bActive = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Mesh.AddImpulse(ActorForwardVector * InitialForce * Mesh.Mass);
		Spline.AddSplinePoint(ActorLocation, ESplineCoordinateSpace::World, false);
		Spline.AddSplinePoint(ActorLocation, ESplineCoordinateSpace::World, false);

		PlayerAlien = Cast<AAlien>(Gameplay::GetPlayerCharacter(0));
		int MeshesToSpawn = Math::CeilToInt((PlayerAlien.Grapple.MaxRopeLength + 1) / PlayerAlien.Grapple.Rope.ParticleDistance);

		for (int i = 0; i < MeshesToSpawn; i++)
		{
			SplineMeshes.Add(USplineMeshComponent::Create(this));
			SplineMeshes[i].SetStaticMesh(RopeMesh);
			SplineMeshes[i].SetMaterial(0, Material::CreateDynamicMaterialInstance(RopeMesh.GetMaterial(0)));
			SplineMeshes[i].SetForwardAxis(ESplineMeshAxis::Z);
			SplineMeshes[i].SetStartScale(FVector2D(0.5, 0.5), false);
			SplineMeshes[i].SetEndScale(FVector2D(0.5, 0.5));
			SplineMeshes[i].SetHiddenInGame(true);
			SplineMeshes[i].SetSplineUpDir(-FVector::RightVector);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bActive)
		{
			int NodesToHook = Math::CeilToInt(PlayerAlien.RopeAttachPoint.WorldLocation.Distance(Mesh.WorldLocation) / PlayerGrapple.Rope.ParticleDistance);
			FVector ToGrappleGun = PlayerAlien.RopeAttachPoint.WorldLocation - Mesh.WorldLocation;
			ToGrappleGun.Normalize();

			Spline.ClearSplinePoints(false);
			for (int i = 0; i < NodesToHook; i++)
				Spline.AddSplinePoint(Mesh.WorldLocation + ToGrappleGun * PlayerGrapple.Rope.ParticleDistance * i, ESplineCoordinateSpace::World, false);
			Spline.AddSplinePoint(PlayerAlien.RopeAttachPoint.WorldLocation, ESplineCoordinateSpace::World, false);

			Spline.UpdateSpline();

			int NumberOfSegments = Math::Min(Spline.GetNumberOfSplineSegments(), SplineMeshes.Num());
			for (int i = 0; i < NumberOfSegments; i++)
			{
				SplineMeshes[i].SetStartAndEnd(Spline.GetLocationAtSplinePoint(i, ESplineCoordinateSpace::Local), 		Spline.GetTangentAtSplinePoint(i, ESplineCoordinateSpace::Local), 
											Spline.GetLocationAtSplinePoint(i + 1, ESplineCoordinateSpace::Local), Spline.GetTangentAtSplinePoint(i + 1, ESplineCoordinateSpace::Local));
				SplineMeshes[i].SetHiddenInGame(false);
			}

			if (NumberOfSegments < SplineMeshes.Num())
			{
				for (int i = Spline.GetNumberOfSplineSegments(); i < SplineMeshes.Num(); i++)
				{
					SplineMeshes[i].SetHiddenInGame(true);
				}
			}
			
			if (PlayerAlien.RopeAttachPoint.WorldLocation.Distance(Mesh.WorldLocation) > PlayerGrapple.MaxRopeLength)
			{
				// ENGAGE DETACHED REELING HERE
				{
					PlayerAlien.GrappleGunSound.Stop();
					FVector AlienAttachmentPoint = PlayerAlien.RopeAttachPoint.WorldLocation;
					PlayerAlien.Grapple.bAttachedRope = true;
					PlayerGrapple.Rope.EstablishLink(AlienAttachmentPoint, Mesh.WorldLocation);
					PlayerGrapple.Release();

					for (auto SplineMesh : SplineMeshes)
						SplineMesh.SetHiddenInGame(true);
					bActive = false;
				}
			}
		}


		// TODO: Fix this behaviour to be simulated rather than just put on the spot
		if (PlayerGrapple.Rope.NodePositions.Num() > 0)
		{
			FVector LastRopeSegmentDirection = PlayerGrapple.Rope.NodePositions[PlayerGrapple.Rope.NodePositions.Num() - 1] - PlayerGrapple.Rope.NodePositions[PlayerGrapple.Rope.NodePositions.Num() - 2];
			LastRopeSegmentDirection.Normalize();
			VisualMesh.WorldRotation = FRotator::MakeFromY(-LastRopeSegmentDirection);
			Mesh.WorldLocation = PlayerGrapple.Rope.NodePositions[PlayerGrapple.Rope.NodePositions.Num() - 1];
		}
	}

	// TODO: Fix this behaviour to be simulated rather than just put on the spot
	void Release()
	{
		Mesh.AttachTo(Root, AttachType = EAttachLocation::KeepWorldPosition);
		// Mesh.SetHiddenInGame(false);
		// Mesh.SetSimulatePhysics(true);
		Mesh.SetSimulatePhysics(false);
		Mesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		VisualMesh.AttachTo(Mesh, AttachType = EAttachLocation::KeepWorldPosition);
		SetTickGroup(ETickingGroup::TG_LastDemotable);
		// Mesh.SetEnableGravity(true);
		ActorTickEnabled = true;
	}

	UFUNCTION(BlueprintOverride)
	void Hit(UPrimitiveComponent MyComp, AActor Other, UPrimitiveComponent OtherComp, bool bSelfMoved,
			 FVector HitLocation, FVector HitNormal, FVector NormalImpulse, FHitResult Hit)
	{
		if (!bActive)
			return;
		Spline.DestroyComponent();
		if (OtherComp.ComponentHasTag(n"GrappleObject"))
		{
			PlayerGrapple.bAttachedRope = true;
			
			PlayerGrapple.AttachedMesh = Other.GetComponent(UMeshComponent);
			PlayerGrapple.Rope.EndActor = Other;
			PlayerGrapple.Rope.EndObject = PlayerGrapple.AttachedMesh;
			if(PlayerGrapple.AttachedMesh != nullptr)
			{
				// Figure out the placement of the grappling hook mesh and attach it to the object
				VisualMesh.WorldLocation = HitLocation + HitNormal * 15;
				VisualMesh.WorldRotation = FRotator::MakeFromY(HitNormal);
				VisualMesh.AttachTo(PlayerGrapple.AttachedMesh, AttachType = EAttachLocation::KeepWorldPosition);

				// Attach the end point to the root of the grappling hook mesh
				PlayerGrapple.AttachedPoint.AttachTo(VisualMesh);
				PlayerGrapple.AttachedPoint.RelativeLocation = FVector::ZeroVector;

				// Attach the regular sphere mesh to the grappling hook to supply the collision detection
				Mesh.AttachTo(VisualMesh);
				Mesh.RelativeLocation = FVector::ZeroVector;

				// Set the collision to be physics only so it doesn't bother the ropes collision handling and scale it down to a reasonable size
				Mesh.SetCollisionEnabled(ECollisionEnabled::PhysicsOnly);
				Mesh.SetWorldScale3D(FVector(0.1, 0.1, 0.1));

				// To see the collision shape
				// Mesh.SetHiddenInGame(false);

				FVector AlienAttachmentPoint = PlayerAlien.RopeAttachPoint.WorldLocation;
				PlayerGrapple.Rope.EstablishLink(AlienAttachmentPoint, PlayerGrapple.AttachedPoint.WorldLocation);
			}
			UMeshComponent OtherMesh = Other.GetComponent(UMeshComponent);
			if(OtherMesh.IsSimulatingPhysics())
			{
				FVector VelNorm = Mesh.ComponentVelocity;
				VelNorm.Normalize();
				OtherMesh.AddImpulseAtLocation(VelNorm * 50 * OtherMesh.Mass, HitLocation);
			}
			PlayerGrapple.ShootRopeGrappleEvent.Broadcast();
			Mesh.SetSimulatePhysics(false);
			ActorTickEnabled = false;

			PlayerAlien.GrappleGunReelFast.Stop();
			PlayerAlien.GrappleGunSound.Sound = PlayerAlien.GrappleHitSuccess;
			PlayerAlien.GrappleGunSound.Play();
		}
		else
		{
			// ENGAGE DETACHED REELING HERE
			{
				PlayerAlien.Grapple.bAttachedRope = true;
				FVector AlienAttachmentPoint = PlayerAlien.RopeAttachPoint.WorldLocation;
				PlayerGrapple.Rope.EstablishLink(AlienAttachmentPoint, Mesh.WorldLocation);
				PlayerGrapple.Release();

				PlayerAlien.GrappleGunSound.Sound = PlayerAlien.GrappleHitFail;
				PlayerAlien.GrappleGunSound.Play();
			}
		}
		for (auto SplineMesh : SplineMeshes)
			SplineMesh.SetHiddenInGame(true);
		Niagara::SpawnSystemAttached(PlayerGrapple.GrappleHitEffect, OtherComp, n"none", HitLocation, FRotator::MakeFromX(HitNormal), EAttachLocation::KeepWorldPosition, true);
		bActive = false;
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		PlayerGrapple.GrappleHook = nullptr;
	}
	UFUNCTION()
	void Disable()
	{
		Mesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		VisualMesh.SetVisibility(false, true);
		// Mesh.bVisible = false;
	}
};