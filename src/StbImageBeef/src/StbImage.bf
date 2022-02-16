using System;
using System.IO;

namespace StbImageBeef
{
#if !STBSHARP_INTERNAL
	public
#else
	internal
#endif
	static class StbImage
	{
		public static String stbi__g_failure_reason;
		public static readonly char8[] stbi__parse_png_file_invalid_chunk = new char8[25] ~ delete _;

		public class stbi__context
		{
			public uint8[] _tempBuffer;
			public int32 img_n = 0;
			public int32 img_out_n = 0;
			public int32 img_x = 0;
			public int32 img_y = 0;

			public this(Stream stream)
			{
				Stream = stream;
			}

			public Stream Stream { get; }
		}

		private static int32 stbi__err(String str)
		{
			stbi__g_failure_reason = str;
			return 0;
		}

		[Inline]
		public static uint8 stbi__get8(stbi__context s)
		{
			return s.Stream.Read<uint8>();
		}

		[Inline]
		public static void stbi__skip(stbi__context s, int32 skip)
		{
			s.Stream.Seek(s.Stream.Position + skip, .Absolute);
		}

		[Inline]
		public static void stbi__rewind(stbi__context s)
		{
			s.Stream.Seek(0, .Absolute);
		}

		[Inline]
		public static int32 stbi__at_eof(stbi__context s)
		{
			return s.Stream.Position == s.Stream.Length ? 1 : 0;
		}

		public static int32 stbi__getn(stbi__context s, uint8* buf, int32 size)
		{
			int32 i = 0;
			for(; i < size; ++i)
			{
				if (stbi__at_eof(s) == 1)
				{
					break;
				}

				buf[i] = stbi__get8(s);

			}

			return i;
		}
	}
}