using System.Threading;

namespace Hebron.Runtime
{
	static class MemoryStats
	{
		private static int32 _allocations;
		 
		public static int32 Allocations
		{
			get
			{
				return _allocations;
			}
		}

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