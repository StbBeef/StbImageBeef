namespace StbImageBeef
{
#if !STBSHARP_INTERNAL
	public
#else
	internal
#endif
	class AnimatedFrameResult : ImageResult
	{
		public int32 Delay
		{
			get; set;
		}
	}
}