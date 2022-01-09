# StbImageBeef
[![Chat](https://img.shields.io/discord/628186029488340992.svg)](https://discord.gg/ZeHxhCY)

StbImageBeef is Beef port of the stb_image.h, which is C library to load images in JPG, PNG, BMP, TGA, PSD and GIF formats.

It is important to note, that this project is **port**(not **wrapper**). Entire C code had been ported to Beef.

# Usage
```c#
    FileStream fs = scope FileStream();
    fs.Open(path, .Open, .Read);
    ImageResult image = ImageResult.FromStream(fs, ColorComponents.RedGreenBlueAlpha);
```

## ImageInfo
ImageInfo class could be used to obtain an image info like this:
```c#
  ImageInfo? info = ImageInfo.FromStream(imageStream);
```
It'll return null if the image type isnt supported, otherwise it'll return the image info(width, height, color components, etc).

# Reliability & Performance
There is special app to measure reliability & performance of StbImageBeef in comparison to the original stb_image.h: https://github.com/StbBeef/StbImageBeef/tree/master/samples/StbImageBeef.Testing

It goes through every image file in the specified folder and tries to load it 10 times with StbImageBeef, then 10 times with native wrapper over the original stb_image.h(Stb.Native). Then it compares whether the results are byte-wise similar and also calculates loading times. Also it sums up and reports loading times for each method.

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
