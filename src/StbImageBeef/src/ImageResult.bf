using System;
using System.IO;
using System.Collections;
using Hebron.Runtime;
using static StbImageBeef.StbImage;

namespace StbImageBeef
{
#if !STBSHARP_INTERNAL
	public
#else
	internal
#endif
	class ImageResult
	{
		public int32 Width
		{
			get; set;
		}
		public int32 Height
		{
			get; set;
		}
		public ColorComponents SourceComp
		{
			get; set;
		}
		public ColorComponents Comp
		{
			get; set;
		}
		public uint8* Data
		{
			get; set;
		}

		public this(uint8* result, int32 width, int32 height, ColorComponents comp, ColorComponents req_comp)
		{
			Width = width;
			Height = height;
			SourceComp = comp;
			Comp = req_comp == ColorComponents.Default ? comp : req_comp;
			Data = result;
		}

		public ~this()
		{
			if (Data != null)
			{
				CRuntime.free(Data);
				Data = null;
			}
		}

		public static uint8* RawFromStream(Stream stream, ColorComponents requiredComponents, out int32 width, out int32 height, out ColorComponents sourceComp)
		{
			uint8* result = null;

			width = height = 0;
			sourceComp = ColorComponents.Default;

			var context = scope stbi__context(stream);

			int32 comp = 0;
			result = stbi__load_and_postprocess_8bit(context, &width, &height, &comp, ((int32)requiredComponents));

			sourceComp = (ColorComponents)comp;

			return result;
		}

		public static uint8* RawFromMemory(List<uint8> data, ColorComponents requiredComponents, out int32 width, out int32 height, out ColorComponents sourceComp)
		{
			var stream = scope MyMemoryStream(data);
			return RawFromStream(stream, requiredComponents, out width, out height, out sourceComp);
		}

		public static ImageResult FromStream(Stream stream, ColorComponents requiredComponents = ColorComponents.Default)
		{
			int32 width, height;
			ColorComponents sourceComp;

			var result = RawFromStream(stream, requiredComponents, out width, out height, out sourceComp);

			return new ImageResult(result, width, height, sourceComp, requiredComponents);
		}

		public static ImageResult FromMemory(List<uint8> data, ColorComponents requiredComponents = ColorComponents.Default)
		{
			var stream = scope MyMemoryStream(data);
			return FromStream(stream, requiredComponents);
		}
	}
}