using System.Threading;

namespace StbImageBeef
{
#if !STBSHARP_INTERNAL
	public
#else
	internal
#endif
	static class MemoryStats
	{
		private static int _allocations;

		public static int Allocations => _allocations;

		public static void Allocated()
		{
			Interlocked.Increment(ref _allocations);
		}

		public static void Freed()
		{
			Interlocked.Decrement(ref _allocations);
		}
	}
}