using System;
using System.IO;
using System.Collections;
using Stb.Native;
using System.Diagnostics;
using System.Threading;
using System.Threading.Tasks;
using Hebron.Runtime;

namespace StbImageBeef.Testing
{
	static class Program
	{
		private struct LoadResult
		{
			public this(int width, int height, ColorComponents components, uint8* data, int timeInMs)
			{
				Width = width;
				Height = height;
				Components = components;
				Data = data;
				TimeInMs = timeInMs;
			}

			public int Width;
			public int Height;
			public ColorComponents Components;
			public uint8* Data;
			public int TimeInMs;
		}

		private class LoadingTimes
		{
			private readonly Dictionary<StringView, int> _byExtension = new Dictionary<StringView, int>();
			private readonly Dictionary<StringView, int> _byExtensionCount = new Dictionary<StringView, int>();
			private int _total, _totalCount;

			public void Add(StringView ext, int value)
			{
				if (!_byExtension.ContainsKey(ext))
				{
					_byExtension[ext] = 0;
					_byExtensionCount[ext] = 0;
				}

				_byExtension[ext] += value;
				++_byExtensionCount[ext];
				_total += value;
				++_totalCount;
			}

			public void BuildString(String sb)
			{
				sb.Clear();
				foreach (var pair in _byExtension)
				{
					var key = pair.key;
					var value = pair.value;
					sb.AppendF($"{key}: {value} ms, ");
				}

				sb.AppendF($"Total: {_total} ms");
			}

			public void BuildStringCount(String sb)
			{
				sb.Clear();

				foreach (var pair in _byExtensionCount)
				{
					sb.AppendF($"{pair.key}: {pair.value}, ");
				}

				sb.AppendF(scope $"Total: {_totalCount}");
			}
		}

		private const int LoadTries = 10;
		private static int tasksStarted;
		private static int filesProcessed, filesMatches;
		private static LoadingTimes stbImageSharpTotal = new LoadingTimes();
		private static LoadingTimes stbNativeTotal = new LoadingTimes();

		public static void Log(StringView fmt, params Object[] args)
		{
			String message = scope String();
			message.AppendF(fmt, params args);

			Console.WriteLine($"{Thread.CurrentThread.Id} -- ${message}");
		}

		private static void BeginWatch(Stopwatch sw)
		{
			sw.Restart();
		}

		private static int EndWatch(Stopwatch sw)
		{
			sw.Stop();
			return (int)sw.ElapsedMilliseconds;
		}

		private static LoadResult ParseTest(String name, LoadDelegate load)
		{
			var sw = scope Stopwatch();

			Log($"With ${name}");
			int32 x = 0, y = 0;
			var comp = ColorComponents.Grey;
			uint8 *parsed = null;
			BeginWatch(sw);

			for (var i = 0; i < LoadTries; ++i)
				parsed = load(out x, out y, out comp);

			var size = x * y * 4;
			Log($"x: {x}, y: {y}, comp: {comp}, size: {size}");
			var passed = EndWatch(sw) / LoadTries;
			Log($"Span: {passed} ms");

			return LoadResult(x, y, comp, parsed, passed);
		}

		public static bool RunTests(String imagesPath)
		{
			var files = Directory.EnumerateFiles(imagesPath, "*.*");

			foreach (var file in files)
			{
				var path = scope String();
				file.GetFilePath(path);
				ThreadProc(path);
				Interlocked.Increment(ref tasksStarted);
			}

			return true;
		}

		private static void ThreadProc(String f)
		{
			if (!f.EndsWith(".bmp") && !f.EndsWith(".jpg") && !f.EndsWith(".png") &&
				!f.EndsWith(".jpg") && !f.EndsWith(".psd") && !f.EndsWith(".pic") &&
				!f.EndsWith(".tga") && !f.EndsWith(".hdr"))
			{
				Interlocked.Decrement(ref tasksStarted);
				return;
			}

			bool match = false;
			var err = scope String();

			repeat {
				Log(String.Empty);
				var dt = scope String();
				DateTime.Now.ToLongTimeString(dt);
				Log($"{dt}: Loading {f} into memory");

				var dataList = scope List<uint8>();
				var result = File.ReadAll(f, dataList);

				var ext =  scope String();
				Path.GetExtension(f, ext);
				ext.ToLower();

				Log("----------------------------");

				var stbImageSharpResult = ParseTest(
					"StbImageSharp",
					scope (x, y, ccomp) =>
					{
						var dataListClone = new List<uint8>();
						dataListClone.AddRange(dataList);
						var img = ImageResult.FromMemory(dataListClone, ColorComponents.RedGreenBlueAlpha);

						x = img.Width;
						y = img.Height;
						ccomp = img.SourceComp;

						var res = img.Data;

						delete img;

						return res;
					});

				var stbNativeResult = ParseTest(
					"Stb.Native",
					scope (x, y, ccomp) =>
					{
						x = y = 0;
						int32 icomp = 0;
						var result = StbNative.stbi_load_from_memory(dataList.Ptr, (int32)dataList.Count, &x, &y, &icomp, (int)ColorComponents.RedGreenBlueAlpha);
						ccomp = (ColorComponents)icomp;


						return result;
					});


				if (stbImageSharpResult.Width != stbNativeResult.Width) {
					err.AppendF($"Inconsistent x: StbSharp={stbImageSharpResult.Width}, Stb.Native={stbNativeResult.Width}");
					break;
				}

				if (stbImageSharpResult.Height != stbNativeResult.Height) {
					err.AppendF($"Inconsistent height: StbSharp={stbImageSharpResult.Height}, Stb.Native={stbNativeResult.Height}");
					break;
				}

				if (stbImageSharpResult.Components != stbNativeResult.Components) {
					err.AppendF($"Inconsistent components: StbSharp={stbImageSharpResult.Components}, Stb.Native={stbNativeResult.Components}");
					break;
				}

				var length = stbImageSharpResult.Width * stbImageSharpResult.Height * 4;

				var dataMatches = true;
				for (var i = 0; i < length; ++i) {
					if (stbImageSharpResult.Data[i] != stbNativeResult.Data[i]) {
						err.AppendF($"Inconsistent data: index={i}, StbSharp={(int)stbImageSharpResult.Data[i]}, Stb.Native={(int)stbNativeResult.Data[i]}");
						dataMatches = false;
						break;
					}
				}

				if (!dataMatches) {
					break;
				}

				match = true;

				stbImageSharpTotal.Add(ext, stbImageSharpResult.TimeInMs);
				stbNativeTotal.Add(ext, stbNativeResult.TimeInMs);

				GC.Collect();
			} while(false);

			if (match)
			{
				Interlocked.Increment(ref filesMatches);
			} else {
				Log($"Error: {err}");
			}

			Interlocked.Increment(ref filesProcessed);
			Interlocked.Decrement(ref tasksStarted);

			var s = scope String();
			stbImageSharpTotal.BuildString(s);
			Log("StbImageSharp - {0}", s);
			s = scope String();
			stbNativeTotal.BuildString(s);
			Log("Stb.Native - {0}", s);
			s = scope String();
			stbImageSharpTotal.BuildStringCount(s);
			Log("Total files processed - {0}", s);
			Log("StbImageSharp/Stb.Native matches/processed - {0}/{1}", filesMatches, filesProcessed);
			Log("Tasks left - {0}", tasksStarted);
			Log("Native Memory Allocations - {0}", MemoryStats.Allocations);
		}

		public static int Main(String[] args)
		{
			if (args == null || args.Count < 1)
			{
				Console.WriteLine("Usage: StbImageBeef.Testing <path_to_folder_with_images>");
				return 1;
			}

			var start = DateTime.Now;

			var res = RunTests(args[0]);
			var passed = DateTime.Now - start;
			Log("Span: {0} ms", passed.TotalMilliseconds);

			var s = scope String();
			DateTime.Now.ToLongTimeString(s);
			Log($"{s} -- ${(res ? "Success" : "Failure")}");

			return res ? 1 : 0;
		}
		private delegate void WriteDelegate(ImageResult image, Stream stream);

		private delegate uint8* LoadDelegate(out int32 x, out int32 y, out ColorComponents comp);
	}
}