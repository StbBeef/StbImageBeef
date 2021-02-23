using System;

namespace StbImageSharp
{
	static class CRuntime
	{
		public static void* malloc(uint64 size)
		{
			return malloc((int64)size);
		}

		public static void* malloc(int64 size)
		{
			var ptr = Internal.StdMalloc((int)size);

			MemoryStats.Allocated();

			return ptr;
		}

		public static void memcpy(void* a, void* b, int64 size)
		{
			Internal.MemCpy(a, b, (int)size);
		}

		public static void memcpy(void* a, void* b, uint64 size)
		{
			memcpy(a, b, (int64)size);
		}

		public static void memmove(void* a, void* b, int64 size)
		{
			Internal.MemMove(a, b, (int)size);
		}

		public static void memmove(void* a, void* b, uint64 size)
		{
			memmove(a, b, (int64)size);
		}

		public static int memcmp(void* a, void* b, int64 size)
		{
			return Internal.MemCmp(a, b, (int)size);
		}

		public static int memcmp(void* a, void* b, uint64 size)
		{
			return memcmp(a, b, (int64)size);
		}

		public static void free(void* a)
		{
			if (a == null)
				return;

			Internal.Free(a);

			MemoryStats.Freed();
		}

		public static void memset(void* ptr, int value, int64 size)
		{
			Internal.MemSet(ptr, (uint8)value, (int)size);
		}

		public static void memset(void* ptr, int value, uint64 size)
		{
			memset(ptr, value, (int64)size);
		}

		public static uint _lrotl(uint x, int y)
		{
			return (x << y) | (x >> (32 - y));
		}

		public static void* realloc(void* a, int64 newSize)
		{
			if (a == null)
				return malloc(newSize);

			var newPtr = malloc(newSize);
			memcpy(newPtr, a, newSize);

			free(a);

			return newPtr;
		}

		public static void* realloc(void* a, uint64 newSize)
		{
			return realloc(a, (int64)newSize);
		}

		public static int abs(int v)
		{
			return Math.Abs(v);
		}

		public static void SetArray<T>(T[] data, T value)
		{
			for (var i = 0; i < data.Count; ++i)
				data[i] = value;
		}
	}
}