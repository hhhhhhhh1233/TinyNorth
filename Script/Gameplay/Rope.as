class ARope : AActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	// STRUCTURED IN A DOD WAY FOR PERFORMANCE REASONS, SINCE ROPES CAN BE HEAVY
	TArray<FVector> NodePositions;
	TArray<FVector> NodeOldPositions;
	TArray<FVector> NodeAccelerations;
	TArray<float> NodeInvertedMass;
	TArray<bool> NodeGrounded;
	TArray<bool> NodeOnSurface;

	UPROPERTY(DefaultComponent)
	USplineComponent Spline;

	default Spline.bDrawDebug = true;

	TArray<USplineMeshComponent> SplineMeshes;

	UPROPERTY(Category = Debug)
	bool bDebugDrawSpheres = true;

	UPROPERTY()
	UStaticMesh RopeMesh;

	UPROPERTY()
	bool bCollisionEnabled = true;

	//	CALCULATE THE CURRENT LENGTH OF THE ROPE
	float RopeLength = 0;

	UPROPERTY(Category = "Rope Values")
	float RopeRadius = 5;

	// HOW LARGE THE GAP SHOULD BE BETWEEN THE PARTICLES IN THE ROPE IN CM
	UPROPERTY(Category = "Rope Values")
	float ParticleDistance = 15;
	float DefaultParticleDistance; // Used to reset the particle distance after we play around with it

	// THE DISTANCE BETWEEN THE PARTICLE ATTACHED TO THE PLAYER AND THE FIRST FREE ONE 
	float ReelProgress = 1;

	// MULTS APPLIED TO THE FORCE FUNCTIONS, PRETTY ARBITRARY
	float GravityConstant = 20;
	const float DefaultGravityConstant = GravityConstant;
	float FrictionConstant = 0.4;
	const float DefaultFrictionConstant = FrictionConstant;
	float AirDragConstant = 0.1;
	const float DefaultAirDragConstant = AirDragConstant;
	const float DefaultInvertedMass = 0.1;

	const float CutRopeLifeTime = 10;

	bool bDetachedReeling = false;

	UPROPERTY(EditAnywhere)
	bool bLinearTension = true;
	UPROPERTY(EditAnywhere)
	float HooksConstant = 1500000.0f;
	UPROPERTY(EditAnywhere)
	float DirectionalDamping = 9000.0f;
	UPROPERTY(EditAnywhere)
	float TensionLimit = 2.0f;
	AAlien PlayerAlien;
	int JakobsenCount = 50;
	int CollisionCheckModulo = 2;

	UPROPERTY()
	bool bEstablishLinkOnSpawn = false;

	bool bIsPlayerGrappleRope = false;

	UPROPERTY(Category = "Attached Object", ToolTip = "Can be left null, will mean the rope is fixed at the start")
	AActor StartActor;

	UPROPERTY(Category = "Attached Object", ToolTip = "Can be left null, will mean the rope is fixed at the end")
	AActor EndActor;

	UMeshComponent StartObject;
	UMeshComponent EndObject;

	TArray<AActor> RopeIgnoreActors;
	TArray<AActor> WithIgnoreTags;

	UPROPERTY(DefaultComponent)
	USceneComponent StartObjectAttachPosition = nullptr;

	UPROPERTY(DefaultComponent)
	USceneComponent EndObjectAttachPosition = nullptr;

	UPROPERTY()
	int MinimumNumberOfNodes = 10;

	float LifeTime = 0;
	float InvincibleTime = 0.3;

	default SetTickGroup(ETickingGroup::TG_PostUpdateWork);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AActor Player = Gameplay::GetPlayerCharacter(0);
		
		if (Player != nullptr)
			PlayerAlien = Cast<AAlien>(Player);

		if (StartActor != nullptr)
		{
			StartObject = StartActor.GetComponentByClass(UStaticMeshComponent);
			StartObjectAttachPosition.AttachTo(StartActor.RootComponent, AttachType = EAttachLocation::KeepWorldPosition);
		}

		if (EndActor != nullptr)
		{
			EndObject = EndActor.GetComponentByClass(UStaticMeshComponent);
			EndObjectAttachPosition.AttachTo(EndActor.RootComponent, AttachType = EAttachLocation::KeepWorldPosition);
		}

		if (bEstablishLinkOnSpawn)
		{
			EstablishLink(StartObjectAttachPosition.WorldLocation, EndObjectAttachPosition.WorldLocation);
		}

		DefaultParticleDistance = ParticleDistance;

		RopeIgnoreActors.Add(Gameplay::GetPlayerCharacter(0));
		GetAllActorsOfClassWithTag(n"RopeIgnore", WithIgnoreTags);
		RopeIgnoreActors.Append(WithIgnoreTags);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Print(f"Number of particles: {NumberOfNodes}", 0);
		// Print(f"Reel: {ReelProgress}", 0);
		if(NodePositions.Num() == 0)
		{
			return;
		}

		LifeTime += DeltaSeconds;
		
		// Print(f"DeltaSeconds: {DeltaSeconds}\nSimSeconds: {SimSeconds}", 0);
		// Print(f"{GetTotalTension()=}", 0);
		
		if(LifeTime >= InvincibleTime && bIsPlayerGrappleRope && GetTotalTension() >= TensionLimit && !bDetachedReeling)
		{
			// Print("Whut");
			PlayerAlien.GrappleGunSound.Sound = PlayerAlien.RopeBreak;
			PlayerAlien.GrappleGunSound.Play();
			CutRope(Math::IntegerDivisionTrunc(NodePositions.Num(), 2));
		}

		// UPDATE THE POSITIONS OF THE NODES BASED ON THE FORCES THEN APPLY THE CONSTRAINTS
		SimulateVerlet(DeltaSeconds);
		Jakobsen(JakobsenCount);
		if (!bDetachedReeling)
			ApplyTension(DeltaSeconds);

		// SET THE FIRST NODE ON THE ROPE TO FOLLOW THE PLAYER CAMERA
		if (NodePositions.Num() > 0)
		{
			// TODO: TAKE THIS ARBITRARY POINT AND PLACE IT SOMEWHERE EDITABLE
			// NodePositions[0] = PlayerAlien.GetActorLocation() + (FVector::DownVector * 20);
			// NodePositions[0] = PlayerAlien.Camera.WorldLocation + PlayerAlien.Camera.ForwardVector * 20 + PlayerAlien.Camera.RightVector * 10 + PlayerAlien.Camera.UpVector * -5;
			if (bIsPlayerGrappleRope)
				NodePositions[0] = PlayerAlien.RopeAttachPoint.WorldLocation;
			else if(StartObject!=nullptr)
				NodePositions[0] = StartObjectAttachPosition.WorldLocation;
			else if(EndObject!=nullptr)
				NodePositions.Last() = EndObjectAttachPosition.WorldLocation;
			// Print(f"Rope attach {(NodePositions[0] - PlayerAlien.ActorLocation).Size()} cm from actor", 0);
			// NodePositions[0] = PlayerAlien.ActorLocation;
			if (bDetachedReeling)
			{
				// NodeAccelerations[NodeAccelerations.Num() - 1] += (NodePositions.Last() - PlayerAlien.ActorLocation) * NodeInvertedMass.Last();
				DetachedReel(-1);
			}
			else
			{
				NodePositions[NodePositions.Num() - 1] = EndObjectAttachPosition.WorldLocation;
			}
		}

		CheckIsGrounded();
		ApplyGravity();
		ApplyAirDrag(DeltaSeconds);
		ApplyFriction(DeltaSeconds);
		// System::DrawDebugLine(PlayerAlien.RopeAttachPoint.WorldLocation, PlayerAlien.RopeAttachPoint.WorldLocation + PlayerAlien.RopeAttachPoint.UpVector*10, FLinearColor::Blue, 0);

		if(NodePositions.Num() == 0)
			return;
		Spline.SetLocationAtSplinePoint(0, NodePositions[0], ESplineCoordinateSpace::World, false);
		
		FVector LastUp;
		if(bIsPlayerGrappleRope)
		{
			// Makes the rope a bit more pretty by setting the tangent to straight out from the player grapple and the grapple hook, some vectors
			Spline.SetTangentAtSplinePoint(0, -PlayerAlien.RopeAttachPoint.RightVector, ESplineCoordinateSpace::World, false);
			if(PlayerAlien.Grapple.GrappleHook != nullptr)
			{
				Spline.SetTangentAtSplinePoint(NodePositions.Num()-1, PlayerAlien.Grapple.GrappleHook.ActorForwardVector, ESplineCoordinateSpace::World, false);
			}
			LastUp = PlayerAlien.ActorForwardVector;
			// System::DrawDebugLine(PlayerAlien.RopeAttachPoint.WorldLocation+FVector(2.0, 0, 0) ,PlayerAlien.RopeAttachPoint.WorldLocation + LastUp * 100+FVector(2.0, 0, 0), FLinearColor::Green, 0);
			
			Spline.SetUpVectorAtSplinePoint(0, LastUp, ESplineCoordinateSpace::Local, false);
		}
		else
		{
			LastUp = FVector::UpVector;
			Spline.SetUpVectorAtSplinePoint(0, LastUp, ESplineCoordinateSpace::Local, false);
		}

		Spline.SetSplinePointType(0, ESplinePointType::Curve, false);
		Spline.SetLocationAtSplinePoint(0, NodePositions[0], ESplineCoordinateSpace::World, false);

		for (int i = 1; i < NodePositions.Num(); i++)
		{
			Spline.SetLocationAtSplinePoint(i, NodePositions[i], ESplineCoordinateSpace::World, false);
			FVector Direction = Spline.GetDirectionAtSplinePoint(i, ESplineCoordinateSpace::World);
			float Angle = Direction.AngularDistance(FVector::DownVector);
			// Print(f"{Angle}",0);
			Spline.SetSplinePointType(i, ESplinePointType::Curve, false);
			if(Angle <= 0.3 || Angle >= PI-0.3)
			{
				FVector LocalLeft;
				LocalLeft = LastUp.CrossProduct(Direction);
				FVector LocalUp = Direction.CrossProduct(LocalLeft);
				LocalUp.Normalize();
				LastUp = LocalUp;
				Spline.SetUpVectorAtSplinePoint(i, LocalUp, ESplineCoordinateSpace::Local, false);
				// System::DrawDebugLine(Spline.GetLocationAtSplinePoint(i, ESplineCoordinateSpace::World),Spline.GetLocationAtSplinePoint(i, ESplineCoordinateSpace::World) + Spline.GetUpVectorAtSplinePoint(i, ESplineCoordinateSpace::World)*100, FLinearColor::Blue, 0);
			}
			else
			{
				Spline.SetUpVectorAtSplinePoint(i, FVector::UpVector, ESplineCoordinateSpace::Local, false);
				// System::DrawDebugLine(Spline.GetLocationAtSplinePoint(i, ESplineCoordinateSpace::World),Spline.GetLocationAtSplinePoint(i, ESplineCoordinateSpace::World) + Spline.GetUpVectorAtSplinePoint(i, ESplineCoordinateSpace::World)*100, FLinearColor::Red, 0);
				LastUp = FVector::UpVector;
			}
		}

		Spline.SetSplinePointType(NodePositions.Num()-1, ESplinePointType::Curve, false);
		Spline.SetLocationAtSplinePoint(NodePositions.Num()-1, NodePositions[NodePositions.Num()-1], ESplineCoordinateSpace::World, false);
		
		
		FVector Direction = Spline.GetDirectionAtSplinePoint(NodePositions.Num()-1, ESplineCoordinateSpace::World);
		float Angle = Direction.AngularDistance(FVector::DownVector);
		// Print(f"{Angle}",0);
		Spline.SetSplinePointType(NodePositions.Num()-1, ESplinePointType::Curve, false);

		Spline.UpdateSpline();
		TArray<AActor> IgnoreList;
		FHitResult Res;
		ETraceTypeQuery Channel;
		for (int i = 0; i < NodePositions.Num() - 1; i++)
		{
			// Updating spline mesh
			SplineMeshes[i].SetSplineUpDir(Spline.GetUpVectorAtSplinePoint(i, ESplineCoordinateSpace::World));
			SplineMeshes[i].SetStartAndEnd(Spline.GetLocationAtSplinePoint(i, ESplineCoordinateSpace::Local), 		Spline.GetTangentAtSplinePoint(i, ESplineCoordinateSpace::Local), 
										Spline.GetLocationAtSplinePoint(i + 1, ESplineCoordinateSpace::Local), Spline.GetTangentAtSplinePoint(i+1, ESplineCoordinateSpace::Local));
			SplineMeshes[i].UpdateMesh();
			if(!bDetachedReeling && bIsPlayerGrappleRope)
			{
				float Tension = GetTotalTension();
				float TensionProgress = (Tension-1)/(TensionLimit-1);
				Cast<UMaterialInstanceDynamic>(SplineMeshes[i].GetMaterial(0)).SetScalarParameterValue(n"Tint", TensionProgress);
			}
			else
			{
				if(SplineMeshes[i].GetMaterial(0)!=nullptr)
					Cast<UMaterialInstanceDynamic>(SplineMeshes[i].GetMaterial(0)).SetScalarParameterValue(n"Tint", 0);
			}
			
			// Check collision with saw
			if(bIsPlayerGrappleRope && !bDetachedReeling)
			{
				if(System::LineTraceSingle(NodePositions[i], NodePositions[i+1], ETraceTypeQuery::TraceTypeQuery1, false, IgnoreList, EDrawDebugTrace::None, Res, true))
				{
					if(Res.Component.ComponentHasTag(n"Saw"))
					{
						CutRope(i+1);
						return;
					}
				}
				// TArray<UPrimitiveComponent> OutComponents;
				// TArray<EObjectTypeQuery> TypeQuery;

				// if (bCollisionEnabled && System::SphereOverlapComponents(NodePositions[i], RopeRadius, TypeQuery, nullptr, IgnoreList, OutComponents))
				// {
				// 	for(UPrimitiveComponent Component:OutComponents)
				// 	{
				// 		if(Component.ComponentHasTag(n"Saw"))
				// 		{
				// 			CutRope(i);
				// 			return;
				// 		}
				// 	}
				// }
			}

		}

		// DrawRope();
	}

	void EstablishLink(FVector Start, FVector End)
	{
		LifeTime = 0;
		FVector Direction = End - Start;
		Direction.Normalize();

		RopeLength = End.Distance(Start);

		if (bIsPlayerGrappleRope && RopeLength > PlayerAlien.Grapple.MaxRopeLength)
		{
			RopeLength = PlayerAlien.Grapple.MaxRopeLength;
		}

		UStaticMesh CurrentRopeMesh;
		if (bIsPlayerGrappleRope)
		{
			CurrentRopeMesh = PlayerAlien.GrappleRopeMesh;
		}
		else
		{
			CurrentRopeMesh = RopeMesh;
		}
		int NumberOfNodes = Math::Max(Math::CeilToInt((RopeLength / ParticleDistance) + 1), MinimumNumberOfNodes);
		Spline.ClearSplinePoints();
		for (int i = 0; i < NumberOfNodes; i++)
		{
			FVector StartingPosition = Start + Direction * ParticleDistance * i;
			NodePositions.Add(StartingPosition);
			NodeOldPositions.Add(StartingPosition);
			NodeAccelerations.Add(FVector::ZeroVector);
			NodeInvertedMass.Add(DefaultInvertedMass);
			NodeGrounded.Add(false);
			NodeOnSurface.Add(false);

			Spline.AddSplinePoint(StartingPosition, ESplineCoordinateSpace::World, false);
		}

		int MeshesToSpawn = NodePositions.Num() - 1;
		if (PlayerAlien != nullptr)
		{
			// I really hope this is not an off by one situation
			MeshesToSpawn = Math::CeilToInt((PlayerAlien.Grapple.MaxRopeLength + 1) / ParticleDistance);
			// Print(f"{MeshesToSpawn = }", 5, FLinearColor::Red);

		}

		for (int i = 0; i < MeshesToSpawn; i++)
		{
			SplineMeshes.Add(USplineMeshComponent::Create(this));
			SplineMeshes[i].SetStaticMesh(CurrentRopeMesh);
			SplineMeshes[i].SetMaterial(0, Material::CreateDynamicMaterialInstance(CurrentRopeMesh.GetMaterial(0)));
			SplineMeshes[i].SetForwardAxis(ESplineMeshAxis::Z);
			SplineMeshes[i].SetHiddenInGame(i >= NodePositions.Num() - 1);
			SplineMeshes[i].SetStartScale(FVector2D(0.5, 0.5), false);
			SplineMeshes[i].SetEndScale(FVector2D(0.5, 0.5));
		}

		Spline.UpdateSpline();

		// SET THE DISTANCE ON THE FIRST PARTICLE DEPENDING ON THE ACTUAL LENGTH OF THE ROPE
		ReelProgress = (RopeLength / ParticleDistance) - Math::FloorToInt(RopeLength / ParticleDistance);

		// SET THE FIRST AND LAST POINT TO HAVE INFINITE MASS IF THEY ARE ATTACHED
		NodeInvertedMass[0] = 0;
		NodeInvertedMass[NodeInvertedMass.Num() - 1] = 0;
		// Print(f"link");
	}

	void SimulateVerlet(float DeltaSeconds)
	{
		FHitResult Hit;
		for (int i = 0; i < NodePositions.Num(); i++)
		{
			FVector NewOldPosition = NodePositions[i];
			FVector NewPosition = NodePositions[i] * 2 - NodeOldPositions[i] + (NodeAccelerations[i] * DeltaSeconds * DeltaSeconds);

			if (bCollisionEnabled && System::SphereTraceSingle(NodePositions[i], NewPosition, RopeRadius, ETraceTypeQuery::TraceTypeQuery_MAX, false, RopeIgnoreActors, EDrawDebugTrace::None, Hit, true))
			{
				NewPosition = Hit.ImpactPoint + Hit.Normal * RopeRadius;
			}
			
			NodePositions[i] = NewPosition;
			NodeOldPositions[i] = NewOldPosition;
			NodeAccelerations[i] = FVector::ZeroVector;
		}
	}

	float CalcVectorAngle(FVector A, FVector B)
	{
		if (A.Size() * B.Size() == 0)
			return 0;
		return Math::Acos(A.DotProduct(B)/(A.Size() * B.Size()));
	}

	FVector ProjectPointOnLine(FVector Start, FVector Direction, FVector ProjectedPoint)
	{
		if (Direction == FVector::ZeroVector)
			return Start;
		return Start + Direction * (ProjectedPoint.DotProduct(Direction) / Direction.DotProduct(Direction));
	}

	// INSPO
	// FVector RelaxAngleConstraint(FVector A, FVector B, FVector C, float MaxAngle)
	// {
	// 	FVector AToB = B - A;
	// 	FVector BToC = C - B;

	// 	FVector AToC = C - A;
	// 	FVector ProjectedB = ProjectPointOnLine(A, AToC, AToB);

	// 	float NewLength = (B - ProjectedB).Size();

	// 	if (CalcVectorAngle(AToB, AToC) > MaxAngle)
	// 	{
	// 		float Opposite = (ProjectedB - A).Size() * Math::Tan(MaxAngle);

	// 		NewLength = Math::Min(Opposite, NewLength);
	// 	}

	// 	if (CalcVectorAngle(-BToC, -AToC) > MaxAngle)
	// 	{
	// 		float Opposite = (ProjectedB - C).Size() * Math::Tan(MaxAngle);

	// 		NewLength = Math::Min(Opposite, NewLength);
	// 	}

	// 	FVector PBToB = (B - ProjectedB);
	// 	PBToB.Normalize();
	// 	return ProjectedB + PBToB * NewLength;
	// }

	// MaxAngle is defined in radians
	void RelaxAngleConstraint(int IndexA, int IndexB, int IndexC, float MaxAngle)
	{
		FVector AToB = NodePositions[IndexB] - NodePositions[IndexA];
		FVector BToC = NodePositions[IndexC] - NodePositions[IndexB];
		FVector AToC = NodePositions[IndexC] - NodePositions[IndexA];

		FVector ProjectedB = ProjectPointOnLine(NodePositions[IndexA], AToC, AToB);

		float NewLength = (NodePositions[IndexB] - ProjectedB).Size();

		if (CalcVectorAngle(AToB, AToC) > MaxAngle)
		{
			float Opposite = (ProjectedB - NodePositions[IndexA]).Size() * Math::Tan(MaxAngle);
			NewLength = Math::Min(Opposite, NewLength);
		}

		if (CalcVectorAngle(-BToC, -AToC) > MaxAngle)
		{
			float Opposite = (ProjectedB - NodePositions[IndexC]).Size() * Math::Tan(MaxAngle);
			NewLength = Math::Min(Opposite, NewLength);
		}

		FVector PBToB = (NodePositions[IndexB] - ProjectedB);
		PBToB.Normalize();
		NodePositions[IndexB] = ProjectedB + PBToB * NewLength;
	}

	void RelaxConstraint(int IndexA, int IndexB, float DesiredDistance)
	{
		// Guard Clause in case the neighboring particles both have infinite mass which would result in a division by zero
		if (NodeInvertedMass[IndexA] == 0 && NodeInvertedMass[IndexB] == 0)
			return;

		FVector Direction = NodePositions[IndexB] - NodePositions[IndexA];
		Direction.Normalize();

		float Overshoot = NodePositions[IndexA].Distance(NodePositions[IndexB]) - DesiredDistance;

		// TArray<AActor> ToIgnore;
		// ToIgnore.Add(Gameplay::GetPlayerCharacter(0));
		// FHitResult AHit;
		// FHitResult BHit;

		// DETECT IF THERE IS A CORNER BETWEEN THESE TWO POINTS, IF THERE IS USE A DIFFERENT DIRECTION
		// IT'S SORT OF LIKE CREATING A FICTITIOUS CORNER PARTICLE THAT IS ALWAYS ATTACHED THERE
		// if (System::LineTraceSingle(NodePositions[IndexA], NodePositions[IndexB], ETraceTypeQuery::TraceTypeQuery_MAX, false, ToIgnore, EDrawDebugTrace::None, AHit, true))
		// {
		// 	if (System::LineTraceSingle(NodePositions[IndexB], NodePositions[IndexA], ETraceTypeQuery::TraceTypeQuery_MAX, false, ToIgnore, EDrawDebugTrace::None, BHit, true))
		// 	{
		// 		// IF THE CORNER IS OVER 90 DEGREES DO NOT DO THE CORNER LOGIC
		// 		if (AHit.Normal.DotProduct(BHit.Normal) <= 0)
		// 		{
		// 			NodePositions[IndexA] += Direction * Overshoot * (NodeInvertedMass[IndexA] / (NodeInvertedMass[IndexA] + NodeInvertedMass[IndexB]));
		// 			NodePositions[IndexB] -= Direction * Overshoot * (NodeInvertedMass[IndexB] / (NodeInvertedMass[IndexA] + NodeInvertedMass[IndexB]));
		// 			return;
		// 		}

		// 		// THIS IS THE TANGENT TO THE CORNER, SO IF YOU HAVE TWO WALLS CONNECTED AT AN ANGLE THEIR CORNER TANGENT IS GOING TO BE STRAIGHT UP
		// 		FVector CornerTangent = AHit.Normal.CrossProduct(BHit.Normal);
		// 		CornerTangent.Normalize();

		// 		FVector ADirection = -AHit.Normal.CrossProduct(CornerTangent);
		// 		FVector BDirection = BHit.Normal.CrossProduct(CornerTangent);

		// 		// A CASE
		// 		// System::DrawDebugLine(AHit.ImpactPoint, AHit.ImpactPoint + ADirection * 30, FLinearColor::Yellow, 5); // DIRECTION TO APPLY CORRECTION IN 
		// 		// System::DrawDebugLine(AHit.ImpactPoint, AHit.ImpactPoint + AHit.ImpactNormal * 30, FLinearColor::Red, 5); // IMPACT NORMAL

		// 		// B CASE
		// 		// System::DrawDebugLine(BHit.ImpactPoint, BHit.ImpactPoint + BDirection * 30, FLinearColor::Yellow, 5); // DIRECTION TO APPLY CORRECTION IN 
		// 		// System::DrawDebugLine(BHit.ImpactPoint, BHit.ImpactPoint + BHit.ImpactNormal * 30, FLinearColor::Red, 5); // IMPACT NORMAL

		// 		NodePositions[IndexA] += ADirection * Overshoot * (NodeInvertedMass[IndexA] / (NodeInvertedMass[IndexA] + NodeInvertedMass[IndexB]));
		// 		NodePositions[IndexB] += BDirection * Overshoot * (NodeInvertedMass[IndexB] / (NodeInvertedMass[IndexA] + NodeInvertedMass[IndexB]));

		// 		// SIMPLE BUT WRONG VERSION, ONLY WORKS FOR 90 DEGREE SITUATIONS
		// 		// NodePositions[IndexA] += BHit.Normal * Overshoot / 2;
		// 		// NodePositions[IndexB] += AHit.Normal * Overshoot / 2;
		// 	}
		// 	else
		// 	{
		// 		PrintError("What the fuck?");
		// 		NodePositions[IndexA] += Direction * Overshoot * (NodeInvertedMass[IndexA] / (NodeInvertedMass[IndexA] + NodeInvertedMass[IndexB]));
		// 		NodePositions[IndexB] -= Direction * Overshoot * (NodeInvertedMass[IndexB] / (NodeInvertedMass[IndexA] + NodeInvertedMass[IndexB]));
		// 	}
		// }
		// else
		{
			NodePositions[IndexA] += Direction * Overshoot * (NodeInvertedMass[IndexA] / (NodeInvertedMass[IndexA] + NodeInvertedMass[IndexB]));
			NodePositions[IndexB] -= Direction * Overshoot * (NodeInvertedMass[IndexB] / (NodeInvertedMass[IndexA] + NodeInvertedMass[IndexB]));
		}
	}

	void ResolveCollisions()
	{
		TArray<AActor> ToIgnore;
		ToIgnore.Add(Gameplay::GetPlayerCharacter(0));
		FHitResult Hit;

		for (int i = 0; i < NodePositions.Num(); i++)
		{
			FVector Position = NodePositions[i];
			if (System::SphereTraceSingle(Position, Position, RopeRadius, ETraceTypeQuery::TraceTypeQuery_MAX, false, ToIgnore, EDrawDebugTrace::None, Hit, true))
			{
				NodePositions[i] += Hit.Normal * Hit.PenetrationDepth;
				break;
			}
		}
	}

	void Jakobsen(int Count)
	{
		if (NodePositions.Num() <= 1)
			return;

		for (int i = 0; i < Count; i++)
		{
			// for (int j = 0; j < NodePositions.Num() - 2; j++)
			// 	RelaxAngleConstraint(j, j + 1, j + 2, 89 * 3.141592/180);

			// EXCEPTION FOR THE FIRST POINT SO THAT IT CAN HAVE A FLEXIBLE DESIRED DISTANCE
			RelaxConstraint(0, 1, ParticleDistance * ReelProgress);

			// ITERATES THROUGH THEM BACKWARDS SO THAT BOTH ENDS POINTS AREN'T PERFECTLY RESOLVED, AND THE OFFSET CAN BE USED TO CALCULATE FORCES APPLIED TO BOTH RIGID BODIES
			for (int j = NodePositions.Num() - 1; j > 1; j--)
				RelaxConstraint(j, j - 1, ParticleDistance);

			// THE OLD VERSION IN CASE SOMETHING IS BUSTED THAT I DON'T YET NOTICE
			// for (int j = 1; j < NodePositions.Num() - 1; j++)
			// 	RelaxConstraint(j, j + 1, RopeDensity);

			if (bCollisionEnabled && i % CollisionCheckModulo == 0)
				ResolveCollisions();
		}
	}

	void CheckIsGrounded()
	{
		TArray<AActor> ToIgnore;
		ToIgnore.Add(Gameplay::GetPlayerCharacter(0));
		FHitResult Hit;

		for (int i = 0; i < NodePositions.Num(); i++)
		{
			// IS IT TOUCHING ANY SORT OF SURFACE?
			NodeOnSurface[i] = (System::SphereTraceSingle(NodePositions[i], NodePositions[i], RopeRadius * 1.5, ETraceTypeQuery::TraceTypeQuery_MAX, false, ToIgnore, EDrawDebugTrace::None, Hit, true));
			// IS THAT SURFACE THE GROUND?
			NodeGrounded[i] = NodeOnSurface[i] && (Hit.Normal.DotProduct(FVector(0,0,1)) > 0.5);
		}
	}

	// RETURNS THE TENSION IN THAT SECTION OF ROPE IN THE DIRECTION OF A
	FVector CalculateRopeTension(int IndexA, int IndexB, float DesiredDistance) const
	{
		// MAKE SURE THE POINTS ARE NEXT TO EACH OTHER
		if (Math::Abs(IndexA - IndexB) != 1)
		{
			PrintError(f"Index {IndexA} and index {IndexB} are not adjacent!");
			return FVector::ZeroVector;
		}

		// EARLY RETURN IF THERE IS NO ROPE
		if (NodePositions.Num() == 0)
			return FVector::ZeroVector;
		
		float Overshoot = NodePositions[IndexA].Distance(NodePositions[IndexB]) - DesiredDistance;
		FVector Direction = NodePositions[IndexB] - NodePositions[IndexA];
		Direction.Normalize();

		return Direction * Overshoot;
	}

	float GetTotalTension() const
	{
		float TotalLength = 0;
		float DesiredLength = 0;
		float TotalTension;
		if(bIsPlayerGrappleRope)
		{
			for(int i = 1; i < NodePositions.Num(); i++)
			{
				TotalLength += (NodePositions[i-1]-NodePositions[i]).Size();
			}
			DesiredLength = (ParticleDistance*(NodePositions.Num()-2)) + (ReelProgress*ParticleDistance);
			TotalTension = TotalLength/DesiredLength;
			
		}
		else
		{
			for(int i = 1; i < NodePositions.Num(); i++)
			{
				TotalLength += (NodePositions[i-1]-NodePositions[i]).Size();
			}
			DesiredLength = (ParticleDistance*(NodePositions.Num()-1));
			TotalTension = TotalLength/DesiredLength;
		}
		if(NodePositions.Num()>1)
		{
			if(!bLinearTension)
			{
				if(TotalTension > 1)
				{
					// Trust, this makes the rope be completly tought before it applies any serious tension.
					TotalTension = ((TotalTension-1)**2)+1;
				}
				else
				{
					TotalTension = 1;
				}
			}
			return TotalTension;
		}
		else
		{
			return 1;
		}
	}

	// NOTE: THIS I'M NOT SURE SHOULD BE IN THE ROPE, MAYBE THIS SHOULD BE THE ROLE OF ANOTHER OBJECT?
	void ApplyTension(float DeltaSeconds)
	{
		if (NodePositions.Num() <= 1)
			return;

		float TotalTension = Math::Clamp(GetTotalTension(),0.0f , TensionLimit);
		
		FVector StartObjectTensionNormalized = (NodePositions[1] - NodePositions[0]);
		StartObjectTensionNormalized.Normalize();
		FVector StartObjectTension = StartObjectTensionNormalized * Math::Max((TotalTension)-1, 0);

		FVector EndObjectTensionNormalized = (NodePositions[NodePositions.Num()-2] - NodePositions[NodePositions.Num()-1]);
		EndObjectTensionNormalized.Normalize();
		FVector EndObjectTension = EndObjectTensionNormalized * Math::Max((TotalTension)-1, 0);
		
		if (bIsPlayerGrappleRope)
		{
			PlayerAlien.CharacterMovement.AddForce(StartObjectTension * DeltaSeconds * HooksConstant);
			PlayerAlien.CharacterMovement.AddForce(-StartObjectTension * DeltaSeconds* Math::Min(0, StartObjectTensionNormalized.DotProduct(PlayerAlien.Velocity))*DirectionalDamping);
			// Print(f"{StartObjectTensionNormalized.DotProduct(PlayerAlien.Velocity)}");
		}
		else
		{
			if (StartObject != nullptr && StartObject.IsSimulatingPhysics())
			{
				StartObject.AddForceAtLocation(StartObjectTension * DeltaSeconds * HooksConstant, StartObjectAttachPosition.WorldLocation);
				//Damping
				StartObject.AddForceAtLocation(-StartObjectTension * DeltaSeconds * Math::Min(0.0f, StartObjectTensionNormalized.DotProduct(StartObject.GetPhysicsLinearVelocityAtPoint(StartObjectAttachPosition.GetWorldLocation()))) * DirectionalDamping, StartObjectAttachPosition.WorldLocation);
			}
		}
		// if (PlayerAlien.Grapple.AttachedMesh.IsSimulatingPhysics())
		// 	PlayerAlien.Grapple.AttachedMesh.AddForceAtLocation(EndObjectTension*DeltaSeconds*HooksConstant, PlayerAlien.Grapple.AttachedPoint.WorldLocation);

		
		if (EndObject != nullptr && EndObject.IsSimulatingPhysics())
		{
			EndObject.AddForceAtLocation(EndObjectTension * DeltaSeconds * HooksConstant, EndObjectAttachPosition.WorldLocation);
			//Damping
			EndObject.AddForceAtLocation(-EndObjectTension * DeltaSeconds *  Math::Min(0.0f, EndObjectTensionNormalized.DotProduct(EndObject.GetPhysicsLinearVelocityAtPoint(EndObjectAttachPosition.GetWorldLocation()))) * DirectionalDamping, EndObjectAttachPosition.WorldLocation);
		}

		// if (PlayerAlien.Grapple.AttachedMesh.IsSimulatingPhysics())
		// 	PlayerAlien.Grapple.AttachedMesh.AddForceAtLocation(-ObjectTension * ObjectTensionNormalized.DotProduct(PlayerAlien.Grapple.AttachedMesh.GetComponentVelocity())*DirectionalDampening, PlayerAlien.Grapple.AttachedPoint.WorldLocation);
		// PlayerAlien.CharacterMovement.AddForce(-StartObjectTension * StartObjectTensionNormalized.DotProduct(PlayerAlien.Velocity)*DirectionalDampening);
		
		// PlayerAlien.CharacterMovement.AddImpulse((PlayerTension /* PlayerAlien.CharacterMovement.Mass*/) / DeltaSeconds);
		// if (PlayerAlien.Grapple.AttachedMesh != nullptr && PlayerAlien.Grapple.AttachedMesh.IsSimulatingPhysics())
		// {
		// 	PlayerAlien.Grapple.AttachedMesh.AddForceAtLocation(((ObjectTension * PlayerAlien.Grapple.AttachedMesh.Mass) / DeltaSeconds) * 3, PlayerAlien.Grapple.AttachedPoint.WorldLocation);
		// 	// PlayerAlien.Grapple.AttachedMesh.AddImpulseAtLocation(((ObjectTension * PlayerAlien.CharacterMovement.Mass) / DeltaSeconds) * 10, PlayerAlien.Grapple.AttachedPoint.WorldLocation);
		// }
	}

	void ApplyGravity()
	{
		for (int i = 0; i < NodePositions.Num(); i++)
		{
			NodeAccelerations[i] += FVector(0, 0, -9.8 * GravityConstant);
		}
	}

	void ApplyFriction(float DeltaSeconds)
	{
		for (int i = 0; i < NodePositions.Num(); i++)
		{
			if (NodeGrounded[i])
				NodeAccelerations[i] += ((NodeOldPositions[i] - NodePositions[i]) / DeltaSeconds) * FrictionConstant;
		}
	}

	void ApplyAirDrag(float DeltaSeconds)
	{
		for (int i = 0; i < NodePositions.Num(); i++)
		{
			if (!NodeOnSurface[i])
				NodeAccelerations[i] += ((NodeOldPositions[i] - NodePositions[i]) / DeltaSeconds) * AirDragConstant;
		}
	}

	void DrawRope()
	{
		// EARLY RETURN IF THERE IS NO ROPE
		if (NodePositions.Num() == 0)
			return;

		float TotalTension = GetTotalTension();

		for (int i = 0; i < NodePositions.Num() - 1; i++)
		{
			if(bDetachedReeling)
			{
				System::DrawDebugLine(NodePositions[i], NodePositions[i + 1], FLinearColor(0, 0, 0, 1), 0, RopeRadius/2.0f);
			}
			else
			{
				System::DrawDebugLine(NodePositions[i], NodePositions[i + 1], FLinearColor((Math::Lerp(0, 1, (TotalTension-1)/(TensionLimit-1))), 0, 0, 1), 0, RopeRadius/2.0f);
			}
			if (bDebugDrawSpheres)
			{
				if (NodeGrounded[i])
					System::DrawDebugSphere(NodePositions[i], RopeRadius, LineColor = FLinearColor::Yellow);
				else
					System::DrawDebugSphere(NodePositions[i], RopeRadius);
			}
		}

		if (bDebugDrawSpheres)
		{
			if (NodeGrounded.Last())
				System::DrawDebugSphere(NodePositions.Last(), RopeRadius, LineColor = FLinearColor::Yellow);
			else
				System::DrawDebugSphere(NodePositions.Last(), RopeRadius);
		}
	}

	void AddParticle(int IndexVal)
	{
		// SEEMS INCOMPREHENSIBLE TO ME BUT IT SEEMS LIKE I HAVE TO PLACE THESE IN VARIABLES BEFORE INSERTING THE VALUE
		// OTHERWISE SOMETIMES THE VALUE THAT GETS INSERTED SOMEHOW IS COMPLETELY WRONG
		FVector NewNodeOldPositionsVal = NodeOldPositions[IndexVal];
		FVector NewNodePositionsVal = NodePositions[IndexVal];
		FVector NewNodeAccelerationsVal = NodeAccelerations[IndexVal];
		float NewNodeMassVal = NodeInvertedMass[IndexVal];
		bool bNewNodeOnSurfaceVal = NodeOnSurface[IndexVal];
		bool bNewNodeGroundedVal = NodeGrounded[IndexVal];

		// SPAWN IN NEW NODE 
		NodeOldPositions.Insert(NewNodeOldPositionsVal, IndexVal);
		NodePositions.Insert(NewNodePositionsVal, IndexVal);
		NodeAccelerations.Insert(NewNodeAccelerationsVal, IndexVal);
		NodeInvertedMass.Insert(NewNodeMassVal, IndexVal);
		NodeOnSurface.Insert(bNewNodeOnSurfaceVal, IndexVal);
		NodeGrounded.Insert(bNewNodeGroundedVal, IndexVal);

		// ADD SPLINE VALUES
		Spline.AddSplinePoint(NewNodePositionsVal, ESplineCoordinateSpace::World, false);
		Spline.UpdateSpline();
	}

	void RemoveParticle(int IndexVal)
	{
		// REMOVE A NODE
		NodeOldPositions.RemoveAt(IndexVal);
		NodePositions.RemoveAt(IndexVal);
		NodeAccelerations.RemoveAt(IndexVal);
		NodeInvertedMass.RemoveAt(IndexVal);
		NodeOnSurface.RemoveAt(IndexVal);
		NodeGrounded.RemoveAt(IndexVal);

		Spline.RemoveSplinePoint(0, false);
		Spline.UpdateSpline();
	}

	void Reel(float Diff)
	{
		if (NodePositions.Num() == 0)
			return;

		ReelProgress += Diff * World.GetDeltaSeconds() * ParticleDistance;

		if (ReelProgress > 1)
		{
			if ((NodePositions.Num() - 1) * ParticleDistance < PlayerAlien.Grapple.MaxRopeLength)
			{
				// REMOVE PROGRESS
				ReelProgress -= 1;

				AddParticle(0);

				// SET THE SECOND NODE TO NOT HAVE INFINITE MASS; INSTEAD TAKE WHATEVER IT USED TO HAVE
				NodeInvertedMass[1] = NodeInvertedMass[2];

				SplineMeshes[NodePositions.Num() - 2].SetHiddenInGame(false);
			}
			else if(ReelProgress >= 1)
			{
				ReelProgress = 1;
				PlayerAlien.StopSlack();	
			}
		}

		// PREVENTS REELING IN IF YOU'VE ALREADY REACHED THE MINIMUM NUMBER; ALSO KEEPS THE NODES EQUIDISTANT
		else if (NodePositions.Num() == MinimumNumberOfNodes)
		{
			ReelProgress = 1;
			PlayerAlien.StopReel();	
		}

		else if (ReelProgress < 0)
		{
			// BEFORE REMOVING ANY NODE, MAKE SURE THAT THERE ARE MORE THAN JUST THE END POINTS
			if (NodePositions.Num() > MinimumNumberOfNodes)
			{
				// REMOVE PROGRESS
				ReelProgress += 1;

				RemoveParticle(0);

				if (NodePositions.Num() == 0)
				{
					RemoveLink();
					ParticleDistance = DefaultParticleDistance;
					if(bIsPlayerGrappleRope)
					{
						PlayerAlien.GrappleHookMesh.SetHiddenInGame(false);
						PlayerAlien.Grapple.GrappleHook = nullptr;
						PlayerAlien.Grapple.bReadyToShoot = true;
					}
					return;
				}

				// SET THE FIRST NODE TO STILL HAVE INFINITE MASS
				NodeInvertedMass[0] = 0;

				SplineMeshes[NodePositions.Num() - 1].SetHiddenInGame(true);

			}
			// IF THERE ARE JUST THE END POINTS, CLAMP PROGRESS AT ZERO AND LET IT BE
			else if(ReelProgress <= 0)
			{
				ReelProgress = 0;
				PlayerAlien.StopReel();	
			}
		}
	}
	void DetachedReel(float Diff)
	{

		ReelProgress += Diff * World.GetDeltaSeconds() * ParticleDistance;
		ParticleDistance -= World.GetDeltaSeconds() * 7;
				
		// ParticleDistance *= 0.5 * World.GetDeltaSeconds();
		if (NodePositions.Num() <= 2 || ParticleDistance <= 0)
		{
			RemoveLink();
			// ParticleDistance = DefaultParticleDistance;
			PlayerAlien.GrappleHookMesh.SetHiddenInGame(false);
			if(PlayerAlien.Grapple.GrappleHook != nullptr)
			{
				PlayerAlien.Grapple.GrappleHook.DestroyActor();
			}
			bDetachedReeling=false;
			// Print("done");
			PlayerAlien.Grapple.bReadyToShoot=true;
			ParticleDistance = DefaultParticleDistance;
			GravityConstant = DefaultGravityConstant;
			AirDragConstant = DefaultAirDragConstant;
			FrictionConstant = DefaultFrictionConstant;
			PlayerAlien.GrappleGunReelFast.Stop();
			return;
		}
		else if (ReelProgress < 0)
		{
			// REMOVE PROGRESS
			ReelProgress += 1;

			RemoveParticle(0);

			SplineMeshes[NodePositions.Num() - 1].SetHiddenInGame(true);

			NodeInvertedMass[0] = 0;
			
		}
	}

	// Everything beyond the index will be sorted inte theri own rope
	void CutRope(int Index)
	{

		if (!bIsPlayerGrappleRope || bDetachedReeling || Index<=0 || Index >= NodePositions.Num()-1)
			return;

        ARope NewRope = Cast<ARope>(SpawnActor(GetClass()));		
		NewRope.LifeTime = 0;
		NewRope.bIsPlayerGrappleRope = false;
		// Makes the new rope behave cooler and calm down faster
		NewRope.GravityConstant = DefaultGravityConstant * 2;
		NewRope.AirDragConstant = DefaultAirDragConstant / 2;
		UStaticMesh CurrentRopeMesh;

		int NumberOfNodes = NodePositions.Num();

		NewRope.NodePositions.SetNum(NumberOfNodes-Index);
		NewRope.NodeOldPositions.SetNum(NumberOfNodes-Index);
		NewRope.NodeAccelerations.SetNum(NumberOfNodes-Index);
		NewRope.NodeInvertedMass.SetNum(NumberOfNodes-Index);
		NewRope.NodeGrounded.SetNum(NumberOfNodes-Index);
		NewRope.NodeOnSurface.SetNum(NumberOfNodes-Index);
		

		NewRope.NodePositions.Copy(NodePositions, Index, NumberOfNodes-Index);
		NewRope.NodeOldPositions.Copy(NodeOldPositions, Index, NumberOfNodes-Index);
		NewRope.NodeAccelerations.Copy(NodeAccelerations, Index, NumberOfNodes-Index);
		NewRope.NodeInvertedMass.Copy(NodeInvertedMass, Index, NumberOfNodes-Index);
		NewRope.NodeGrounded.Copy(NodeGrounded, Index, NumberOfNodes-Index);
		NewRope.NodeOnSurface.Copy(NodeOnSurface, Index, NumberOfNodes-Index);
		NewRope.Spline.ClearSplinePoints();

		NewRope.Spline.SetSplinePoints(NewRope.NodePositions, ESplineCoordinateSpace::World, true);
		// NewRope.SplineMeshes.RemoveAt(0);
		
		// NodePositions.Co;
		for(int i = Index; i<NumberOfNodes-2; i++)
		{
			NodePositions.RemoveAt(Index);
			NodeOldPositions.RemoveAt(Index);
			NodeAccelerations.RemoveAt(Index);
			NodeInvertedMass.RemoveAt(Index);
			NodeGrounded.RemoveAt(Index);
			NodeOnSurface.RemoveAt(Index);
			Spline.RemoveSplinePoint(i, false);
		}
		Spline.UpdateSpline();

		if (bIsPlayerGrappleRope)
		{
			CurrentRopeMesh = PlayerAlien.GrappleRopeMesh;
		}
		else
		{
			CurrentRopeMesh = RopeMesh;
		}
		
		for (int i = 0; i < NewRope.NodePositions.Num()-1; i++)
		{
			NewRope.SplineMeshes.Add(USplineMeshComponent::Create(NewRope));
			NewRope.SplineMeshes[i].SetStaticMesh(CurrentRopeMesh);
			NewRope.SplineMeshes[i].SetMaterial(0, Material::CreateDynamicMaterialInstance(CurrentRopeMesh.GetMaterial(0)));
			NewRope.SplineMeshes[i].SetForwardAxis(ESplineMeshAxis::Z);
			NewRope.SplineMeshes[i].SetHiddenInGame(false);
			NewRope.SplineMeshes[i].SetStartScale(FVector2D(0.5, 0.5), false);
			NewRope.SplineMeshes[i].SetEndScale(FVector2D(0.5, 0.5));
		}

		// NewRope.SplineMeshes[0].SetHiddenInGame(true);
		// NewRope.SplineMeshes.RemoveAt(Index);
		USceneComponent NewEnd = USceneComponent::Create(EndActor);
		NewEnd.AttachTo(EndObject);
		NewEnd.WorldLocation=EndObjectAttachPosition.WorldLocation;
		NewRope.EndObjectAttachPosition = NewEnd;
		NewRope.Spline.UpdateSpline();
		NewRope.JakobsenCount = 10;
		NewRope.ParticleDistance *= NewRope.GetTotalTension();

		// NewRope.ReelProgress = (RopeLength / ParticleDistance) - Math::FloorToInt(RopeLength / ParticleDistance);
		PlayerAlien.Grapple.GrappleHook.AttachToActor(EndActor);
		PlayerAlien.Grapple.GrappleHook.SetActorEnableCollision(false);
		// PlayerAlien.Grapple.GrappleHook.SetLifeSpan(3);
		System::SetTimer(PlayerAlien.Grapple.GrappleHook, n"Disable", CutRopeLifeTime, false);
		NewRope.SetLifeSpan(CutRopeLifeTime);
		PlayerAlien.Grapple.GrappleHook.ActorTickEnabled = false;
		PlayerAlien.Grapple.GrappleHook=nullptr;


		DetachEndPoint();
	}

	void DetachEndPoint()
	{
		if (!bDetachedReeling && PlayerAlien.Grapple.bAttachedRope)
		{
			PlayerAlien.Grapple.bReadyToShoot = false;
			bDetachedReeling = true;
			NodeInvertedMass.Last() = 0.001;
			// AirDragConstant = 1;
			// GravityConstant = 1;
			// remove tension
			ParticleDistance *= GetTotalTension();
		}
		EndActor = nullptr;
		EndObject = nullptr;
		if(PlayerAlien.Grapple.GrappleHook != nullptr)
		{
			PlayerAlien.Grapple.GrappleHook.SetActorHiddenInGame(false);
		}
		PlayerAlien.GrappleGunReelFast.Sound = PlayerAlien.GrappleReelInFast;
		PlayerAlien.GrappleGunReelFast.Play();
		if(bIsPlayerGrappleRope)
		{
			PlayerAlien.Grapple.bAttachedRope=false;
		} 
	}

	void RemoveLink()
	{
		NodePositions.Empty();
		NodeOldPositions.Empty();
		NodeAccelerations.Empty();
		NodeInvertedMass.Empty();
		NodeGrounded.Empty();
		NodeOnSurface.Empty();

		for (int i = 0; i < SplineMeshes.Num(); i++)
			SplineMeshes[i].DestroyComponent();
		SplineMeshes.Empty();

		bDetachedReeling = false;
	}
	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		RemoveLink();
	}
};