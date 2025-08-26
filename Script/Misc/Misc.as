UFUNCTION(BlueprintCallable)
bool IsEditor()
{
	#if EDITOR
	return true;
	#else
	return false;
	#endif
}