namespace StbImageBeef
{
#if !STBSHARP_INTERNAL
	public
#else
	internal
#endif
	class AnimatedFrameResult : ImageResult
	{
		public int32 DelayInMs { get; set; }
	}
}