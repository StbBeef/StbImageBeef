using System;
using System.IO;

namespace StbImageBeef
{
	class Program
	{
		public static int Main(String[] args)
		{
			ImageResult image;
			FileStream stream = new .();

			stream.Open(@"C:\Projects\TestImages\BasicSample.jpg", .Read, .None);

			image = ImageResult.FromStream(stream, ColorComponents.RedGreenBlueAlpha);

			stream.Close();

			delete stream;

			return 0;
		}
	}
}