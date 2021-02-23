using System;
using System.IO;
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
		public int Width
		{
			get; set;
		}
		public int Height
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

		internal static ImageResult FromResult(uint8* result, int width, int height, ColorComponents comp, ColorComponents req_comp)
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

			int x = 0, y = 0, comp = 0;

			var context = new stbi__context(stream);

			result = stbi__load_and_postprocess_8bit(context, &x, &y, &comp, (int)requiredComponents);

			return FromResult(result, x, y, (ColorComponents)comp, requiredComponents);
		}
	}
}