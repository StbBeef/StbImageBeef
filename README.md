# StbImageBeef
[![Chat](https://img.shields.io/discord/628186029488340992.svg)](https://discord.gg/ZeHxhCY)

StbImageBeef is C# port of the stb_image.h, which is C library to load images in JPG, PNG, BMP, TGA, PSD, GIF and HDR formats.

It is important to note, that this project is **port**(not **wrapper**). Original C code had been ported to C#. Therefore StbImageBeef doesnt require any native binaries.

The porting hasn't been done by hand, but using [Sichem](https://github.com/rds1983/Sichem), which is the C to C# code converter utility.
    
# Usage
StbImageBeef exposes API similar to stb_image.h. However that API is complicated and deals with raw unsafe pointers.

Thus several utility classes had been made to wrap that functionality.

'ImageResult.FromStream' loads an image from stream:
```c# 
  using(var stream = File.OpenRead(path))
  {
    ImageResult image = ImageResult.FromStream(stream, ColorComponents.RedGreenBlueAlpha);
  }
```

'ImageResult.FromMemory' loads an image from byte array:
```c# 
  byte[] buffer = File.ReadAllBytes(path);
  ImageResult image = ImageResult.FromMemory(buffer, ColorComponents.RedGreenBlueAlpha);
```

Both code samples will try to load an image (JPG/PNG/BMP/TGA/PSD/GIF) located at 'path'.

## ImageInfo
ImageInfo class could be used to obtain an image info like this:
```c#
  ImageInfo? info = ImageInfo.FromStream(imageStream);
```
It'll return null if the image type isnt supported, otherwise it'll return the image info(width, height, color components, etc).

# Reliability & Performance
There is special app to measure reliability & performance of StbImageBeef in comparison to the original stb_image.h: https://github.com/StbBeef/StbImageBeef/tree/master/tests/StbImageBeef.Testing

It goes through every image file in the specified folder and tries to load it 10 times with StbImageBeef, then 10 times with C++/CLI wrapper over the original stb_image.h(Stb.Native). Then it compares whether the results are byte-wise similar and also calculates loading times. Also it sums up and reports loading times for each method.

Moreover SixLabor ImageBeef 1.0.4 is included in the testing too.

I've used it over following set of images: https://github.com/StbBeef/TestImages

The byte-wise comprarison results are similar for StbImageBeef and Stb.Native.

And performance comparison results are(times are total loading times):
```
28268 -- $StbImageSharp - .png: 147141 ms, .bmp: 170 ms, .jpg: 31940 ms, .tga: 10296 ms, .psd: 19 ms, Total: 189566 ms
28268 -- $Stb.Native - .png: 92757 ms, .bmp: 402 ms, .jpg: 24248 ms, .tga: 5398 ms, .psd: 0 ms, Total: 122805 ms
28268 -- $Total files processed - .png: 568, .bmp: 7, .jpg: 170, .tga: 41, .psd: 1, Total: 787
28268 -- $StbImageSharp/Stb.Native matches/processed - 787/787
```

# License
Public Domain

# Credits
* [stb](https://github.com/nothings/stb)
