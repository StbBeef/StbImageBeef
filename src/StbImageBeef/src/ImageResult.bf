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

		public ~this()
		{
			if (Data != null)
			{
				CRuntime.free(Data);
				Data = null;
			}
		}

		internal static ImageResult FromResult(uint8* result, int32 width, int32 height, ColorComponents comp, ColorComponents req_comp)
		{
			if (result == null)
				return null;

			var image = new ImageResult();
			image.Width = width;
			image.Height = height;
			image.SourceComp = comp;
			image.Comp = req_comp == ColorComponents.Default ? comp : req_comp;
			image.Data = result;

			return image;
		}

		public static ImageResult FromStream(Stream stream,
			ColorComponents requiredComponents = ColorComponents.Default)
		{
			uint8* result = null;

			int32 x = 0, y = 0, comp = 0;

			var context = scope stbi__context(stream);

			result = stbi__load_and_postprocess_8bit(context, &x, &y, &comp, ((int32)requiredComponents));

			return FromResult(result, x, y, (ColorComponents)comp, requiredComponents);
		}

		public static ImageResult FromMemory(List<uint8> data, ColorComponents requiredComponents = ColorComponents.Default)
		{
			var stream =  scope MemoryStream(data);
			return FromStream(stream, requiredComponents);
		}
	}
}