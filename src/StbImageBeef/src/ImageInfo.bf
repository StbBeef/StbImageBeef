using System.IO;

namespace StbImageBeef
{
#if !STBSHARP_INTERNAL
	public
#else
	internal
#endif
	struct ImageInfo
	{
		public int32 Width;
		public int32 Height;
		public ColorComponents ColorComponents;
		public int32 BitsPerChannel;


		public static ImageInfo? FromStream(Stream stream)
		{
			int32 width = 0, height = 0, comp = 0;
			var context = new StbImage.stbi__context(stream);

			var is16Bit = StbImage.stbi__is_16_main(context) == 1;
			StbImage.stbi__rewind(context);

			var infoResult = StbImage.stbi__info_main(context, &width, &height, &comp);
			StbImage.stbi__rewind(context);

			if (infoResult == 0) return null;

			ImageInfo result = default;
			result.Width = width;
			result.Height = height;
			result.ColorComponents = (ColorComponents)comp;
			result.BitsPerChannel  = is16Bit ? 16 : 8;

			return result;

		}
	}
}