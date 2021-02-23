using System;

namespace StbImageBeef
{
	static class CRuntime
	{
		public static void* malloc(uint64 size)
		{
			return malloc((int64)size);
		}

		public static void* malloc(int64 size)
		{
			var ptr = Internal.StdMalloc((int32)size);

			MemoryStats.Allocated();

			return ptr;
		}

		public static void memcpy(void* a, void* b, int64 size)
		{
			Internal.MemCpy(a, b, (int32)size);
		}

		public static void memcpy(void* a, void* b, uint64 size)
		{
			memcpy(a, b, (int64)size);
		}

		public static void memmove(void* a, void* b, int64 size)
		{
			Internal.MemMove(a, b, (int32)size);
		}

		public static void memmove(void* a, void* b, uint64 size)
		{
			memmove(a, b, (int64)size);
		}

		public static int32 memcmp(void* a, void* b, int64 size)
		{
			return (int32)Internal.MemCmp(a, b, size);
		}

		public static int32 memcmp(void* a, void* b, uint64 size)
		{
			return memcmp(a, b, (int64)size);
		}

		public static void free(void* a)
		{
			if (a == null)
				return;

			Internal.StdFree(a);

			MemoryStats.Freed();
		}

		public static void memset(void* ptr, int32 value, int64 size)
		{
			Internal.MemSet(ptr, (uint8)value, (int32)size);
		}

		public static void memset(void* ptr, int32 value, uint64 size)
		{
			memset(ptr, value, (int64)size);
		}

		public static uint32 _lrotl(uint32 x, int32 y)
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

		public static int32 abs(int32 v)
		{
			return Math.Abs(v);
		}

		public static void SetArray<T>(T[] data, T value)
		{
			for (int32 i = 0; i < data.Count; ++i)
				data[i] = value;
		}
	}
}